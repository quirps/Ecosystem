// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/*
  CampaignManagerFacet (diamond facet)
  - Epoch length = 300s
  - recordPurchase receives amounts in the creator token's native wei units
  - finalizeEpoch computes per-buyer sqrt(weight), applies caps/overflow to levels
  - openChest triggers Chainlink VRF request; fulfillRandomness picks winners and transfers ERC-1155 from vault
  - Vault is a pre-registered address (could be a contract or EOA) that creator controls and approves transfers from
*/

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract CampaignManagerFacet is VRFConsumerBaseV2 {
    // === EVENTS ===
    event CampaignRegistered(bytes32 indexed campaignId, address indexed creator);
    event PurchaseRecorded(bytes32 indexed campaignId, uint256 indexed epochId, address indexed buyer, uint256 amount);
    event EpochFinalized(bytes32 indexed campaignId, uint256 indexed epochId, uint256 totalWeight, uint256 newTotalPU);
    event MilestoneReached(bytes32 indexed campaignId, uint256 levelIndex);
    event ChestRequested(bytes32 indexed campaignId, uint256 levelIndex, uint256 requestId);
    event ChestOpened(bytes32 indexed campaignId, uint256 levelIndex, bytes32 randomness, address[] winners);

    // === STORAGE STRUCTS ===
    struct Campaign {
        address creator;
        uint256[] levelThresholds; // in PU units (PU = derived weight after sqrt transform)
        uint256 capRatioBP;        // basis points (e.g., 2000 = 20%)
        address vault;             // vault address where ERC1155 items are held
        uint8 minMemberLevel;      // min membership required
        uint256 currentLevel;      // current level index
        uint256 levelProgressPU;   // PU currently credited in current level
        bool active;
        uint256[] numDrawsPerLevel; // number draws per level
    }

    // epoch granularity
    uint256 public constant EPOCH_SECONDS = 300;

    // campaigns
    mapping(bytes32 => Campaign) public campaigns;

    // epoch data: campaign => epochId => buyer => amount (in creator token wei)
    // (For gas reasons we store buyer list per epoch to iterate during finalize)
    mapping(bytes32 => mapping(uint256 => mapping(address => uint256))) public epochBuyerAmount;
    mapping(bytes32 => mapping(uint256 => address[])) public epochBuyerList;

    // level participants: campaign -> levelIndex -> address -> weight (PU contribution assigned to that user for the level)
    mapping(bytes32 => mapping(uint256 => mapping(address => uint256))) public levelParticipantsWeight;
    mapping(bytes32 => mapping(uint256 => uint256)) public levelTotalWeight; // sum weights for level

    // chainlink VRF fields (addresses/IDs to be configured)
    VRFCoordinatorV2Interface immutable COORDINATOR;
    uint64 immutable vrfSubscriptionId;
    bytes32 immutable vrfKeyHash;
    mapping(uint256 => bytes32) public vrfRequestToCampaign; // requestId -> campaignId|level encoded

    constructor(address _vrfCoordinator, uint64 _subId, bytes32 _keyHash) VRFConsumerBaseV2(_vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        vrfSubscriptionId = _subId;
        vrfKeyHash = _keyHash;
    }

    // === ADMIN / CREATOR ACTIONS ===

    /// @notice register or update a campaign
    function registerCampaign(
        bytes32 campaignId,
        address creator,
        uint256[] calldata levelThresholds,
        uint256 capRatioBP,
        address vault,
        uint8 minMemberLevel,
        uint256[] calldata numDrawsPerLevel
    ) external {
        // Access control: only the diamond owner or creator can call (omitted access checks for brevity)
        require(levelThresholds.length == numDrawsPerLevel.length, "level length mismatch");
        Campaign storage c = campaigns[campaignId];
        c.creator = creator;
        c.levelThresholds = levelThresholds;
        c.capRatioBP = capRatioBP;
        c.vault = vault;
        c.minMemberLevel = minMemberLevel;
        c.currentLevel = 0;
        c.levelProgressPU = 0;
        c.active = true;
        c.numDrawsPerLevel = numDrawsPerLevel;
        emit CampaignRegistered(campaignId, creator);
    }

    // === MARKETPLACE HOOK ===
    /// @notice called by MarketplaceFacet when a primary sale occurs
    function recordPurchase(bytes32 campaignId, address buyer, uint256 amount) external {
        // Access control: Only authorized marketplace facet can call this (omitted)
        Campaign storage c = campaigns[campaignId];
        require(c.active, "campaign not active");
        // membership check (calls MembershipFacet - omitted actual call)
        // uint8 level = MembershipFacet.getLevel(buyer); require(level >= c.minMemberLevel);

        uint256 epochId = block.timestamp / EPOCH_SECONDS;
        if (epochBuyerAmount[campaignId][epochId][buyer] == 0) {
            // first time this buyer in this epoch, push to list
            epochBuyerList[campaignId][epochId].push(buyer);
        }
        // accumulate buyer amount for this epoch (native token wei)
        epochBuyerAmount[campaignId][epochId][buyer] += amount;
        emit PurchaseRecorded(campaignId, epochId, buyer, amount);
    }

    // === FINALIZE EPOCH ===
    /// @notice anyone can call finalizeEpoch to compute contributions for an epoch,
    /// allocate PU across levels respecting cap and overflow.
    function finalizeEpoch(bytes32 campaignId, uint256 epochId) external {
        Campaign storage c = campaigns[campaignId];
        require(c.active, "campaign inactive");

        address[] storage buyers = epochBuyerList[campaignId][epochId];
        require(buyers.length > 0, "no buyers");

        // compute sqrt weights per buyer and total E
        uint256 totalE = 0;
        uint256 len = buyers.length;
        // temporary in-memory arrays (careful with gas if len big)
        uint256[] memory weights = new uint256[](len);
        for (uint256 i = 0; i < len; ++i) {
            address b = buyers[i];
            uint256 amt = epochBuyerAmount[campaignId][epochId][b];
            // weight = floor(sqrt(amt))
            uint256 w = integerSqrt(amt);
            weights[i] = w;
            totalE += w;
        }

        uint256 remaining = totalE;

        // distribute across levels with caps and overflow
        while (remaining > 0 && c.currentLevel < c.levelThresholds.length) {
            uint256 levelThreshold = c.levelThresholds[c.currentLevel];
            uint256 levelCap = (levelThreshold * c.capRatioBP) / 10000; // cap in PU
            uint256 levelRemainingCap = levelCap;
            if (c.levelProgressPU > 0) {
                // subtract already used PU in this level
                if (c.levelProgressPU >= levelCap) {
                    levelRemainingCap = 0;
                } else {
                    levelRemainingCap = levelCap - c.levelProgressPU;
                }
            }

            uint256 take = remaining;
            if (take > levelRemainingCap) take = levelRemainingCap;

            if (take == 0) {
                // move to next level (cap exhausted)
                c.currentLevel++;
                c.levelProgressPU = 0;
                continue;
            }

            // pro-rata allocate 'take' across buyers per weight
            uint256 allocatedTotal = 0;
            for (uint256 i = 0; i < len; ++i) {
                if (weights[i] == 0) continue;
                address buyer = buyers[i];
                uint256 alloc = (take * weights[i]) / totalE; // integer division
                if (alloc > 0) {
                    levelParticipantsWeight[campaignId][c.currentLevel][buyer] += alloc;
                    levelTotalWeight[campaignId][c.currentLevel] += alloc;
                    allocatedTotal += alloc;
                }
            }
            // handle leftover due to rounding: assign deterministically to first participants
            uint256 leftover = take - allocatedTotal;
            uint256 idx = 0;
            while (leftover > 0 && idx < len) {
                if (weights[idx] > 0) {
                    address b = buyers[idx];
                    levelParticipantsWeight[campaignId][c.currentLevel][b] += 1;
                    levelTotalWeight[campaignId][c.currentLevel] += 1;
                    leftover--;
                }
                idx++;
            }

            // update level progress and remaining pool
            c.levelProgressPU += take;
            remaining -= take;

            // if level completed, emit milestone and advance
            if (c.levelProgressPU >= levelThreshold) {
                emit MilestoneReached(campaignId, c.currentLevel);
                // create chest record on-chain if desired (omitted struct)
                c.currentLevel++;
                c.levelProgressPU = 0;
            }
        }

        // update global PU (approx) - for tracking
        // not storing every detail here, but can increment campaign total if needed

        emit EpochFinalized(campaignId, epochId, totalE, /*newTotalPU=*/0);

        // Note: epochBuyerAmount and epochBuyerList can be cleared by separate pruning tx to save gas if desired.
    }

    // === CHEST OPENING / VRF ===
    function openChest(bytes32 campaignId, uint256 levelIndex) external returns (uint256 requestId) {
        Campaign storage c = campaigns[campaignId];
        require(levelIndex < c.levelThresholds.length, "invalid level");
        // require milestone reached - ensure level participants exist
        require(levelTotalWeight[campaignId][levelIndex] > 0, "no participants");
        // request VRF
        uint256 reqId = COORDINATOR.requestRandomWords(
            vrfKeyHash,
            vrfSubscriptionId,
            3, // requestConfirmations
            200000, // callbackGasLimit (tune)
            1 // numWords
        );
        // store mapping so fulfillRandomness knows which campaign/level this corresponds to
        // encode campaignId + levelIndex into bytes32 and store by requestId
        vrfRequestToCampaign[reqId] = campaignId; // For brevity; also store levelIndex in a separate mapping in real impl
        emit ChestRequested(campaignId, levelIndex, reqId);
        return reqId;
    }

    // VRF coordinator calls this
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        bytes32 campaignId = vrfRequestToCampaign[requestId];
        // decode levelIndex (omitted here—store separately in real impl)
        uint256 levelIndex = 0; // placeholder
        bytes32 randomness = bytes32(randomWords[0]);

        // selection logic: weighted draws with replacement
        uint256 totalW = levelTotalWeight[campaignId][levelIndex];
        require(totalW > 0, "no weight");
        uint256 draws = campaigns[campaignId].numDrawsPerLevel[levelIndex];
        address[] memory winners = new address[](draws);

        for (uint256 i = 0; i < draws; ++i) {
            uint256 r = uint256(keccak256(abi.encode(randomness, i))) % totalW;
            // iterate deterministic participant list to find winner
            // NOTE: this requires a stored participant list or iteration strategy (omitted details)
            address winner = _findWeightedWinner(campaignId, levelIndex, r);
            winners[i] = winner;
            // with replacement, do not remove weight
        }

        // transfer ERC1155 items from vault -> winners according to loot table (omitted retrieval)
        // IERC1155(campaigns[campaignId].vaultTokenContract).safeTransferFrom(vault, winner, tokenId, amount, "");

        emit ChestOpened(campaignId, levelIndex, randomness, winners);
    }

    // === HELPERS ===
    // integer sqrt (binary method)
    function integerSqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    // placeholder: find weighted winner by scanning participant list (implementation detail)
    function _findWeightedWinner(bytes32 campaignId, uint256 levelIndex, uint256 target) internal view returns (address) {
        // Implementation requires an iterable participant list for the level.
        // For brevity, not fully implemented here.
        revert("unimplemented");
    }

    // Additional helper functions: pruneEpoch, getEpochInfo, etc.
}