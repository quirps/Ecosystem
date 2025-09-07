// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol"; // For supportsInterface
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol"; // If TokenSaleStaking is also an ERC1155Receiver

/**
 * @title ITokenSaleStaking Interface
 * @dev Interface for the TokenSaleStaking Contract.
 * Defines all external and public functions, events, errors, and structs.
 */
interface ITokenSaleStaking is IERC165, IERC1155Receiver { // Add IERC1155Receiver if it inherits it

    // --- Structs (copy from TokenSaleStaking.sol) ---
    struct Stake {
        uint256 stakeId;
        address owner;
        uint256 amount;
        uint256 startTime;
        bool active;
    }

    struct PoolRewardInfo {
        uint256 rewardPerTokenStored;
        uint256 totalStaked;
    }

    // --- Events (copy from TokenSaleStaking.sol) ---
    event Staked(address indexed user, uint256 indexed stakeId, uint256 amount, uint256 startTime);
    event Unstaked(address indexed user, uint256 indexed stakeId, uint256 amount);
    event RewardsClaimed(address indexed user, address indexed paymentToken, uint256 amount);
    event FeeRecorded(address indexed paymentToken, uint256 amount); // This is the event emitted by TokenSaleStaking's recordFee
    event ExchangeRewardsContractUpdated(address indexed newAddress);

    // --- Errors (copy from TokenSaleStaking.sol) ---
    error NotExchangeRewardsContract();
    error StakingPeriodOver();
    error InvalidToken();
    error AmountMustBePositive();
    error NotStakeOwner();
    error StakeNotActive();
    error StakeLocked();
    error NoRewardsToClaim();
    error ZeroAddress();


    // --- Public State Variables (copy public/external getters from TokenSaleStaking.sol) ---
    function rewardToken() external view returns (address);
    function exchangeRewardsContract() external view returns (address);
    function entryDeadline() external view returns (uint256);
    function lockupDuration() external view returns (uint256);
    function saleTokenId() external view returns (uint256);
    function stakes(uint256) external view returns (Stake memory);
    function nextStakeId() external view returns (uint256);
    function poolRewardInfo(address) external view returns (PoolRewardInfo memory);
    function userRewardDebt(uint256, address) external view returns (uint256);


    // --- External Functions (copy from TokenSaleStaking.sol) ---
    function setExchangeRewardsContract(address _newAddress) external;
    function stake(uint256 amount) external;
    function unstake(uint256 stakeId) external;
    function recordFee(address paymentToken, uint256 feeAmount) external; // Correct signature for TokenSaleStaking
    function claimAllRewards() external;
    function claimRewards(address paymentToken) external;
    function pendingRewards(address user, address paymentToken) external view returns (uint256 totalPending);
    function getUserStakeIds(address user) external view returns (uint256[] memory);

    // --- IERC1155Receiver Overrides (if TokenSaleStaking implements them) ---
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}