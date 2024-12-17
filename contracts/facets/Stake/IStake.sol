pragma solidity ^0.8.9;

interface IStake{

    enum StakeTier {Continious, SevenDay, FourteenDay, TwentyEightDay} 
    struct RewardRate{
        uint16 initialRate;
        uint16 rateIncrease;
        uint16 rateIncreaseStopDuration;
    }

    struct StakePosition{
        address user;
        uint256 amount;
        StakeTier tier;
        uint32 startTime;
    }
    
    function fundStakeAccount(uint256 amount) external;
    function stake( uint256 amount, StakeTier tier, uint256 stakeId) external;
    function stakeContract( address user, uint256 amount, StakeTier tier, uint256 stakeId) external;
    function stakeVirtual(address staker, uint256 amount, StakeTier tier, uint256 stakeId) external;
    function batchStake( address[] memory user, uint256[] memory amount, StakeTier[] memory tier, uint256[] memory stakeIds) external;
    function setRewardRates(StakeTier[] memory _stakeTier, RewardRate[] memory _rewardRate) external;
    function unstake( uint256 amount, uint256 stakeId) external;
    function unstakeContract(address user, uint256 amount, uint256 stakeId) external returns(uint256);
    function unstakeVirtual(address staker, uint256 amount, uint256 stakeId) external;
    function getGasStakeFee() external returns ( uint24, uint24 );
    
}