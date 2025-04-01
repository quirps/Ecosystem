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
    using EnumerableSet for EnumerableSet.AddressSet; // For claim iteration

    // --- State Variables ---

    IRewardToken public immutable rewardToken; // Address of the RewardToken contract (ERC1155)
    address public ticketExchange; // Address of the TicketExchange contract

    mapping(address => uint256) totalRewardsByToken; // REMOVED - Should be local in claim functions

    // --- Staking State ---
    mapping(uint256 => StakeInfo) public stakes; // stakeId => StakeInfo (Struct defined in interface)
    uint256 public nextStakeId;
    mapping(address => EnumerableSet.UintSet) private _userStakes; // user => set of active stake IDs

     struct LockupOption {
         uint256 duration; // seconds 
         uint16 passiveRateMultiplierBp; // Multiplier for passive accrual rate (Stream 1), 10000 = 1x
     }
    // Lockup options define duration and passive accrual multiplier
    LockupOption[] public lockupOptions; // Index maps to durationOption in stake()

    // Fee Share Reward Calculation State (Stream 2 - Accumulator Pattern)
     struct RewardInfo { 
        uint256 rewardPerTokenStored; // Accumulated fee share rewards (ERC20) per EFFECTIVE token staked (scaled by 1e18)
        uint256 lastUpdateTime;
        uint256 totalStaked; // Total actual amount of this tokenId currently staked
        uint256 totalEffectiveStaked; // Total amount considering NFT liquidity boosts
    }
    mapping(uint256 => RewardInfo) public rewardInfo; // rewardTokenId => RewardInfo (Struct defined in interface)

    // Passive Staking Reward Calculation State (Stream 1 - Time-based)
    uint256 public basePassiveStakingRate; // Wei of reward per second per wei staked, scaled by 1e18 for precision

    // --- Passive Holding Rewards State (Unstaked tokens) ---
      struct HoldingRewardInfo {
        uint256 rewardPerTokenStored; // Accumulated rewards (ERC20) per token held (scaled by 1e18)
        uint256 lastUpdateTime;
    }
    mapping(uint256 => HoldingRewardInfo) public holdingRewardInfo; // tokenId => Info (Struct defined in interface)
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
    mapping(uint256 => NftProperties) public nftProperties; // nftId => Properties (Struct/Enum defined in interface)

    // --- Constants ---
    uint256 private constant PRECISION_FACTOR = 1e18;
    uint16 private constant BASIS_POINTS_DIVISOR = 10000;

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
    constructor(address _rewardTokenAddress, address initialOwner) Ownable(initialOwner) { // Changed _owner to initialOwner
        if (_rewardTokenAddress == address(0)) revert ZeroAddress();
        rewardToken = IRewardToken(_rewardTokenAddress);
        // Initialize default lockup options with passive rate multipliers
        lockupOptions.push(LockupOption(0, 10000));       // 0: No lock, 1.00x passive rate
        lockupOptions.push(LockupOption(7 days, 11000));  // 1: 1 week,   1.10x passive rate
        lockupOptions.push(LockupOption(14 days, 12000)); // 2: 2 weeks,  1.20x passive rate
        lockupOptions.push(LockupOption(30 days, 13500)); // 3: 1 month,  1.35x passive rate
        // Base passive staking rate must be set by admin
        basePassiveStakingRate = 0;
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
        lockupOptions.push(LockupOption(duration, passiveRateMultiplierBp));
    }
    /** @inheritdoc IExchangeRewards*/
    function setBaseRewardRate(uint256 numerator, uint256 denominator) external override onlyOwner {
        require(denominator > 0, "Denominator cannot be zero");
        baseRewardRateNumerator = numerator;
        baseRewardRateDenominator = denominator;
    }

    /** @inheritdoc IExchangeRewards*/
    function setBasePassiveStakingRate(uint256 ratePerSecScaled) external override onlyOwner {
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
        // Use RewardToken's owner mint function - Ensure IRewardToken interface is correct
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
     ) public override onlyOwner { // Public so owner can update later
        if (!rewardToken.isEnhancementNFT(nftId)) revert NotEnhancementNFT();
        nftProperties[nftId] = NftProperties({
            bonusType: bonusType,
            targetEcosystem: targetEcosystem,
            bonusValue: bonusValue,
            isActive: isActive
        });
        emit NftPropertiesSet(nftId, bonusType, targetEcosystem, bonusValue, isActive);
     }

    // --- Core Interactions (Called by TicketExchange) ---

    /** @inheritdoc IExchangeRewards*/
    function recordFee(address paymentToken, uint256 platformFeeAmount) external payable override ReentrancyGuard {
        if (msg.sender != ticketExchange) revert NotTicketExchange();
        if (platformFeeAmount == 0) return;

        uint256 tokenId = uint256(uint160(paymentToken));
        uint256 amountForStaking = platformFeeAmount;

        // Allocate portion to Passive Holding Reward Pool
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
            stakingInfo.lastUpdateTime = block.timestamp; // Update timestamp

            // Distribute rewards based on TOTAL EFFECTIVE STAKED amount
            if (stakingInfo.totalEffectiveStaked > 0) {
                uint256 rewardAddedPerEffectiveToken = (amountForStaking * PRECISION_FACTOR) / stakingInfo.totalEffectiveStaked;
                stakingInfo.rewardPerTokenStored += rewardAddedPerEffectiveToken;
            }
        }
        emit FeeRecorded(paymentToken, amountForStaking);
    }

    /** @inheritdoc IExchangeRewards*/
    function getRewardMintRate(address paymentToken) external view override returns (uint256 rate) {
        // Implementation unchanged
        uint256 tokenId = uint256(uint160(paymentToken));
        uint256 totalStaked = rewardInfo[tokenId].totalStaked;
        uint256 totalSupply = rewardToken.totalSupply(tokenId);
        uint256 stakingRatio = 0;
        if (totalSupply > 0) {
            stakingRatio = (totalStaked * BASIS_POINTS_DIVISOR) / totalSupply;
            if(stakingRatio > BASIS_POINTS_DIVISOR) stakingRatio = BASIS_POINTS_DIVISOR;
        }
        uint256 boost = (stakingRatio * stakingRatioBoostFactor) / BASIS_POINTS_DIVISOR;
        uint256 multiplier = BASIS_POINTS_DIVISOR + boost;

       // Final rate = BaseRate * Multiplier (adjusting for BP and using 1e18 precision for rate)
         if (baseRewardRateDenominator == 0) return 0; // Avoid division by zero
        rate = (baseRewardRateNumerator * PRECISION_FACTOR / baseRewardRateDenominator) * multiplier / BASIS_POINTS_DIVISOR;
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
        // Implementation unchanged
        if (msg.sender != ticketExchange) revert NotTicketExchange();
        if (rewardToken.isEnhancementNFT(rewardTokenId)) revert CannotMintNFTAsReward();
        rewardToken.mint(buyer, rewardTokenId, rewardAmount, "");
     }

    /** @inheritdoc IExchangeRewards*/
    function verifyAndUsePurchaseBooster(
        address buyer,
        uint256 boosterNftId,
        address purchaseEcosystemAddress
    ) external override ReentrancyGuard returns (bool boosted) {
        if (msg.sender != ticketExchange) revert NotTicketExchange();
        if (boosterNftId == 0) return false;
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
    }

    // --- Admin Actions ---

    /** @inheritdoc IExchangeRewards*/
        // Distributes passive rewards for *holding* unstaked tokens
    function distributePassiveHoldingRewards(uint256[] calldata tokenIds) external override onlyOwner {
        // Implementation unchanged
         for (uint i = 0; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];
            address paymentToken = address(uint160(tokenId));
            uint256 poolAmount = passiveRewardPool[paymentToken];
            if (poolAmount > 0) {
                uint256 totalSupply = rewardToken.totalSupply(tokenId);
                if (totalSupply > 0) {
                    uint256 addedRewardPerToken = poolAmount * PRECISION_FACTOR / totalSupply;
                    HoldingRewardInfo storage info = holdingRewardInfo[tokenId];
                    info.rewardPerTokenStored += addedRewardPerToken;
                    info.lastUpdateTime = block.timestamp;
                    passiveRewardPool[paymentToken] = 0;
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
        uint256 currentTime = block.timestamp; // Cache timestamp
        uint256 endTime = (chosenOption.duration == 0) ? 0 : currentTime + chosenOption.duration;

        RewardInfo storage stakingInfo = rewardInfo[tokenId];
        _updateFeeShareReward(stakingInfo); // Update fee share accumulator

        // Transfer reward tokens from user
        // Using virtual function call for potential future overrides if needed
        IRewardToken(rewardToken).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");

        // Create stake record - CORRECTED INITIALIZATION (10 fields)
        uint256 stakeId = nextStakeId++;
        // Use updated StakeInfo struct definition
        stakes[stakeId] = StakeInfo({ 
            tokenId: tokenId,
            owner: msg.sender,
            amount: amount,
            startTime: currentTime, 
            endTime: endTime,
            durationOption: durationOption,
            feeShareRewardDebt: stakingInfo.rewardPerTokenStored, // Initialize debt for fee share
            lastPassiveRewardClaimTime: currentTime, // Initialize passive claim time to now
            attachedNftId: 0,
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
    function unstake(uint256 stakeId) external override ReentrancyGuard { // Use nonReentrant from custom import
        StakeInfo storage stake = stakes[stakeId]; 
        address user = msg.sender;
        // ... (Ownership, active, lock checks) ...
        if (stake.owner != user) revert NotStakeOwner();
        if (!stake.active) revert StakeNotActive();
        if (stake.endTime != 0 && block.timestamp < stake.endTime) revert StakeLocked();


        uint256 tokenId = stake.tokenId;
        uint256 amount = stake.amount;

        // --- Calculate Rewards BEFORE modifying state ---
        RewardInfo storage stakingInfo = rewardInfo[tokenId];
        _updateFeeShareReward(stakingInfo);

        uint256 pendingFeeShare = _calculatePendingFeeShareRewards(stakeId, stakingInfo.rewardPerTokenStored);
        uint256 pendingPassive = _calculatePendingPassiveStakingRewards(stake, block.timestamp); // Calculate passive rewards

        // --- Modify State ---
        // ... (Update active, totals, detach NFT, remove from _userStakes - unchanged) ...
        stake.active = false;
        uint256 currentEffectiveAmount = _getEffectiveStakedAmount(stake.amount, stake.attachedNftId);
        stakingInfo.totalStaked -= amount;
        stakingInfo.totalEffectiveStaked -= currentEffectiveAmount;
        uint256 nftIdToReturn = 0;
        if (stake.attachedNftId != 0) {
            nftIdToReturn = _detachStakingNftInternal(stake, stakeId);
        }
        _userStakes[user].remove(stakeId);


        // --- Transfer Assets ---
        // 1. Principal (ERC1155 RewardToken)
        IRewardToken(rewardToken).safeTransferFrom(address(this), user, tokenId, amount, "");

        // 2. Fee Share Rewards (Stream 2 - ERC20 paymentToken)
        if (pendingFeeShare > 0) {
            address paymentToken = address(uint160(tokenId));
            IERC20(paymentToken).safeTransfer(user, pendingFeeShare);
            emit StakingFeeShareRewardsClaimed(user, tokenId, pendingFeeShare);
        }
 
        // 3. Passive Accrual Rewards (Stream 1 - MINT ERC1155 RewardToken)
        if (pendingPassive > 0) {
            // Mint the rewards directly to the user
            rewardToken.mint(user, tokenId, pendingPassive, ""); // Use existing mint authority
            emit PassiveStakingRewardsClaimed(user, stakeId, pendingPassive);
        }

        // 4. Detached NFT (ERC1155 RewardToken - NFT ID)
        if (nftIdToReturn != 0) {
             IRewardToken(rewardToken).safeTransferFrom(address(this), user, nftIdToReturn, 1, "");
        }

        emit Unstaked(user, stakeId, tokenId, amount);
    }

    /** @inheritdoc IExchangeRewards*/
    function attachStakingNft(uint256 stakeId, uint256 nftId) external override ReentrancyGuard {
         StakeInfo storage stake = stakes[stakeId];
         address user = msg.sender;
         if (stake.owner != user) revert NotStakeOwner();
         if (!stake.active) revert StakeNotActive();
         if (stake.attachedNftId != 0) revert EnhancementAlreadyAttached();
         if (!rewardToken.isEnhancementNFT(nftId)) revert NotEnhancementNFT();
         if (rewardToken.balanceOf(user, nftId) < 1) revert UserDoesNotOwnNFT();

         NftProperties storage properties = nftProperties[nftId];
         if (!properties.isActive) revert NftInactive();
        // Check if NFT is a STAKING booster type (Passive or Fee Share)
         if (properties.bonusType != BonusType.PASSIVE_STAKING_RATE_BOOST && properties.bonusType != BonusType.STAKING_FEE_SHARE_BOOST) {
             revert NftNotBoosterType();
         }

         RewardInfo storage stakingInfo = rewardInfo[stake.tokenId];
         _updateFeeShareReward(stakingInfo); // Settle fee share rewards first

        // Settle Fee Share debt before changing effective amount
         uint256 pendingFeeShare = _calculatePendingFeeShareRewards(stakeId, stakingInfo.rewardPerTokenStored);
         if (pendingFeeShare > 0) {
              stake.feeShareRewardDebt = stakingInfo.rewardPerTokenStored; // Update debt before boost changes things
         }

         // Settle Passive Rewards? No, boost applies going forward.

         uint256 oldEffectiveAmount = _getEffectiveStakedAmount(stake.amount, 0);
         uint256 newEffectiveAmount = _getEffectiveStakedAmount(stake.amount, nftId);

         IRewardToken(rewardToken).safeTransferFrom(user, address(this), nftId, 1, "");
         IRewardToken(rewardToken).setNFTLocked(nftId, true);

         stake.attachedNftId = nftId;
        // Boost BPs are now read dynamically via _getNftBoosts or _getEffectiveStakedAmount

         stakingInfo.totalEffectiveStaked = stakingInfo.totalEffectiveStaked - oldEffectiveAmount + newEffectiveAmount;

         emit StakingNftAttached(stakeId, nftId);
    }

    /**
     * @dev Internal: Handles NFT detachment logic. Updates stake state and unlocks NFT.
     * @param stake The stake storage pointer.
     * @param stakeId The ID of the stake being modified.
     * @return nftId The ID of the detached NFT, or 0 if none.
     */
     function _detachStakingNftInternal(StakeInfo storage stake, uint256 stakeId) internal returns (uint256 nftId) { // Added stakeId param
        nftId = stake.attachedNftId;
        if (nftId == 0) return 0; // Nothing attached

        // Update stake state only
        stake.attachedNftId = 0;

        // Unlock NFT status in RewardToken contract
        IRewardToken(rewardToken).setNFTLocked(nftId, false);

        emit StakingNftDetached(stakeId, nftId); // Now we have stakeId to emit correctly

        return nftId; // Return ID so caller can transfer it back
     }



       /** @inheritdoc IExchangeRewards*/
    function claimFeeShareRewards(uint256[] calldata stakeIds) external override ReentrancyGuard { // Use nonReentrant from custom import
        address user = msg.sender;  
        // Use dynamic array + count for unique token tracking locally
        address[] memory uniquePaymentTokensList = new address[](stakeIds.length); // Max size needed
        uint256 uniqueTokenCount = 0;
        // Removed invalid mapping: mapping(address => bool) memory alreadyAdded;

        // --- Aggregation Phase ---
        for (uint i = 0; i < stakeIds.length; i++) {
            uint256 stakeId = stakeIds[i];
            StakeInfo storage stake = stakes[stakeId]; // Storage pointer

            if (stake.owner != user || !stake.active) {
                continue; // Skip if not owner or inactive
            }

            uint256 currentTokenId = stake.tokenId; // Cache for efficiency
            RewardInfo storage stakingInfo = rewardInfo[currentTokenId]; // Storage pointer
            _updateFeeShareReward(stakingInfo); // Update global accumulator timestamp if needed by model

            uint256 pending = _calculatePendingFeeShareRewards(stakeId, stakingInfo.rewardPerTokenStored);

            if (pending > 0) {
                // Update stake's debt to current level BEFORE aggregating reward
                stake.feeShareRewardDebt = stakingInfo.rewardPerTokenStored;

                // Aggregate total rewards per payment token type
                address paymentToken = address(uint160(currentTokenId));
                totalRewardsByToken[paymentToken] += pending;

                // --- Check if paymentToken is already in unique list ---
                bool found = false;
                // Iterate only through the unique tokens found so far
                for (uint j = 0; j < uniqueTokenCount; j++) {
                    if (uniquePaymentTokensList[j] == paymentToken) {
                        found = true;
                        break; // Exit inner loop once found
                    }
                }
                // --- Add to list if not found ---
                if (!found) {
                    // Add check to prevent overflow - unlikely but safe
                    if(uniqueTokenCount < uniquePaymentTokensList.length) {
                         uniquePaymentTokensList[uniqueTokenCount] = paymentToken;
                         uniqueTokenCount++; // Increment count of unique tokens found
                    }
                    // else { revert("Too many unique tokens"); } // Optional safety
                }
                // --- End uniqueness check ---
            }
        }

        // --- Transfer Phase ---
        // Iterate only up to the actual number of unique tokens found
        for (uint i = 0; i < uniqueTokenCount; ++i) {
             address paymentToken = uniquePaymentTokensList[i];
             // Retrieve the aggregated amount from the temporary mapping
             uint256 amountToTransfer = totalRewardsByToken[paymentToken];

             if (amountToTransfer > 0) {
                 // Perform the transfer
                 IERC20(paymentToken).safeTransfer(user, amountToTransfer);

                 // Emit event for each token type claimed
                 uint256 correspondingTokenId = uint256(uint160(paymentToken));
                 emit StakingFeeShareRewardsClaimed(user, correspondingTokenId, amountToTransfer);

                 // Optional: Clear the temporary map entry
                 // delete totalRewardsByToken[paymentToken];
             }
        }
    }

    /** @inheritdoc IExchangeRewards*/
    function claimPassiveStakingRewards(uint256[] calldata stakeIds) external override ReentrancyGuard { // Use nonReentrant from custom import
        address user = msg.sender;
 
        // Use dynamic array + count for unique token tracking locally
        address[] memory uniquePaymentTokensList = new address[](stakeIds.length); // Max size needed
        uint256 uniqueTokenCount = 0;
        // Removed: EnumerableSet.AddressSet memory uniquePaymentTokens; // INVALID

        uint256 currentTime = block.timestamp; // Cache current time for consistency

        // --- Aggregation Phase ---
        for (uint i = 0; i < stakeIds.length; ++i) {
            uint256 stakeId = stakeIds[i];
            StakeInfo storage stake = stakes[stakeId];

            if (stake.owner != user || !stake.active) {
                continue; // Skip invalid/inactive stakes
            }

            // Calculate pending passive rewards up to current time
            uint256 pendingPassive = _calculatePendingPassiveStakingRewards(stake, currentTime);

            if (pendingPassive > 0) {
                // Update the last claim time *before* aggregating/transferring
                stake.lastPassiveRewardClaimTime = currentTime;

                // Aggregate rewards by payment token
                address paymentToken = address(uint160(stake.tokenId));
                totalRewardsByToken[paymentToken] += pendingPassive;

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
                    // Add check to prevent overflow if stakeIds contains duplicates leading to > length unique tokens
                    // Though this shouldn't happen with correct external input.
                    if(uniqueTokenCount < uniquePaymentTokensList.length) {
                         uniquePaymentTokensList[uniqueTokenCount] = paymentToken;
                         uniqueTokenCount++; // Increment count of unique tokens found
                    }
                    // else { revert("Too many unique tokens found"); } // Optional safety
                }
                // --- End uniqueness check ---
            }
        }

        // --- Transfer Phase ---
        // Iterate only up to the actual number of unique tokens found
        for (uint i = 0; i < uniqueTokenCount; ++i) {
            address paymentToken = uniquePaymentTokensList[i];
            // Retrieve the aggregated amount from the temporary mapping
            uint256 amountToTransfer = totalRewardsByToken[paymentToken];

            if (amountToTransfer > 0) {
                // Check contract has funds deposited by owner
                if (IERC20(paymentToken).balanceOf(address(this)) < amountToTransfer) {
                    revert InsufficientFundsForPassiveReward();
                }
                // Perform the transfer
                IERC20(paymentToken).safeTransfer(user, amountToTransfer);

                // Emit event - Finding *a* relevant stakeId is inefficient/imprecise here
                // Consider changing event or accepting imprecision
                uint256 correspondingTokenId = uint256(uint160(paymentToken));
                uint256 emittedStakeId = 0; // Default if no suitable ID found quickly
                 for(uint j=0; j<stakeIds.length; ++j) { // Find first matching stakeId for event context
                     if(stakes[stakeIds[j]].tokenId == correspondingTokenId && stakes[stakeIds[j]].owner == user ) { // Basic check
                         emittedStakeId = stakeIds[j];
                         break;
                     }
                 }
                emit PassiveStakingRewardsClaimed(user, emittedStakeId, amountToTransfer); // Emit with best-effort stakeId

                 // Optional: Clear the temporary map entry (usually not necessary for storage map local var)
                 // delete totalRewardsByToken[paymentToken];
            }
        }
    }

    /** @inheritdoc IExchangeRewards*/
    function claimHoldingReward(uint256 tokenId) external override ReentrancyGuard {
        // Implementation unchanged from previous version
         address user = msg.sender;
         if (rewardToken.isEnhancementNFT(tokenId)) revert CannotClaimForNFT();
         uint256 pending = pendingHoldingRewards(user, tokenId);
         if (pending == 0) revert NoRewardsToClaim();
         userHoldingRewardDebt[user][tokenId] = holdingRewardInfo[tokenId].rewardPerTokenStored;
         address paymentToken = address(uint160(tokenId));
         IERC20(paymentToken).safeTransfer(user, pending);
         emit HoldingRewardsClaimed(user, tokenId, pending);
    }

    /** @inheritdoc IExchangeRewards*/
    function claimDiscountVoucher(uint256 rewardTokenId, uint256 amountToBurn) external override ReentrancyGuard {
        // Implementation unchanged from previous version
         address user = msg.sender;
         if (rewardToken.isEnhancementNFT(rewardTokenId)) revert CannotClaimForNFT();
         if (amountToBurn == 0) revert AmountMustBePositive();
         if (rewardToken.balanceOf(user, rewardTokenId) < amountToBurn) revert InsufficientBalance();
         uint256 discountRatePerPaymentTokenUnit = 10; // TODO: Configurable
         if (discountRatePerPaymentTokenUnit == 0) revert("Discount rate not set");
         uint256 discountValue = amountToBurn / discountRatePerPaymentTokenUnit;
         if (discountValue == 0) revert BurnAmountTooSmall();
         rewardToken.burnFrom(user, rewardTokenId, amountToBurn);
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

    /** @dev Calculates pending fee share rewards (Stream 2) */
    function _calculatePendingFeeShareRewards(uint256 stakeId, uint256 currentGlobalRewardPerToken_scaled) internal view returns (uint256) {
        // Implementation unchanged
        StakeInfo storage stake = stakes[stakeId];
        if (!stake.active) return 0;
        uint256 rewardPerToken = currentGlobalRewardPerToken_scaled;
        uint256 debtPerToken = stake.feeShareRewardDebt;
        if (rewardPerToken <= debtPerToken) return 0;
        uint256 effectiveAmount = _getEffectiveStakedAmount(stake.amount, stake.attachedNftId);
        uint256 earned = (effectiveAmount * (rewardPerToken - debtPerToken)) / PRECISION_FACTOR;
        return earned;
    }

    /** @dev Calculates pending passive staking rewards (Stream 1) for a single stake up to a given time.*/
     function _calculatePendingPassiveStakingRewards(StakeInfo storage stake, uint256 calculationTime) internal view returns (uint256 pending) {
        // Implementation unchanged
         if (!stake.active || calculationTime <= stake.lastPassiveRewardClaimTime) {
             return 0;
         } 
         uint256 baseRate = basePassiveStakingRate;
         if (baseRate == 0) return 0;
         uint16 lockupMultiplierBp = lockupOptions[stake.durationOption].passiveRateMultiplierBp;
         uint16 nftBoostBp = _getPassiveRateBoostBP(stake.attachedNftId);
         uint256 effectiveRateScaled = baseRate * lockupMultiplierBp / BASIS_POINTS_DIVISOR;
         effectiveRateScaled = effectiveRateScaled * (BASIS_POINTS_DIVISOR + nftBoostBp) / BASIS_POINTS_DIVISOR;
         uint256 timeElapsed = calculationTime - stake.lastPassiveRewardClaimTime;
         pending = (effectiveRateScaled * stake.amount * timeElapsed) / PRECISION_FACTOR;
         return pending; // Returns amount of RewardToken (ID=stake.tokenId) to mint
     }

    /** @dev Calculates pending passive staking rewards (Stream 1) - Internal helper taking ID */
    function _calculatePendingPassiveStakingRewards(uint256 stakeId) internal view returns (uint256) {
        // Calls the struct version with current block time
        return _calculatePendingPassiveStakingRewards(stakes[stakeId], block.timestamp);
    }


    /** @dev Calculates the effective stake amount considering NFT boost */
    function _getEffectiveStakedAmount(uint256 actualAmount, uint256 attachedNftId) internal view returns (uint256 effectiveAmount) {
        // Implementation unchanged
        effectiveAmount = actualAmount;
        if (attachedNftId != 0) {
            NftProperties storage properties = nftProperties[attachedNftId];
            if (properties.isActive && properties.bonusType == BonusType.STAKING_FEE_SHARE_BOOST) {
                 effectiveAmount = (actualAmount * (BASIS_POINTS_DIVISOR + uint16(properties.bonusValue))) / BASIS_POINTS_DIVISOR;
            }
        }
    }

      /** @dev Gets passive rate boost BP from attached NFT */
     function _getPassiveRateBoostBP(uint256 attachedNftId) internal view returns (uint16 boostBp) {
         // Implementation unchanged
        boostBp = 0;
        if (attachedNftId != 0) {
             NftProperties storage properties = nftProperties[attachedNftId];
            if (properties.isActive && properties.bonusType == BonusType.PASSIVE_STAKING_RATE_BOOST) {
                 boostBp = uint16(properties.bonusValue);
            } 
        }
     }

    /** @inheritdoc IExchangeRewards*/
    function pendingFeeShareRewards(uint256 stakeId) external view override returns (uint256) {
        // Implementation unchanged
        StakeInfo storage stake = stakes[stakeId];
        // Allow viewing inactive stake rewards? Yes.
        // if (!stake.active) return 0;
        RewardInfo storage stakingInfo = rewardInfo[stake.tokenId];
        return _calculatePendingFeeShareRewards(stakeId, stakingInfo.rewardPerTokenStored);
    }

    /** @inheritdoc IExchangeRewards*/
    function pendingPassiveStakingRewards(uint256 stakeId) external view override returns (uint256) {
        // Calls the internal helper which uses block.timestamp
        // Need to ensure stake exists, maybe check active? Let internal handle active check for now.
        return _calculatePendingPassiveStakingRewards(stakeId);
    }

    /** @inheritdoc IExchangeRewards*/
    function getStakeInfo(uint256 stakeId) external view override returns (StakeInfo memory) {
         // Access check? No, info is public.
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
         uint256 globalRewardPerToken = info.rewardPerTokenStored;
         uint256 userDebtPerToken = userHoldingRewardDebt[user][tokenId];
         if (globalRewardPerToken <= userDebtPerToken) return 0;
         uint256 userBalance = rewardToken.balanceOf(user, tokenId);
         if (userBalance == 0) return 0;
         uint256 reward = (userBalance * (globalRewardPerToken - userDebtPerToken)) / PRECISION_FACTOR;
         return reward;
     }

    /** @inheritdoc IExchangeRewards*/
    function getLockupOptions() external view override returns (uint256[] memory durations, uint16[] memory passiveRateMultipliers) {
        // Implementation unchanged
         uint256 length = lockupOptions.length;
         durations = new uint256[](length);
         passiveRateMultipliers = new uint16[](length);
         for(uint i = 0; i < length; ++i) {
             durations[i] = lockupOptions[i].duration;
             passiveRateMultipliers[i] = lockupOptions[i].passiveRateMultiplierBp;
         }
         return (durations, passiveRateMultipliers);
     }

    // --- IERC1155Receiver ---
    /** @inheritdoc IERC1155Receiver*/
    function onERC1155Received( address /*operator*/, address /*from*/, uint256 /*id*/, uint256 /*value*/, bytes calldata /*data*/) external override returns (bytes4) {
        // Basic implementation accepts transfers (needed for NFT attach)
         return this.onERC1155Received.selector;
    } 

    /** @inheritdoc IERC1155Receiver*/
    function onERC1155BatchReceived( address /*operator*/, address /*from*/, uint256[] calldata /*ids*/, uint256[] calldata /*values*/, bytes calldata /*data*/) external override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    // --- Supports Interface ---
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return interfaceId == type(IExchangeRewards).interfaceId || interfaceId == type(IERC1155Receiver).interfaceId;
    }
}