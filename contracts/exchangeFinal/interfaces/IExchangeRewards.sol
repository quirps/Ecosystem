// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IExchangeRewards Interface
 * @dev Interface for the central rewards and staking contract.
 */
interface IExchangeRewards {

    // --- Enums and Structs ---
    enum BonusType { NONE, PURCHASE_REWARD_MULTIPLIER, PASSIVE_STAKING_RATE_BOOST, STAKING_FEE_SHARE_BOOST }

    struct NftProperties {
        BonusType bonusType;
        address targetEcosystem; // address(0) for global
        uint256 bonusValue; // BP for rates, Multiplier x10000 for purchase (e.g., 20000 = 2x)
        bool isActive;
    }
 
       struct StakeInfo { 
        uint256 tokenId;
        address owner;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        uint8 durationOption;
        uint256 feeShareRewardDebt;       // Debt for Stream 2 (Fee Share)
        uint256 lastPassiveRewardClaimTime; // Time for Stream 1 (Passive Accrual)
        uint256 attachedNftId;
        bool active;
    }

    // --- Events ---
    event HoldingRewardsClaimed(address indexed user, uint256 indexed tokenId,uint256 indexed pending);
    event FeeRecorded(address indexed paymentToken, uint256 amountAllocatedToStaking);
    event PassiveRewardsDistributed(uint256 indexed tokenId, uint256 totalAmountDistributed, uint256 rewardAddedPerToken); // For holding rewards
    event Staked(address indexed user, uint256 indexed stakeId, uint256 indexed tokenId, uint256 amount, uint8 durationOption, uint256 endTime);
    event Unstaked(address indexed user, uint256 indexed stakeId, uint256 tokenId, uint256 amount);
    event StakingFeeShareRewardsClaimed(address indexed user, uint256 indexed tokenId, uint256 amount); // From fee share accumulator
    event PassiveStakingRewardsClaimed(address indexed user, uint256 indexed stakeId, uint256 amount); // From passive time-based accrual
    event StakingNftAttached(uint256 indexed stakeId, uint256 indexed nftId);
    event StakingNftDetached(uint256 indexed stakeId, uint256 indexed nftId);
    event DiscountVoucherClaimed(address indexed user, uint256 indexed rewardTokenId, uint256 amountBurned, uint256 discountCreditValue, address paymentToken);
    event DiscountUsed(address indexed user, address indexed paymentToken, uint256 discountAmount);
    event NftPropertiesSet(uint256 indexed nftId, BonusType bonusType, address targetEcosystem, uint256 bonusValue, bool isActive);


    // --- Configuration Functions ---
    function setTicketExchange(address _ticketExchange) external;
    function addLockupOption(uint256 duration, uint16 passiveRateMultiplierBp) external; // Multiplier for passive accrual rate
    function setBaseRewardRate(uint256 numerator, uint256 denominator) external; // For purchase reward minting
    function setStakingRatioBoostFactor(uint16 boostFactorBp) external; // For purchase reward minting
    function setPassiveRewardFeeShare(uint16 basisPoints) external; // For passive *holding* rewards
    function setBasePassiveStakingRate(uint256 ratePerSecScaled) external; // Base rate for Stream 1 (passive staking) accrual
    // Admin function to mint NFTs and set properties
    function ownerMintAndSetNft(address to, uint256 nftId, uint256 amount, bytes calldata data, BonusType bonusType, address targetEcosystem, uint256 bonusValue) external;
    function setNftProperties(uint256 nftId, BonusType bonusType, address targetEcosystem, uint256 bonusValue, bool isActive) external;


    // --- Core Interactions (Called by TicketExchange) ---
    function recordFee(address paymentToken, uint256 platformFeeAmount) external payable;
    function getRewardMintRate(address paymentToken) external view returns (uint256 rate); // Rate per unit (wei), scaled 1e18
    function useDiscount(address user, address paymentToken) external returns (uint256 discountAmount);
    function executeMint(address buyer, uint256 rewardTokenId, uint256 rewardAmount) external;
    function verifyAndUsePurchaseBooster(address buyer, uint256 boosterNftId, address purchaseEcosystemAddress) external returns (bool boosted);


    // --- Admin Actions ---
    function distributePassiveHoldingRewards(uint256[] calldata tokenIds) external;


    // --- User Staking & Rewards ---
    function stake(uint256 tokenId, uint256 amount, uint8 durationOption) external;
    function unstake(uint256 stakeId) external;
    function attachStakingNft(uint256 stakeId, uint256 nftId) external;
    // detach integrated into unstake
    function claimFeeShareRewards(uint256[] calldata stakeIds) external; // Claims Stream 2 (Fee Share)
    function claimPassiveStakingRewards(uint256[] calldata stakeIds) external; // Claims Stream 1 (Passive Accrual)
    function claimHoldingReward(uint256 tokenId) external; // Claims passive holding rewards (unrelated to staking)
    function claimDiscountVoucher(uint256 rewardTokenId, uint256 amountToBurn) external;

    // --- View Functions ---
    function getStakeInfo(uint256 stakeId) external view returns (StakeInfo memory); // Return memory struct
    function getUserStakeIds(address user) external view returns (uint256[] memory);
    function getNftProperties(uint256 nftId) external view returns (NftProperties memory);
    function pendingFeeShareRewards(uint256 stakeId) external view returns (uint256); // Stream 2 rewards
    function pendingPassiveStakingRewards(uint256 stakeId) external view returns (uint256); // Stream 1 rewards
    function getUserDiscountCredit(address user, address paymentToken) external view returns (uint256);
    function pendingHoldingRewards(address user, uint256 tokenId) external view returns (uint256); // Passive holding rewards
    function getLockupOptions() external view returns (uint256[] memory durations, uint16[] memory passiveRateMultipliers);

}