// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol"; // For iterating claims if needed

import { IExchangeRewards } from "./interfaces/IExchangeRewards.sol";
import "./interfaces/IRewardToken.sol";

/**
 * @title ExchangeRewards Contract
 * @dev Manages staking, passive rewards, NFT enhancements, discounts, and fee distribution.
 */
contract ExchangeRewards is IExchangeRewards, Ownable, ReentrancyGuard, IERC1155Receiver {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet; // Example if map iteration needed

    IRewardToken public immutable rewardToken;
    address public ticketExchange; // Address of the TicketExchange contract

    // --- Staking State ---
    struct StakeInfo {
        uint256 tokenId; // Reward token ID (== ERC20 address)
        address owner;
        uint256 amount;
        uint256 startTime;
        uint256 endTime; // 0 if no lock
        uint16 rewardMultiplierBasisPoints; // Multiplier from lock duration
        uint256 rewardDebt; // Tracks rewards already accounted for (scaled by 1e18)
        uint256 enhancementNftId; // 0 if none
        uint16 enhancementBoostBasisPoints; // Additional boost from NFT
        bool active;
    }
    mapping(uint256 => StakeInfo) public stakes;
    uint256 public nextStakeId;
    mapping(address => EnumerableSet.UintSet) private _userStakes; // user => set of active stake IDs

    struct LockupOption {
        uint256 duration; // seconds
        uint16 rewardMultiplierBasisPoints; // 10000 = 1x
    }
    LockupOption[] public lockupOptions;

    // Staking Reward Calculation State (Accumulator Pattern)
    struct RewardInfo {
        uint256 rewardPerTokenStored; // Accumulated rewards (ERC20) per token staked (scaled by 1e18)
        uint256 lastUpdateTime;
        uint256 totalStaked; // Total amount of this tokenId currently staked
    }
    mapping(uint256 => RewardInfo) public rewardInfo; // tokenId => RewardInfo

    // --- Passive Holding Rewards State ---
    struct HoldingRewardInfo {
         uint256 rewardPerTokenStored; // Accumulated rewards (ERC20) per token held (scaled by 1e18)
         uint256 lastUpdateTime;
    }
    mapping(uint256 => HoldingRewardInfo) public holdingRewardInfo;
    mapping(address => mapping(uint256 => uint256)) public userHoldingRewardDebt; // user => tokenId => debt (scaled by 1e18)
    uint16 public passiveRewardFeeShareBasisPoints; // e.g., 500 = 5%
    mapping(address => uint256) internal passiveRewardPool; // paymentToken => accumulated ERC20 amount for passive distribution

    // --- Discount State ---
    mapping(address => mapping(address => uint256)) public userDiscountCredit; // user => paymentToken => credit amount (in paymentToken units)

    // --- Dynamic Rate State ---
    uint256 public baseRewardRateNumerator = 1;   // Default: 1 reward token...
    uint256 public baseRewardRateDenominator = 100; // ...per 100 payment tokens (1%)
    uint16 public stakingRatioBoostFactor = 5000; // Default: 0.5x boost potential from staking ratio (5000 BP)

    // --- NFT Boost Override State ---
    mapping(uint256 => uint16) public nftBoostOverrides; // nftId => boostBasisPoints

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
    error InsufficientBalance();
    error BurnAmountTooSmall();
    error CannotClaimForNFT();
    error NoRewardsToClaim();


    // --- Constructor ---
    constructor(address _rewardTokenAddress, address initialOwner) Ownable(initialOwner) {
        rewardToken = IRewardToken(_rewardTokenAddress);
        // Initialize default lockup optionswwwwa
        lockupOptions.push(LockupOption(0, 10000));       // 0: No lock, 1.00x
        lockupOptions.push(LockupOption(7 days, 11000));  // 1: 1 week,   1.10x
        lockupOptions.push(LockupOption(14 days, 12000)); // 2: 2 weeks,  1.20x
        lockupOptions.push(LockupOption(30 days, 13500)); // 3: 1 month,  1.35x
    }

    // --- Configuration Functions --- (Ownable) ---
    /** @inheritdoc IExchangeRewards*/    
    function setTicketExchange(address _ticketExchange) external override onlyOwner {
        require(_ticketExchange != address(0), "Zero address");
        ticketExchange = _ticketExchange;
    }

    /** @inheritdoc IExchangeRewards*/
    function addLockupOption(uint256 duration, uint16 multiplierBp) external override onlyOwner {
        require(multiplierBp >= 10000, "Multiplier must be >= 1x"); // Basic sanity check
        lockupOptions.push(LockupOption(duration, multiplierBp));
    }

    /** @inheritdoc IExchangeRewards*/
    function setBaseRewardRate(uint256 numerator, uint256 denominator) external override onlyOwner {
        require(denominator > 0, "Denominator cannot be zero");
        baseRewardRateNumerator = numerator;
        baseRewardRateDenominator = denominator;
    }

    /** @inheritdoc IExchangeRewards*/
    function setStakingRatioBoostFactor(uint16 boostFactorBp) external override onlyOwner {
        stakingRatioBoostFactor = boostFactorBp; // Allow 0
    }

    /** @inheritdoc IExchangeRewards*/
    function setPassiveRewardFeeShare(uint16 basisPoints) external override onlyOwner {
        require(basisPoints <= 10000, "Cannot exceed 100%");
        passiveRewardFeeShareBasisPoints = basisPoints;
    }

    /** @inheritdoc IExchangeRewards*/
    function setNftBoostOverride(uint256 nftId, uint16 boostBasisPoints) external override onlyOwner {
        if (!rewardToken.isEnhancementNFT(nftId)) revert NotEnhancementNFT();
        nftBoostOverrides[nftId] = boostBasisPoints;
        emit NftBoostOverrideSet(nftId, boostBasisPoints);
    }


    // --- Core Logic ---

    /** @inheritdoc IExchangeRewards*/
    function recordFee(address paymentToken, uint256 amount) external override payable nonReentrant {
        // Payable allows receiving native coin if used as paymentToken/fee
        if (msg.sender != ticketExchange) revert NotTicketExchange();
        if (amount == 0) return; // No fee, nothing to do

        uint256 tokenId = uint256(uint160(paymentToken));
        uint256 amountForStaking = amount;

        // Allocate portion to Passive Reward Pool (accounting only)
        if (passiveRewardFeeShareBasisPoints > 0) {
            uint256 passiveShare = amount * passiveRewardFeeShareBasisPoints / 10000;
            if (passiveShare > 0) {
                passiveRewardPool[paymentToken] += passiveShare;
                amountForStaking -= passiveShare;
            }
        }

        // Allocate remaining portion to Staking Rewards
        if (amountForStaking > 0) {
            RewardInfo storage stakingInfo = rewardInfo[tokenId];
            _updateStakingRewardAccumulator(stakingInfo); // Update based on time elapsed if rate-based

            if (stakingInfo.totalStaked > 0) {
                // Add new rewards per staked token unit
                stakingInfo.rewardPerTokenStored += (amountForStaking * 1e18 / stakingInfo.totalStaked);
            }
            // If totalStaked is 0, the rewards are effectively lost for stakers (or pool them?)
            // For simplicity, they are lost if no one is staked. Alternatively, pool them.
        }
        // Note: Actual ERC20 tokens need to be held by this contract. TicketExchange should transfer the full fee amount here.

        emit FeeRecorded(paymentToken, amountForStaking); // Event shows amount for staking pool
    }

    /** @inheritdoc IExchangeRewards*/
    function getRewardMintRate(address paymentToken) external view override returns (uint256 rate) {
        uint256 tokenId = uint256(uint160(paymentToken));
        uint256 totalStaked = rewardInfo[tokenId].totalStaked;
        uint256 totalSupply = rewardToken.totalSupply(tokenId);

        uint256 stakingRatio = 0; // Basis points (0-10000)
        if (totalSupply > 0) {
            stakingRatio = totalStaked * 10000 / totalSupply;
            if(stakingRatio > 10000) stakingRatio = 10000; // Cap at 100%
        }

        // Rate boost calculation: Boost = Ratio * Factor
        uint256 boost = stakingRatio * stakingRatioBoostFactor / 10000; // Result is in Basis Points
        uint256 multiplier = 10000 + boost; // Final multiplier in Basis Points

        // Final rate = BaseRate * Multiplier (adjusting for BP and using 1e18 precision for rate)
        // rate = (baseNum * 1e18 / baseDenom) * (multiplier / 10000)
        rate = (baseRewardRateNumerator * 1e18 / baseRewardRateDenominator) * multiplier / 10000;
        // This 'rate' represents: how many reward tokens (wei) to mint per 1 unit (wei) of paymentToken
    }

    /** @inheritdoc IExchangeRewards*/
    function distributePassiveRewards(uint256[] calldata tokenIds) external override onlyOwner {
        // Implementation as defined in thought process
        for (uint i = 0; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];
            address paymentToken = address(uint160(tokenId));
            uint256 poolAmount = passiveRewardPool[paymentToken];

            if (poolAmount > 0) {
                uint256 totalSupply = rewardToken.totalSupply(tokenId);
                if (totalSupply > 0) {
                    uint256 addedRewardPerToken = poolAmount * 1e18 / totalSupply; // Scale for precision

                    HoldingRewardInfo storage info = holdingRewardInfo[tokenId];
                    info.rewardPerTokenStored += addedRewardPerToken;
                    info.lastUpdateTime = block.timestamp;
                    passiveRewardPool[paymentToken] = 0; // Reset pool for this token

                    emit PassiveRewardsDistributed(tokenId, poolAmount, addedRewardPerToken);
                }
            }
        }
    }

    // --- User Staking ---

    /** @inheritdoc IExchangeRewards*/
    function stake(uint256 tokenId, uint256 amount, uint8 durationOption) external override nonReentrant {
        if (rewardToken.isEnhancementNFT(tokenId)) revert CannotStakeNFT();
        if (amount == 0) revert AmountMustBePositive();
        if (durationOption >= lockupOptions.length) revert InvalidDurationOption();

        LockupOption storage chosenOption = lockupOptions[durationOption];
        uint256 endTime = (chosenOption.duration == 0) ? 0 : block.timestamp + chosenOption.duration;

        RewardInfo storage stakingInfo = rewardInfo[tokenId];
        _updateStakingRewardAccumulator(stakingInfo); // Update rewards before changing stake

        // Transfer reward tokens from user
        rewardToken.safeTransferFrom(msg.sender, address(this), tokenId, amount, "");

        // Create stake record
        uint256 stakeId = nextStakeId++;
        uint256 initialRewardDebt = stakingInfo.rewardPerTokenStored * amount / 1e18; // Calculate initial debt
        stakes[stakeId] = StakeInfo({
            tokenId: tokenId,
            owner: msg.sender,
            amount: amount,
            startTime: block.timestamp,
            endTime: endTime,
            rewardMultiplierBasisPoints: chosenOption.rewardMultiplierBasisPoints,
            rewardDebt: initialRewardDebt,
            enhancementNftId: 0,
            enhancementBoostBasisPoints: 0,
            active: true
        });
        _userStakes[msg.sender].add(stakeId);

        // Update total staked
        stakingInfo.totalStaked += amount;

        emit Staked(msg.sender, stakeId, tokenId, amount, endTime, chosenOption.rewardMultiplierBasisPoints);
    }

    /** @inheritdoc IExchangeRewards*/
    function unstake(uint256 stakeId) external override nonReentrant {
        StakeInfo storage stake = stakes[stakeId];
        address user = msg.sender;
        if (stake.owner != user) revert NotStakeOwner();
        if (!stake.active) revert StakeNotActive();
        if (stake.endTime != 0 && block.timestamp < stake.endTime) revert StakeLocked();

        uint256 tokenId = stake.tokenId;
        uint256 amount = stake.amount;

        // Update rewards before calculating final payout and modifying state
        RewardInfo storage stakingInfo = rewardInfo[tokenId];
         _updateStakingRewardAccumulator(stakingInfo);

        // Calculate pending rewards
        uint256 pending = _calculatePendingStakingRewards(stakeId, stakingInfo.rewardPerTokenStored);

        // Update stake state
        stake.active = false;

        // Update global state
        stakingInfo.totalStaked -= amount;

        // Detach NFT if attached
        uint256 nftIdToReturn = 0;
        if (stake.enhancementNftId != 0) {
            nftIdToReturn = _detachNFTInternal(stake);
        }

        // Remove from user's active stakes
        _userStakes[user].remove(stakeId);

        // Transfer principal back
        rewardToken.safeTransferFrom(address(this), user, tokenId, amount, "");

        // Transfer pending rewards (if any)
        if (pending > 0) {
            address paymentToken = address(uint160(tokenId));
            IERC20(paymentToken).safeTransfer(user, pending);
            emit StakingRewardsClaimed(user, tokenId, pending); // Emit reward event
        }

        // Transfer enhancement NFT back if detached
        if (nftIdToReturn != 0) {
             rewardToken.safeTransferFrom(address(this), user, nftIdToReturn, 1, "");
        }


        emit Unstaked(user, stakeId, tokenId, amount);
    }

    // --- User Rewards Claiming ---

    /** @inheritdoc IExchangeRewards*/
    function claimStakingRewards(uint256[] calldata stakeIds) external override nonReentrant {
        address user = msg.sender;
        mapping(address => uint256) totalRewardsByToken; // paymentToken => amount

        for (uint i = 0; i < stakeIds.length; i++) {
            uint256 stakeId = stakeIds[i];
            StakeInfo storage stake = stakes[stakeId];

            if (stake.owner != user) revert NotStakeOwner(); // Check ownership early
            if (!stake.active) continue; // Skip inactive stakes silently or revert? Let's skip.

            RewardInfo storage stakingInfo = rewardInfo[stake.tokenId];
            _updateStakingRewardAccumulator(stakingInfo); // Update accumulator

            uint256 pending = _calculatePendingStakingRewards(stakeId, stakingInfo.rewardPerTokenStored);

            if (pending > 0) {
                // Update reward debt for the stake to prevent double claiming
                stake.rewardDebt += pending; // Add claimed amount to debt

                address paymentToken = address(uint160(stake.tokenId));
                totalRewardsByToken[paymentToken] += pending;
            }
        }

        // Perform ERC20 transfers for aggregated amounts
        // To iterate map keys, we'd need to store them or use a library.
        // Simple approach: Assume FE calls this per paymentToken type or user knows which tokens they had rewards for.
        // We *must* iterate to transfer. Using EnumerableSet for map keys pattern:
        // Example (requires tracking unique payment tokens involved):
        // address[] memory paymentTokens = getKeys(totalRewardsByToken); // pseudo-code for getting keys
         for (uint i = 0; i < stakeIds.length; ++i) { // Inefficient way to find unique keys
             uint256 stakeId = stakeIds[i];
              if (!stakes[stakeId].active) continue; // Skip inactive stakes used only for key finding
             address paymentToken = address(uint160(stakes[stakeId].tokenId));
             uint256 amountToTransfer = totalRewardsByToken[paymentToken];
             if (amountToTransfer > 0) {
                 IERC20(paymentToken).safeTransfer(user, amountToTransfer);
                 emit StakingRewardsClaimed(user, stakes[stakeId].tokenId, amountToTransfer);
                 totalRewardsByToken[paymentToken] = 0; // Mark as transferred
             }
         }
         // A better approach involves storing the unique token addresses from the loop.
    }


    /** @inheritdoc IExchangeRewards*/
    function claimHoldingReward(uint256 tokenId) external override nonReentrant {
         // Implementation as refined previously
         address user = msg.sender;
         if (rewardToken.isEnhancementNFT(tokenId)) revert CannotClaimForNFT();

         uint256 pending = pendingHoldingRewards(user, tokenId); // Uses view function

         if (pending == 0) revert NoRewardsToClaim();

         userHoldingRewardDebt[user][tokenId] = holdingRewardInfo[tokenId].rewardPerTokenStored; // Update debt
         address paymentToken = address(uint160(tokenId));
         IERC20(paymentToken).safeTransfer(user, pending); // Transfer from contract's balance

         emit HoldingRewardsClaimed(user, tokenId, pending);
    }

    // --- NFT Enhancement Logic ---

    /** @inheritdoc IExchangeRewards*/
    function attachEnhancementNFT(uint256 stakeId, uint256 enhancementNftId) external override nonReentrant {
         StakeInfo storage stake = stakes[stakeId];
         address user = msg.sender;
         if (stake.owner != user) revert NotStakeOwner();
         if (!stake.active) revert StakeNotActive();
         if (stake.enhancementNftId != 0) revert EnhancementAlreadyAttached();
         if (!rewardToken.isEnhancementNFT(enhancementNftId)) revert NotEnhancementNFT();
         if (rewardToken.balanceOf(user, enhancementNftId) < 1) revert UserDoesNotOwnNFT();

         uint16 boostFactorBp = _getNftBoostFactor(enhancementNftId);
         if (boostFactorBp == 0) revert NotEnhancementNFT(); // Treat 0 boost as invalid/non-boost NFT

         RewardInfo storage stakingInfo = rewardInfo[stake.tokenId];
         _updateStakingRewardAccumulator(stakingInfo); // Update rewards before changing params

         // Settle reward debt *before* applying boost
         uint256 pending = _calculatePendingStakingRewards(stakeId, stakingInfo.rewardPerTokenStored);
         stake.rewardDebt += pending;

         // Lock NFT: Transfer to this contract AND call setNFTLocked on RewardToken
         rewardToken.safeTransferFrom(user, address(this), enhancementNftId, 1, "");
         rewardToken.setNFTLocked(enhancementNftId, true);

         // Apply boost
         stake.enhancementNftId = enhancementNftId;
         stake.enhancementBoostBasisPoints = boostFactorBp;

         emit EnhancementAttached(stakeId, enhancementNftId, boostFactorBp);
    }

    /** @inheritdoc IExchangeRewards*/
    function detachEnhancementNFT(uint256 stakeId) external override nonReentrant {
        // Note: Current design primarily detaches automatically during unstake.
        // Provide manual detach only if explicitly needed & carefully consider conditions (e.g., after lock?)
         revert("Manual detach not implemented; occurs during unstake."); // Placeholder
    }

    /** @dev Internal: Handles NFT detachment logic during unstake or manual detach */
    function _detachNFTInternal(StakeInfo storage stake) internal returns (uint256 nftId) {
        nftId = stake.enhancementNftId;
        if (nftId == 0) return 0; // Nothing attached

        stake.enhancementNftId = 0;
        stake.enhancementBoostBasisPoints = 0;

        // Unlock NFT status in RewardToken contract
        rewardToken.setNFTLocked(nftId, false);
        // Note: Actual transfer back to user happens in the calling function (e.g., unstake)

        emit EnhancementDetached(stake.owner, nftId); // Event might need stakeId too? Let's use owner.
        return nftId;
    }

    /** @dev Internal: Gets boost factor based on override or range */
    function _getNftBoostFactor(uint256 nftId) internal view returns (uint16) {
        // Implementation as refined previously
        // require(rewardToken.isEnhancementNFT(nftId)); // Assumed check in caller

        uint16 overrideBoost = nftBoostOverrides[nftId];
        if (overrideBoost > 0) {
            return overrideBoost;
        }

        uint160 NFT_ID_THRESHOLD = type(uint160).max;
        if (nftId == NFT_ID_THRESHOLD) return 500; // 5%
        if (nftId > NFT_ID_THRESHOLD && nftId <= NFT_ID_THRESHOLD + 100) return 1000; // 10%
        if (nftId > NFT_ID_THRESHOLD + 100 && nftId <= NFT_ID_THRESHOLD + 500) return 1500; // 15%
        // Add more ranges if needed

        return 0; // Default no boost
    }


    // --- Discount Logic ---

    /** @inheritdoc IExchangeRewards*/
    function claimDiscountVoucher(uint256 rewardTokenId, uint256 amountToBurn) external override nonReentrant {
        address user = msg.sender;
        if (rewardToken.isEnhancementNFT(rewardTokenId)) revert CannotClaimForNFT();
        if (amountToBurn == 0) revert AmountMustBePositive();
        if (rewardToken.balanceOf(user, rewardTokenId) < amountToBurn) revert InsufficientBalance();

        // Define conversion rate: Burned Tokens -> Discount Value (in corresponding payment token)
        // Example: 10 reward tokens = 1 unit of discount. Need admin function to set this per token?
        // For simplicity: Fixed rate for all tokens initially.
        uint256 discountRatePerPaymentTokenUnit = 10; // 10 reward tokens per 1 base unit of payment token discount
        if (discountRatePerPaymentTokenUnit == 0) revert("Discount rate not set"); // Prevent division by zero

        uint256 discountValue = amountToBurn / discountRatePerPaymentTokenUnit;
        if (discountValue == 0) revert BurnAmountTooSmall();

        // Burn the reward tokens via RewardToken contract
        rewardToken.burnFrom(user, rewardTokenId, amountToBurn); // Call controlled burn

        address paymentToken = address(uint160(rewardTokenId));
        userDiscountCredit[user][paymentToken] += discountValue;

        emit DiscountVoucherClaimed(user, rewardTokenId, amountToBurn, discountValue, paymentToken);
    }

    /** @inheritdoc IExchangeRewards*/
    function useDiscount(address user, address paymentToken) external override nonReentrant returns (uint256 discountAmount) {
        // Only callable by TicketExchange
        if (msg.sender != ticketExchange) revert NotTicketExchange();

        discountAmount = userDiscountCredit[user][paymentToken];
        if (discountAmount > 0) {
            userDiscountCredit[user][paymentToken] = 0; // Consume entire credit
            emit DiscountUsed(user, paymentToken, discountAmount);
        }
        // Returns 0 if no credit available
    }

    // --- Helper & View Functions ---

    /** @dev Updates reward accumulator based on elapsed time if using a rate model. No-op if distributing only on fee deposit. */
    function _updateStakingRewardAccumulator(RewardInfo storage stakingInfo) internal {
        // If rewards distribute *only* when recordFee is called, this might only need to update lastUpdateTime.
        // If rewards accrue per second based on a rate, calculate here.
        // Current design distributes fully on recordFee, so this is mainly a placeholder / timestamp update spot.
        stakingInfo.lastUpdateTime = block.timestamp;
    }

    /** @dev Calculates pending rewards for a single stake without updating state */
    function _calculatePendingStakingRewards(uint256 stakeId, uint256 currentGlobalRewardPerToken) internal view returns (uint256) {
         StakeInfo storage stake = stakes[stakeId];
         if (!stake.active) return 0; // No rewards for inactive stake

         // Total accumulated reward per token globally
         uint256 rewardPerToken = currentGlobalRewardPerToken;

         // Effective stake multiplier = Base multiplier + NFT boost
         uint256 effectiveMultiplier = uint256(stake.rewardMultiplierBasisPoints) + uint256(stake.enhancementBoostBasisPoints); // Sum basis points

         // Calculate total earned: Amount * RewardPerToken (scaled) * Multiplier (scaled)
         // Need careful scaling: (Amount * (RewardPerToken - DebtPerToken)) * Multiplier / ScalingFactors
         uint256 totalEarnedScaled = stake.amount * (rewardPerToken - (stake.rewardDebt * 1e18 / stake.amount)); // approx
         // More accurate: reward = amount * (rewardPerToken_scaled - rewardDebt_scaled) / 1e18
         uint256 earned = stake.amount * (rewardPerToken - stake.rewardDebt) / 1e18;

         // Apply multiplier
         earned = earned * effectiveMultiplier / 10000;

         return earned;
    }

    /** @inheritdoc IExchangeRewards*/
    function pendingStakingRewards(uint256 stakeId) external view override returns (uint256) {
        // This provides a snapshot based on the last time the accumulator was updated.
        StakeInfo storage stake = stakes[stakeId];
        if (!stake.active) return 0;
        RewardInfo storage stakingInfo = rewardInfo[stake.tokenId];
        // Use the stored value - doesn't simulate updates since last transaction.
        return _calculatePendingStakingRewards(stakeId, stakingInfo.rewardPerTokenStored);
    }

    /** @inheritdoc IExchangeRewards*/
    function getStakeInfo(uint256 stakeId) external view override returns (uint256 tokenId, address owner, uint256 amount, uint256 startTime, uint256 endTime, uint16 rewardMultiplierBasisPoints, uint256 rewardDebt, uint256 enhancementNftId, uint16 enhancementBoostBasisPoints, bool active) {
         StakeInfo storage s = stakes[stakeId];
         // Note: rewardDebt is scaled by 1e18
         return (s.tokenId, s.owner, s.amount, s.startTime, s.endTime, s.rewardMultiplierBasisPoints, s.rewardDebt, s.enhancementNftId, s.enhancementBoostBasisPoints, s.active);
    }


    /** @inheritdoc IExchangeRewards*/
    function getUserStakeIds(address user) external view override returns (uint256[] memory) {
        return _userStakes[user].values();
    }

    /** @inheritdoc IExchangeRewards*/
     function getUserDiscountCredit(address user, address paymentToken) external view override returns (uint256) {
         return userDiscountCredit[user][paymentToken];
     }

    /** @inheritdoc IExchangeRewards*/
     function pendingHoldingRewards(address user, uint256 tokenId) public view override returns (uint256) {
         // Implementation as refined previously
         HoldingRewardInfo storage info = holdingRewardInfo[tokenId];
         uint256 globalRewardPerToken = info.rewardPerTokenStored; // Scaled by 1e18
         uint256 userDebtPerToken = userHoldingRewardDebt[user][tokenId]; // Scaled by 1e18

         if (globalRewardPerToken <= userDebtPerToken) return 0;

         uint256 userBalance = rewardToken.balanceOf(user, tokenId);
         if (userBalance == 0) return 0;

         // reward = Balance * (GlobalRewardLevel - UserClaimedLevel) / Precision
         uint256 reward = userBalance * (globalRewardPerToken - userDebtPerToken) / 1e18;
         return reward;
     }

     /** @inheritdoc IExchangeRewards*/
     function getLockupOptions() external view override returns (uint256[] memory durations, uint16[] memory multipliers) {
         uint256 length = lockupOptions.length;
         durations = new uint256[](length);
         multipliers = new uint16[](length);
         for(uint i = 0; i < length; ++i) {
             durations[i] = lockupOptions[i].duration;
             multipliers[i] = lockupOptions[i].rewardMultiplierBasisPoints;
         }
         return (durations, multipliers);
     }

    // --- IERC1155Receiver ---
    /** @inheritdoc IERC1155Receiver*/
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external override returns (bytes4) {
        // Only accept transfers related to NFT attachments?
        // For now, accept generally but log event. Could restrict later.
        // require(tx.origin == owner(), "Debug: Direct transfers disallowed?"); // Example restriction
        return this.onERC1155Received.selector;
    }

    /** @inheritdoc IERC1155Receiver*/
    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

       
 
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) { // Override only ERC165 now
        return interfaceId == type(IExchangeRewards).interfaceId ||
               interfaceId == type(IERC1155Receiver).interfaceId ||
               super.supportsInterface(interfaceId); // Call ERC165's base implementation
    }
}