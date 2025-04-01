// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Interfaces
import "./interfaces/IExchangeRewards.sol";
import "./interfaces/IRewardToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "../facets/ERC2981/IERC2981.sol";
// Libraries & Utilities
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
// Access & Security
import "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuardContract} from "../ReentrancyGuard.sol";
// Debugging (Optional)
// import "hardhat/console.sol"; // Uncomment for hardhat console logging

/**
 * @title ExchangeRewards Contract v3 (Passive Accrual Added)
 * @dev Manages staking of Reward Tokens, distribution of platform fees,
 * passive reward accrual, NFT enhancements, discount vouchers, and passive holding rewards.
 */
contract ExchangeRewards is IExchangeRewards, Ownable, ReentrancyGuardContract, IERC1155Receiver {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet; // For user stake tracking
    using EnumerableSet for EnumerableSet.AddressSet; // Added for passive claim iteration
    // --- State Variables ---

    IRewardToken public immutable rewardToken; // Address of the RewardToken contract (ERC1155)
    address public ticketExchange; // Address of the TicketExchange contract

    mapping(address => uint256) totalRewardsByToken; // paymentToken => amount

    // --- Staking State ---
    // StakeInfo struct defined in IExchangeRewards.sol included via inheritance
    mapping(uint256 => StakeInfo) public stakes; // stakeId => StakeInfo
    uint256 public nextStakeId;
    mapping(address => EnumerableSet.UintSet) private _userStakes; // user => set of active stake IDs

    struct LockupOption {
        uint256 duration; // seconds
        uint16 passiveRateMultiplierBp; // Multiplier for passive accrual rate (Stream 1), 10000 = 1x
    }
    LockupOption[] public lockupOptions; // Index maps to durationOption in stake()

    // Fee Share Reward Calculation State (Stream 2 - Accumulator Pattern)
    struct RewardInfo {
        uint256 rewardPerTokenStored; // Accumulated fee share rewards (ERC20) per EFFECTIVE token staked (scaled by 1e18)
        uint256 lastUpdateTime;
        uint256 totalStaked; // Total actual amount of this tokenId currently staked
        uint256 totalEffectiveStaked; // Total amount considering NFT liquidity boosts
    }
    mapping(uint256 => RewardInfo) public rewardInfo; // rewardTokenId => RewardInfo

    // Passive Staking Reward Calculation State (Stream 1 - Time-based)
    uint256 public basePassiveStakingRate; // Wei of reward per second per wei staked, scaled by 1e18 for precision

    // --- Passive Holding Rewards State (Unstaked tokens) ---
    struct HoldingRewardInfo {
        uint256 rewardPerTokenStored; // Accumulated rewards (ERC20) per token held (scaled by 1e18)
        uint256 lastUpdateTime;
    }
    mapping(uint256 => HoldingRewardInfo) public holdingRewardInfo;
    mapping(address => mapping(uint256 => uint256)) public userHoldingRewardDebt; // user => tokenId => debt (scaled by 1e18)
    uint16 public passiveRewardFeeShareBasisPoints; // Pct of fees for passive holding rewards
    mapping(address => uint256) internal passiveRewardPool; // paymentToken => accumulated ERC20 amount

    // --- Discount State ---
    mapping(address => mapping(address => uint256)) public userDiscountCredit; // user => paymentToken => credit amount (in paymentToken units)

    // --- Dynamic Purchase Reward Mint Rate State ---
    uint256 public baseRewardRateNumerator = 1;
    uint256 public baseRewardRateDenominator = 100;
    uint16 public stakingRatioBoostFactor = 5000;

    // --- NFT Properties State ---
    // NftProperties struct and BonusType enum defined in IExchangeRewards.sol included via inheritance
    mapping(uint256 => NftProperties) public nftProperties; // nftId => Properties

    // --- Constants ---
    uint256 private constant PRECISION_FACTOR = 1e18;
    uint16 private constant BASIS_POINTS_DIVISOR = 10000;

    // --- Errors ---
    // --- Errors ---
    error NotTicketExchange();
    error InvalidDurationOption();
    error AmountMustBePositive();
    error CannotStakeNFT();
    error NotStakeOwner();
    error StakeNotActive();
    error StakeLocked();
    error EnhancementAlreadyAttached();
    error NotEnhancementNFT();
    error UserDoesNotOwnNFT();
    error NoEnhancementAttached();
    error CannotMintNFTAsReward();
    error InsufficientBalance();
    error BurnAmountTooSmall();
    error CannotClaimForNFT();
    error NoRewardsToClaim();
    error ZeroAddress();
    error NftNotBoosterType();
    error NftTargetMismatch();
    error NftInactive();
    error InsufficientFundsForPassiveReward();

    // --- Constructor ---
    constructor(address _rewardTokenAddress, address _owner) Ownable(_owner) {
        if (_rewardTokenAddress == address(0)) revert ZeroAddress();
        rewardToken = IRewardToken(_rewardTokenAddress);
        // Initialize default lockup options (passive rate multipliers)
        lockupOptions.push(LockupOption(0, 10000)); // 0: No lock, 1.00x passive rate
        lockupOptions.push(LockupOption(7 days, 11000)); // 1: 1 week,   1.10x passive rate
        lockupOptions.push(LockupOption(14 days, 12000)); // 2: 2 weeks,  1.20x passive rate
        lockupOptions.push(LockupOption(30 days, 13500)); // 3: 1 month,  1.35x passive rate

        // Initialize base passive staking rate (requires admin configuration)
        basePassiveStakingRate = 0;
        // basePassiveStakingRate = 1 * PRECISION_FACTOR / (1 days); // e.g., 1 unit per day per token, needs scaling definition
    }

    // --- Configuration Functions (Owner Controlled) ---

    /** @inheritdoc IExchangeRewards*/
    function setTicketExchange(address _ticketExchange) external override onlyOwner {
        if (_ticketExchange == address(0)) revert ZeroAddress();
        ticketExchange = _ticketExchange;
    }

    /** @inheritdoc IExchangeRewards*/
    function addLockupOption(uint256 duration, uint16 passiveRateMultiplierBp) external override onlyOwner {
        require(passiveRateMultiplierBp >= BASIS_POINTS_DIVISOR, "Multiplier must be >= 1x");
        lockupOptions.push(LockupOption(duration, passiveRateMultiplierBp)); // Stores passive rate multiplier    }
    }
    /** @inheritdoc IExchangeRewards*/
    function setBaseRewardRate(uint256 numerator, uint256 denominator) external override onlyOwner {
        require(denominator > 0, "Denominator cannot be zero");
        baseRewardRateNumerator = numerator;
        baseRewardRateDenominator = denominator;
    }

    /** @inheritdoc IExchangeRewards*/
    function setBasePassiveStakingRate(uint256 ratePerSecScaled) external override onlyOwner {
        // Consider adding validation for the rate scale if needed
        basePassiveStakingRate = ratePerSecScaled;
    }

    /** @inheritdoc IExchangeRewards*/
    function setStakingRatioBoostFactor(uint16 boostFactorBp) external override onlyOwner {
        stakingRatioBoostFactor = boostFactorBp;
    }

    /** @inheritdoc IExchangeRewards*/
    function setPassiveRewardFeeShare(uint16 basisPoints) external override onlyOwner {
        require(basisPoints <= BASIS_POINTS_DIVISOR, "Cannot exceed 100%");
        passiveRewardFeeShareBasisPoints = basisPoints;
    }

    /** @inheritdoc IExchangeRewards*/
    function ownerMintAndSetNft(
        address to,
        uint256 nftId,
        uint256 amount,
        bytes calldata data,
        BonusType bonusType,
        address targetEcosystem,
        uint256 bonusValue
    ) external override onlyOwner {
        if (!rewardToken.isEnhancementNFT(nftId)) revert NotEnhancementNFT();
        // Use RewardToken's owner mint function
        IRewardToken(rewardToken).ownerMintEnhancementNFT(to, nftId, amount, data);
        // Set properties
        setNftProperties(nftId, bonusType, targetEcosystem, bonusValue, true);
    }

    /** @inheritdoc IExchangeRewards*/
    function setNftProperties(
        uint256 nftId,
        BonusType bonusType,
        address targetEcosystem,
        uint256 bonusValue,
        bool isActive
    ) public override onlyOwner {
        // Public so owner can update properties later
        if (!rewardToken.isEnhancementNFT(nftId)) revert NotEnhancementNFT();
        nftProperties[nftId] = NftProperties({bonusType: bonusType, targetEcosystem: targetEcosystem, bonusValue: bonusValue, isActive: isActive});
        emit NftPropertiesSet(nftId, bonusType, targetEcosystem, bonusValue, isActive);
    }

    // --- Funding Function ---
    /**
     * @notice Allows owner to deposit ERC20 tokens to fund passive reward payouts.
     * @param paymentToken The address of the ERC20 token being deposited.
     * @param amount The amount of tokens being deposited.
     */
    function depositPassiveRewardFunds(address paymentToken, uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be positive");
        IERC20(paymentToken).safeTransferFrom(msg.sender, address(this), amount);
    }
    // --- Core Interactions (Called by TicketExchange) ---

    /** @inheritdoc IExchangeRewards*/
    function recordFee(address paymentToken, uint256 platformFeeAmount) external payable override ReentrancyGuard {
        if (msg.sender != ticketExchange) revert NotTicketExchange();
        if (platformFeeAmount == 0) return;

        uint256 tokenId = uint256(uint160(paymentToken));
        uint256 amountForStaking = platformFeeAmount;

        // Allocate portion to Passive Holding Reward Pool (accounting only)
        if (passiveRewardFeeShareBasisPoints > 0) {
            uint256 passiveShare = (platformFeeAmount * passiveRewardFeeShareBasisPoints) / BASIS_POINTS_DIVISOR;
            if (passiveShare > 0) {
                passiveRewardPool[paymentToken] += passiveShare;
                amountForStaking -= passiveShare;
            }
        }

        // Allocate remaining portion to Staking Fee Share Rewards (Stream 2)
        if (amountForStaking > 0) {
            RewardInfo storage stakingInfo = rewardInfo[tokenId];
            // Note: _updateStakingRewardAccumulator removed as fee distribution *is* the update event
            stakingInfo.lastUpdateTime = block.timestamp; // Update timestamp

            // Distribute rewards based on TOTAL EFFECTIVE STAKED amount
            if (stakingInfo.totalEffectiveStaked > 0) {
                uint256 rewardAddedPerEffectiveToken = ((amountForStaking * PRECISION_FACTOR) / stakingInfo.totalEffectiveStaked);
                stakingInfo.rewardPerTokenStored += rewardAddedPerEffectiveToken;
            }
            // If totalEffectiveStaked is 0, fee share rewards are implicitly pooled until someone stakes        }

            emit FeeRecorded(paymentToken, amountForStaking);
        }
    }

    /** @inheritdoc IExchangeRewards*/
    function getRewardMintRate(address paymentToken) external view override returns (uint256 rate) {
        // Calculation unchanged from previous version, using actual totalStaked
        uint256 tokenId = uint256(uint160(paymentToken));
        uint256 totalStaked = rewardInfo[tokenId].totalStaked; // Use actual staked amount for ratio
        uint256 totalSupply = rewardToken.totalSupply(tokenId);

        uint256 stakingRatio = 0; // Basis points (0-10000)
        if (totalSupply > 0) {
            stakingRatio = (totalStaked * BASIS_POINTS_DIVISOR) / totalSupply;
            if (stakingRatio > BASIS_POINTS_DIVISOR) stakingRatio = BASIS_POINTS_DIVISOR; // Cap
        }

        uint256 boost = (stakingRatio * stakingRatioBoostFactor) / BASIS_POINTS_DIVISOR;
        uint256 multiplier = BASIS_POINTS_DIVISOR + boost;

       // Final rate = BaseRate * Multiplier (adjusting for BP and using 1e18 precision for rate)
         if (baseRewardRateDenominator == 0) return 0; // Avoid division by zero
         rate = (baseRewardRateNumerator * PRECISION_FACTOR / baseRewardRateDenominator) * multiplier / BASIS_POINTS_DIVISOR;
         // This 'rate' represents: how many reward tokens (wei) to mint per 1 unit (wei) of paymentToken
    }

    /** @inheritdoc IExchangeRewards*/
    function useDiscount(address user, address paymentToken) external override ReentrancyGuard returns (uint256 discountAmount) {
        if (msg.sender != ticketExchange) revert NotTicketExchange();
        discountAmount = userDiscountCredit[user][paymentToken];
        if (discountAmount > 0) {
            userDiscountCredit[user][paymentToken] = 0;
            emit DiscountUsed(user, paymentToken, discountAmount);
        }
    }

    /** @inheritdoc IExchangeRewards*/
    function executeMint(address buyer, uint256 rewardTokenId, uint256 rewardAmount) external override {
        if (msg.sender != ticketExchange) revert NotTicketExchange();
        // Check rewardTokenId is not in NFT range
        if (rewardToken.isEnhancementNFT(rewardTokenId)) revert CannotMintNFTAsReward(); // Add Error
        rewardToken.mint(buyer, rewardTokenId, rewardAmount, "");
    }

    /** @inheritdoc IExchangeRewards*/
    function verifyAndUsePurchaseBooster(
        address buyer,
        uint256 boosterNftId,
        address purchaseEcosystemAddress
    ) external override ReentrancyGuard returns (bool boosted) {
        if (msg.sender != ticketExchange) revert NotTicketExchange();
        if (boosterNftId == 0) return false; // No NFT provided

        if (!rewardToken.isEnhancementNFT(boosterNftId)) revert NotEnhancementNFT();

        NftProperties storage properties = nftProperties[boosterNftId];

        // Check NFT properties
        if (!properties.isActive) revert NftInactive(); // Check if usable
        if (properties.bonusType != BonusType.PURCHASE_REWARD_MULTIPLIER) revert NftNotBoosterType();
        // Check target ecosystem (allow 0 address for global boost)
        if (properties.targetEcosystem != address(0) && properties.targetEcosystem != purchaseEcosystemAddress) {
            revert NftTargetMismatch();
        }
        // Check ownership (balance >= 1)
        if (rewardToken.balanceOf(buyer, boosterNftId) < 1) revert UserDoesNotOwnNFT();

        // Burn the NFT - call controlled burn function on RewardToken
        rewardToken.burnFrom(buyer, boosterNftId, 1);

        // Indicate boost should be applied
        boosted = true;
        // Emit event? Maybe handled by TicketExchange event.
    }

    // --- Admin Actions ---

    /** @inheritdoc IExchangeRewards*/
        // Distributes passive rewards for *holding* unstaked tokens
    function distributePassiveHoldingRewards(uint256[] calldata tokenIds) external override onlyOwner {
        // Implementation unchanged from previous version
        for (uint i = 0; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];
            address paymentToken = address(uint160(tokenId));
            uint256 poolAmount = passiveRewardPool[paymentToken];

            if (poolAmount > 0) {
                uint256 totalSupply = rewardToken.totalSupply(tokenId);
                if (totalSupply > 0) {
                    uint256 addedRewardPerToken = poolAmount * PRECISION_FACTOR / totalSupply; // Scale for precision
                    HoldingRewardInfo storage info = holdingRewardInfo[tokenId];
                    info.rewardPerTokenStored += addedRewardPerToken;
                    info.lastUpdateTime = block.timestamp;
                    passiveRewardPool[paymentToken] = 0; // Reset pool

                    emit PassiveRewardsDistributed(tokenId, poolAmount, addedRewardPerToken);
                }
            }
        }
    }

    // --- User Staking & Rewards ---

    /** @inheritdoc IExchangeRewards*/
    function stake(uint256 tokenId, uint256 amount, uint8 durationOption) external override ReentrancyGuard {
        if (rewardToken.isEnhancementNFT(tokenId)) revert CannotStakeNFT();
        if (amount == 0) revert AmountMustBePositive();
        if (durationOption >= lockupOptions.length) revert InvalidDurationOption();

        LockupOption storage chosenOption = lockupOptions[durationOption];
        uint256 currentTimestamp = block.timestamp;
        uint256 endTime = (chosenOption.duration == 0) ? 0 : currentTimestamp + chosenOption.duration;
        RewardInfo storage stakingInfo = rewardInfo[tokenId];
        // Update fee share accumulator BEFORE stake changes
        _updateFeeShareReward(stakingInfo);

        // Transfer reward tokens from user
        // Using virtual function call for potential future overrides if needed
        IRewardToken(rewardToken).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");

        // Create stake record - CORRECTED INITIALIZATION (10 fields)
        uint256 stakeId = nextStakeId++;
        stakes[stakeId] = StakeInfo({
            tokenId: tokenId,
            owner: msg.sender,
            amount: amount,
            startTime: currentTimestamp, 
            endTime: endTime,
            durationOption: durationOption,
            feeShareRewardDebt: stakingInfo.rewardPerTokenStored, // Initialize debt for fee share
            passiveRewardDebt: 0, // Initialize passive debt (actual value depends on passive calc specifics)
            lastPassiveRewardClaimTime: currentTimestamp,  
            attachedNftId: 0, // Initialize attached NFT ID
            // passiveRateBoostBP: 0, // REMOVED - Field does not exist in struct
            // feeShareBoostBP: 0,    // REMOVED - Field does not exist in struct
            active: true
        });
        // Add stakeId to user's list of stakes
        _userStakes[msg.sender].add(stakeId);

        // Update totals
        stakingInfo.totalStaked += amount;
        // Effective staked amount initially equals actual amount (no boost yet)
        // Use helper to calculate initial effective amount (which is just amount if no NFT)
        stakingInfo.totalEffectiveStaked += _getEffectiveStakedAmount(amount, 0); // Add initial effective amount

        // Emit event using updated parameters
        emit Staked(msg.sender, stakeId, tokenId, amount, durationOption, endTime);
    }

    /** @inheritdoc IExchangeRewards*/
    function unstake(uint256 stakeId) external override ReentrancyGuard {
        StakeInfo storage stake = stakes[stakeId];
        address user = msg.sender;
        if (stake.owner != user) revert NotStakeOwner();
        if (!stake.active) revert StakeNotActive();
        if (stake.endTime != 0 && block.timestamp < stake.endTime) revert StakeLocked();

        uint256 tokenId = stake.tokenId;
        uint256 amount = stake.amount; // Actual amount staked

        // --- Calculate and Handle Rewards BEFORE modifying state ---
        RewardInfo storage stakingInfo = rewardInfo[tokenId];
        _updateFeeShareReward(stakingInfo); // Update global fee share accumulator

        // Calculate pending Fee Share rewards (Stream 2)
        uint256 pendingFeeShare = _calculatePendingFeeShareRewards(stakeId, stakingInfo.rewardPerTokenStored);

        // Calculate pending Passive Accrual rewards (Stream 1) - STUBBED
        uint256 pendingPassive = _calculatePendingPassiveStakingRewards(stakeId);

        // --- Modify State ---
        stake.active = false;

        // Update global totals
        uint256 currentEffectiveAmount = _getEffectiveStakedAmount(stake.amount, stake.attachedNftId);
        stakingInfo.totalStaked -= amount;
        stakingInfo.totalEffectiveStaked -= currentEffectiveAmount;

        // Detach NFT if present
        uint256 nftIdToReturn = 0;
        if (stake.attachedNftId != 0) {
            nftIdToReturn = _detachStakingNftInternal(stake); // Updates stake boost fields
        }

        // Remove from user's active stakes list
        _userStakes[user].remove(stakeId);

        // --- Transfer Assets ---
        // Transfer principal reward tokens back
        rewardToken.safeTransferFrom(address(this), user, tokenId, amount, "");

        address paymentToken = address(uint160(tokenId));
        uint256 totalRewardsToTransfer = 0;

        // Transfer pending Fee Share rewards
        if (pendingFeeShare > 0) {
            // stake.feeShareRewardDebt = stakingInfo.rewardPerTokenStored; // Update debt as reward is paid
            totalRewardsToTransfer += pendingFeeShare;
            emit StakingFeeShareRewardsClaimed(user, tokenId, pendingFeeShare);
        }

        // Transfer pending Passive Accrual rewards - STUBBED
        if (pendingPassive > 0) {
            // stake.passiveRewardDebt = ??? // Update passive debt based on claim logic
            totalRewardsToTransfer += pendingPassive;
            emit PassiveStakingRewardsClaimed(user, stakeId, pendingPassive);
        }

        // Perform single transfer for combined rewards
        if (totalRewardsToTransfer > 0) {
            IERC20(paymentToken).safeTransfer(user, totalRewardsToTransfer);
        }

        // Transfer enhancement NFT back if detached
        if (nftIdToReturn != 0) {
            rewardToken.safeTransferFrom(address(this), user, nftIdToReturn, 1, "");
        }

        emit Unstaked(user, stakeId, tokenId, amount);
    }

    /** @inheritdoc IExchangeRewards*/
    function attachStakingNft(uint256 stakeId, uint256 nftId) external override ReentrancyGuard {
        StakeInfo storage stake = stakes[stakeId];
        address user = msg.sender;
        if (stake.owner != user) revert NotStakeOwner();
        if (!stake.active) revert StakeNotActive();
        if (stake.attachedNftId != 0) revert EnhancementAlreadyAttached(); // Only one allowed
        if (!rewardToken.isEnhancementNFT(nftId)) revert NotEnhancementNFT();
        if (rewardToken.balanceOf(user, nftId) < 1) revert UserDoesNotOwnNFT();

        NftProperties storage properties = nftProperties[nftId];
        if (!properties.isActive) revert NftInactive();
        // Check if NFT is a STAKING booster type (Passive or Fee Share)
        if (properties.bonusType != BonusType.PASSIVE_STAKING_RATE_BOOST && properties.bonusType != BonusType.STAKING_FEE_SHARE_BOOST) {
            revert NftNotBoosterType(); // Or different error? "NotStakingBooster"
        }
        // Optional: Check target ecosystem if needed for staking boosts
        // if (properties.targetEcosystem != address(0) && properties.targetEcosystem != address(uint160(stake.tokenId))) { ... }

        RewardInfo storage stakingInfo = rewardInfo[stake.tokenId];
        _updateFeeShareReward(stakingInfo); // Settle fee share rewards before changing effective amount

        // Settle Fee Share debt before changing effective amount
        uint256 pendingFeeShare = _calculatePendingFeeShareRewards(stakeId, stakingInfo.rewardPerTokenStored);
        stake.feeShareRewardDebt += (pendingFeeShare * PRECISION_FACTOR) / stake.amount; // Re-scale to per-token ? No, update debt to current global level
        stake.feeShareRewardDebt = stakingInfo.rewardPerTokenStored; // Update debt

        // Settle Passive Accrual debt - STUBBED
        // uint256 pendingPassive = _calculatePendingPassiveStakingRewards(stakeId);
        // stake.passiveRewardDebt = ??? // Update based on passive claim logic

        // --- Apply Boost and Lock NFT ---
        uint256 oldEffectiveAmount = stake.amount; // Before attaching NFT
        uint256 newEffectiveAmount = _getEffectiveStakedAmount(stake.amount, nftId); // After attaching

        // Lock NFT: Transfer to this contract AND call setNFTLocked
        rewardToken.safeTransferFrom(user, address(this), nftId, 1, "");
        rewardToken.setNFTLocked(nftId, true);

        stake.attachedNftId = nftId;
        // Boost BPs are now read dynamically via _getNftBoosts or _getEffectiveStakedAmount

        // Update total effective staked amount
        RewardInfo storage stakingInfo_attach = rewardInfo[stake.tokenId]; // Get storage pointer
        stakingInfo_attach.totalEffectiveStaked = stakingInfo_attach.totalEffectiveStaked - oldEffectiveAmount + newEffectiveAmount;

        emit StakingNftAttached(stakeId, nftId);
    }

    /** @dev Internal: Handles NFT detachment logic during unstake */
    function _detachStakingNftInternal(StakeInfo storage stake) internal returns (uint256 nftId) {
        nftId = stake.attachedNftId;
        if (nftId == 0) return 0;

        // Settle rewards before removing boost effects - fee share settled in unstake already
        // Settle Passive Accrual debt - STUBBED
        // uint256 pendingPassive = _calculatePendingPassiveStakingRewards(stakeId); // Uses boost from attached NFT
        // stake.passiveRewardDebt = ??? // Update based on passive claim logic

        // // --- Remove Boost and Unlock NFT ---
        // uint256 currentEffectiveAmount = _getEffectiveStakedAmount(stake.amount, nftId); // With boost
        // uint256 newEffectiveAmount = _getEffectiveStakedAmount(stake.amount, 0); // Without boost

        // stake.attachedNftId = 0;
        // // stake.passiveRateBoostBP = 0; // Not stored directly
        // // stake.feeShareBoostBP = 0; // Not stored directly

        // // Update total effective staked amount in global info
        // RewardInfo storage stakingInfo = rewardInfo[stake.tokenId];
        // // Check for potential underflow if state is inconsistent, though unlikely
        // stakingInfo.totalEffectiveStaked = stakingInfo.totalEffectiveStaked - currentEffectiveAmount + newEffectiveAmount;

        // Unlock NFT status in RewardToken contract
        rewardToken.setNFTLocked(nftId, false);

        //emit StakingNftDetached(stakeId, nftId);
        return nftId; // Return ID so caller can transfer it back
    }

    /** @inheritdoc IExchangeRewards*/
    function claimFeeShareRewards(uint256[] calldata stakeIds) external override ReentrancyGuard {
        address user = msg.sender;
        // Use dynamic array + count for unique token tracking
        address[] memory uniquePaymentTokensList = new address[](stakeIds.length);
        uint256 uniqueTokenCount = 0;
        // Removed: mapping(address => bool) memory alreadyAdded; // Invalid syntax

        // --- Aggregation Phase ---
        for (uint i = 0; i < stakeIds.length; i++) {
            uint256 stakeId = stakeIds[i];
            StakeInfo storage stake = stakes[stakeId];

            if (stake.owner != user || !stake.active) {
                continue;
            }

            uint256 currentTokenId = stake.tokenId; // Cache for efficiency
            RewardInfo storage stakingInfo = rewardInfo[currentTokenId];
            _updateFeeShareReward(stakingInfo); // Update global accumulator

            uint256 pending = _calculatePendingFeeShareRewards(stakeId, stakingInfo.rewardPerTokenStored);

            if (pending > 0) {
                // Update stake's debt to current level BEFORE aggregating reward
                stake.feeShareRewardDebt = stakingInfo.rewardPerTokenStored;

                address paymentToken = address(uint160(currentTokenId));
                totalRewardsByToken[paymentToken] += pending; // Aggregate reward

                // --- Check if paymentToken is already in unique list ---
                bool found = false;
                for (uint j = 0; j < uniqueTokenCount; j++) {
                    if (uniquePaymentTokensList[j] == paymentToken) {
                        found = true;
                        break;
                    }
                }
                // --- Add to list if not found ---
                if (!found) {
                    uniquePaymentTokensList[uniqueTokenCount] = paymentToken;
                    uniqueTokenCount++;
                }
                // --- End uniqueness check ---
            }
        }

        // --- Transfer Phase ---
        for (uint i = 0; i < uniqueTokenCount; ++i) {
            address paymentToken = uniquePaymentTokensList[i];
            uint256 amountToTransfer = totalRewardsByToken[paymentToken];

            if (amountToTransfer > 0) {
                IERC20(paymentToken).safeTransfer(user, amountToTransfer);
                uint256 correspondingTokenId = uint256(uint160(paymentToken));
                emit StakingFeeShareRewardsClaimed(user, correspondingTokenId, amountToTransfer);
                // Optional: delete totalRewardsByToken[paymentToken];
            }
        }
    }

    /** @inheritdoc IExchangeRewards*/
    function claimPassiveStakingRewards(uint256[] calldata stakeIds) external override ReentrancyGuard {
        // --- STUB ---
        // TODO: Implement time-based calculation for Stream 1 rewards
        // Iterate stakeIds
        // For each stake:
        //  - Calculate time elapsed since stake.startTime or last passive claim time
        //  - Get basePassiveStakingRate
        //  - Get passiveRateMultiplierBp from lockupOptions[stake.durationOption]
        //  - Get passiveRateBoostBP from attached NFT properties (_getNftBoosts)
        //  - Calculate reward = time * baseRate * multiplier * boost * stake.amount / scaling_factors
        //  - Update stake.passiveRewardDebt
        //  - Aggregate rewards by paymentToken
        // Transfer aggregated rewards
        revert("Passive staking rewards not implemented yet.");
    }

    /** @inheritdoc IExchangeRewards*/
    function claimHoldingReward(uint256 tokenId) external override ReentrancyGuard {
        // Implementation unchanged from previous version
        address user = msg.sender;
        if (rewardToken.isEnhancementNFT(tokenId)) revert CannotClaimForNFT();

        uint256 pending = pendingHoldingRewards(user, tokenId); // Uses view function

        if (pending == 0) revert NoRewardsToClaim();

        userHoldingRewardDebt[user][tokenId] = holdingRewardInfo[tokenId].rewardPerTokenStored; // Update debt
        address paymentToken = address(uint160(tokenId));
        IERC20(paymentToken).safeTransfer(user, pending); // Transfer from contract's balance

        emit HoldingRewardsClaimed(user, tokenId, pending);
    }

    /** @inheritdoc IExchangeRewards*/
    function claimDiscountVoucher(uint256 rewardTokenId, uint256 amountToBurn) external override ReentrancyGuard {
        // Implementation unchanged from previous version
        address user = msg.sender;
        if (rewardToken.isEnhancementNFT(rewardTokenId)) revert CannotClaimForNFT();
        if (amountToBurn == 0) revert AmountMustBePositive();
        if (rewardToken.balanceOf(user, rewardTokenId) < amountToBurn) revert InsufficientBalance();

        uint256 discountRatePerPaymentTokenUnit = 10; // TODO: Make configurable?
        if (discountRatePerPaymentTokenUnit == 0) revert("Discount rate not set");

        uint256 discountValue = amountToBurn / discountRatePerPaymentTokenUnit;
        if (discountValue == 0) revert BurnAmountTooSmall();

        rewardToken.burnFrom(user, rewardTokenId, amountToBurn); // Call controlled burn

        address paymentToken = address(uint160(rewardTokenId));
        userDiscountCredit[user][paymentToken] += discountValue;

        emit DiscountVoucherClaimed(user, rewardTokenId, amountToBurn, discountValue, paymentToken);
    }

    // --- Helper & View Functions ---

    /** @dev Updates the fee share reward accumulator based on elapsed time if using a rate model. No-op for deposit model. */
    function _updateFeeShareReward(RewardInfo storage stakingInfo) internal {
        // Current model adds reward on recordFee, so just update timestamp
        stakingInfo.lastUpdateTime = block.timestamp;
    }

    /** @dev Calculates pending fee share rewards (Stream 2) for a single stake without updating state */
    function _calculatePendingFeeShareRewards(uint256 stakeId, uint256 currentGlobalRewardPerToken_scaled) internal view returns (uint256) {
        StakeInfo storage stake = stakes[stakeId];
        if (!stake.active) return 0;

        uint256 rewardPerToken = currentGlobalRewardPerToken_scaled; // Scaled by 1e18
        uint256 debtPerToken = stake.feeShareRewardDebt; // Also scaled by 1e18

        if (rewardPerToken <= debtPerToken) return 0; // No new rewards accumulated

        uint256 effectiveAmount = _getEffectiveStakedAmount(stake.amount, stake.attachedNftId);

        // Calculate earned = effectiveAmount * (RewardPerToken_scaled - DebtPerToken_scaled) / 1e18
        uint256 earned = (effectiveAmount * (rewardPerToken - debtPerToken)) / PRECISION_FACTOR; // base earned, unscaled

        return earned;
    }

    /** @dev Calculates pending passive staking rewards (Stream 1) for a single stake without updating state */
    function _calculatePendingPassiveStakingRewards(uint256 stakeId) internal view returns (uint256) {
        // --- STUB ---
        // TODO: Implement time-based calculation logic here mirroring claimPassiveStakingRewards
        return 0;
    }

    /** @dev Calculates the effective stake amount considering NFT boost */
    function _getEffectiveStakedAmount(uint256 actualAmount, uint256 attachedNftId) internal view returns (uint256 effectiveAmount) {
        effectiveAmount = actualAmount;
        if (attachedNftId != 0) {
            NftProperties storage properties = nftProperties[attachedNftId];
            if (properties.isActive && properties.bonusType == BonusType.STAKING_FEE_SHARE_BOOST) {
                // Assumes bonusValue stores boost basis points (e.g., 1000 = +10%)
                effectiveAmount = (actualAmount * (BASIS_POINTS_DIVISOR + uint16(properties.bonusValue))) / BASIS_POINTS_DIVISOR;
            }
        }
    }

    /** @dev Gets passive rate boost BP from attached NFT */
    function _getPassiveRateBoostBP(uint256 attachedNftId) internal view returns (uint16 boostBp) {
        boostBp = 0;
        if (attachedNftId != 0) {
            NftProperties storage properties = nftProperties[attachedNftId];
            if (properties.isActive && properties.bonusType == BonusType.PASSIVE_STAKING_RATE_BOOST) {
                boostBp = uint16(properties.bonusValue); // Assumes bonusValue stores boost BP
            }
        }
    }

    /** @inheritdoc IExchangeRewards*/
    function pendingFeeShareRewards(uint256 stakeId) external view override returns (uint256) {
        StakeInfo storage stake = stakes[stakeId];
        if (!stake.active) return 0;
        RewardInfo storage stakingInfo = rewardInfo[stake.tokenId];
        return _calculatePendingFeeShareRewards(stakeId, stakingInfo.rewardPerTokenStored);
    }

    /** @inheritdoc IExchangeRewards*/
    function pendingPassiveStakingRewards(uint256 stakeId) external view override returns (uint256) {
        return _calculatePendingPassiveStakingRewards(stakeId); // Calls stubbed internal function
    }

    /** @inheritdoc IExchangeRewards*/
    function getStakeInfo(uint256 stakeId) external view override returns (StakeInfo memory) {
        return stakes[stakeId];
    }

    /** @inheritdoc IExchangeRewards*/
    function getUserStakeIds(address user) external view override returns (uint256[] memory) {
        return _userStakes[user].values();
    }

    /** @inheritdoc IExchangeRewards*/
    function getNftProperties(uint256 nftId) external view override returns (NftProperties memory) {
        if (!rewardToken.isEnhancementNFT(nftId)) revert NotEnhancementNFT();
        return nftProperties[nftId];
    }

    /** @inheritdoc IExchangeRewards*/
    function getUserDiscountCredit(address user, address paymentToken) external view override returns (uint256) {
        return userDiscountCredit[user][paymentToken];
    }

    /** @inheritdoc IExchangeRewards*/
    function pendingHoldingRewards(address user, uint256 tokenId) public view override returns (uint256) {
        // Implementation unchanged from previous version
        HoldingRewardInfo storage info = holdingRewardInfo[tokenId];
        uint256 globalRewardPerToken = info.rewardPerTokenStored; // Scaled
        uint256 userDebtPerToken = userHoldingRewardDebt[user][tokenId]; // Scaled

        if (globalRewardPerToken <= userDebtPerToken) return 0;

        uint256 userBalance = rewardToken.balanceOf(user, tokenId);
        if (userBalance == 0) return 0;

        uint256 reward = (userBalance * (globalRewardPerToken - userDebtPerToken)) / PRECISION_FACTOR;
        return reward;
    }

    /** @inheritdoc IExchangeRewards*/
    function getLockupOptions() external view override returns (uint256[] memory durations, uint16[] memory passiveRateMultipliers) {
        uint256 length = lockupOptions.length;
        durations = new uint256[](length);
        passiveRateMultipliers = new uint16[](length);
        for (uint i = 0; i < length; ++i) {
            durations[i] = lockupOptions[i].duration;
            passiveRateMultipliers[i] = lockupOptions[i].passiveRateMultiplierBp;
        }
        return (durations, passiveRateMultipliers);
    }

    // --- IERC1155Receiver ---
    /** @inheritdoc IERC1155Receiver*/
    function onERC1155Received(
        address /*operator*/,
        address /*from*/,
        uint256 /*id*/,
        uint256 /*value*/,
        bytes calldata /*data*/
    ) external override returns (bytes4) {
        // Accept transfers intended for NFT attachments (e.g., during attachStakingNft)
        // Check msg.sender == rewardToken? Could add checks based on internal state tracking expected deposits.
        return this.onERC1155Received.selector;
    }

    /** @inheritdoc IERC1155Receiver*/
    function onERC1155BatchReceived(
        address /*operator*/,
        address /*from*/,
        uint256[] calldata /*ids*/,
        uint256[] calldata /*values*/,
        bytes calldata /*data*/
    ) external override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    // --- Supports Interface ---
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return interfaceId == type(IExchangeRewards).interfaceId || interfaceId == type(IERC1155Receiver).interfaceId;
    }
}
