// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IExchangeRewards Interface
 * @dev Interface for the central rewards and staking contract.
 */
interface IExchangeRewards {
    // --- Events ---
    event FeeRecorded(address indexed paymentToken, uint256 amountAllocatedToStaking);
    event PassiveRewardsDistributed(uint256 indexed tokenId, uint256 totalAmountDistributed, uint256 rewardAddedPerToken);
    event Staked(address indexed user, uint256 indexed stakeId, uint256 indexed tokenId, uint256 amount, uint256 endTime, uint256 rewardMultiplier);
    event Unstaked(address indexed user, uint256 indexed stakeId, uint256 tokenId, uint256 amount);
    event StakingRewardsClaimed(address indexed user, uint256 indexed tokenId, uint256 amount);
    event HoldingRewardsClaimed(address indexed user, uint256 indexed tokenId, uint256 amount);
    event EnhancementAttached(uint256 indexed stakeId, uint256 enhancementNftId, uint16 boostFactor);
    event EnhancementDetached(uint256 indexed stakeId, uint256 enhancementNftId);
    event DiscountVoucherClaimed(address indexed user, uint256 indexed rewardTokenId, uint256 amountBurned, uint256 discountCreditValue, address paymentToken);
    event DiscountUsed(address indexed user, address indexed paymentToken, uint256 discountAmount);
    event NftBoostOverrideSet(uint256 indexed nftId, uint16 boostBasisPoints);

    // --- Configuration ---
    function setTicketExchange(address _ticketExchange) external;
    function addLockupOption(uint256 duration, uint16 multiplierBp) external;
    function setBaseRewardRate(uint256 numerator, uint256 denominator) external;
    function setStakingRatioBoostFactor(uint16 boostFactorBp) external;
    function setPassiveRewardFeeShare(uint16 basisPoints) external;
    function setNftBoostOverride(uint256 nftId, uint16 boostBasisPoints) external;

    // --- Core Interactions ---
    function recordFee(address paymentToken, uint256 amount) external payable; // payable if native coin support needed
    function getRewardMintRate(address paymentToken) external view returns (uint256 rate);
    function useDiscount(address user, address paymentToken) external returns (uint256 discountAmount);
    function distributePassiveRewards(uint256[] calldata tokenIds) external; // Admin action
 
    // --- User Staking & Rewards ---
    function stake(uint256 tokenId, uint256 amount, uint8 durationOption) external;
    function unstake(uint256 stakeId) external;
    function claimStakingRewards(uint256[] calldata stakeIds) external; // Consider gas if many different tokenIds claimed
    function claimHoldingReward(uint256 tokenId) external;
    function attachEnhancementNFT(uint256 stakeId, uint256 enhancementNftId) external;
    function detachEnhancementNFT(uint256 stakeId) external; // Note: Current logic detaches on unstake
    function claimDiscountVoucher(uint256 rewardTokenId, uint256 amountToBurn) external;

    // --- View Functions ---
    function pendingStakingRewards(uint256 stakeId) external view returns (uint256);
    function getStakeInfo(uint256 stakeId) external view returns (uint256 tokenId, address owner, uint256 amount, uint256 startTime, uint256 endTime, uint16 rewardMultiplierBasisPoints, uint256 rewardDebt, uint256 enhancementNftId, uint16 enhancementBoostBasisPoints, bool active);
    function getUserStakeIds(address user) external view returns (uint256[] memory); // Returns only active stake IDs
    function getUserDiscountCredit(address user, address paymentToken) external view returns (uint256);
    function pendingHoldingRewards(address user, uint256 tokenId) external view returns (uint256);
    function getLockupOptions() external view returns (uint256[] memory durations, uint16[] memory multipliers);
}