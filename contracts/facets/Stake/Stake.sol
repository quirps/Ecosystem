pragma solidity ^0.8.9;

/**
    Enable permitted contracts to allow staking/unstaking, done implicitly through erc20
    transfers function
    Have several tiers 
    Create a seperate stake address 
 */
 
import {iERC1155Transfer} from "../Tokens/ERC1155/ERC1155Transfer.sol";  
import {LibERC20} from "../Tokens/ERC20/libraries/LibERC20.sol";  
import {iOwnership} from "../Ownership/_Ownership.sol";
import {iMembers} from "../MemberRankings/_Members.sol";

contract Stake is iERC1155Transfer, iOwnership, iMembers{  
    enum StakeTier {Continious, SevenDay, FourteenDay, TwentyEightDay} 
    uint8 constant NUM_STAKE_TIERS = 4;
    struct RewardRate{
        uint16 initialRate;
        uint16 rateIncrease;
        uint16 rateIncreaseStopDuration;
    }

    address constant STAKE_FUNDING_ADDRESS = 0x2D08BDf3c61834F76Decaf6E85ffAecFeF02E605; //address(this), massDX, and whoever else the owner decides has permissions
    address constant STAKE_DEPOSIT_ADDRESS = 0x2D08BDf3c61834F76Decaf6E85ffAecFeF02E605; //address(this), massDX, and whoever else the owner decides has permissions

    uint24 constant GAS_STAKE_FEE_SCALE = 1000000;
    uint24 constant GAS_STAKE_FEE = 16000000;

    struct StakePosition{
        address holder; // if non-zero, implies an app is implicitly staking for a user and holds their currency in turn
        StakeTier tier;
        uint32 startTime;
        bool isVirtual;
        uint256 amount;
    }
    //address, then stakeId
    mapping( address => mapping(uint256 => StakePosition) ) stakePosition;
    mapping( StakeTier => RewardRate) rewardRate;
    mapping( address => bool) approvedContracts;
    event StakeRewardAccountFunded(address funder, uint256 amount);
    event RewardsRetrieved(address user, uint256 amount, uint256 reward, uint256 stakeId);
    event RewardRatesChanged(RewardRate[] _rewardRates);
    
    function stakeContract(address staker, uint256 amount, StakeTier tier, uint256 stakeId) public{
        //require approved contract
        //transfer funds from staker to stake deposit
        _safeTransferFrom(staker, STAKE_DEPOSIT_ADDRESS, LibERC20.PRIMARY_CURRENCY_ID, amount, "");

        //stake
        StakePosition storage _stakePosition = stakePosition[ msgSender() ][ stakeId ];
        require(_stakePosition.startTime == 0 ,"StakeId already exists, please create a unique stakeId");

        stakePosition[ staker ][ stakeId ] = StakePosition( msgSender(), tier, uint32(block.timestamp), false, amount );
    }

    function stake(uint256 amount, StakeTier tier, uint256 stakeId) public{
        stakeContract(msgSender(), amount, tier, stakeId); 
    }

    /**
     * Swap orders having this ecosystem token as their output can stake the expected 
     * outputted tokens and retrieve rewards IF their order is fulfilled. 
     */
    function stakeVirtual(address staker, uint256 amount, StakeTier tier, uint256 stakeId) external {
        //stake
        StakePosition storage _stakePosition = stakePosition[ msgSender() ][ stakeId ];
        require(_stakePosition.startTime == 0 ,"StakeId already exists, please create a unique stakeId");

        stakePosition[ staker ][ stakeId ] = StakePosition( msgSender(), tier, uint32(block.timestamp), true, amount );

    }

    //batch staking is immune to same block/transaction limitation for a given user
    function batchStake( address[] memory user, uint256[] memory amount, StakeTier[] memory tier, uint256[] memory stakeIds) external{
        for( uint256 stakeIndex; stakeIndex < user.length - 1; stakeIndex++){
            stake( amount[stakeIndex], tier[stakeIndex], stakeIds[stakeIndex]);
        }
    }

    function setRewardRates(StakeTier[] memory _stakeTier, RewardRate[] memory _rewardRate) external {
        isEcosystemOwnerVerification();
        require(_stakeTier.length == _rewardRate.length, "Input parameters must have same length");
        for(uint8 rewardRateIndex; rewardRateIndex < _rewardRate.length - 1; rewardRateIndex ++){
            require( type(uint16).max >= _rewardRate[ rewardRateIndex ].rateIncreaseStopDuration , "RateIncreaseStopDuration must be a uint16 type.");
            rewardRate[ _stakeTier[ rewardRateIndex ] ] = _rewardRate[ rewardRateIndex ];
        }
        emit RewardRatesChanged(_rewardRate);
    }

    function unstakeContract( address staker, uint256 amount, uint256 stakeId) public returns (uint256) {
        StakePosition storage _stakePosition = stakePosition[ staker ][ stakeId ];
        address _holder = _stakePosition.holder;

        
        uint32 elapsedTime = uint32( block.timestamp ) - _stakePosition.startTime;
        require(elapsedTime >= stakeTierDurations(_stakePosition.tier),"Can't unstake rewards until the mininmum duration has passed.");
        
        //update stake amount
        _stakePosition.amount -= amount;
      

        //calculate rewards
        uint256 reward = calculateReward(amount, _stakePosition.tier, _stakePosition.startTime);
        uint256 totalTransferAmount = reward + amount;
        //send reward to user from STAKE_ACCOUNT
        _safeTransferFrom( STAKE_FUNDING_ADDRESS, staker, LibERC20.PRIMARY_CURRENCY_ID, reward, ""); 
        //send amount to holding contract
        _safeTransferFrom( STAKE_DEPOSIT_ADDRESS, _holder, LibERC20.PRIMARY_CURRENCY_ID, amount, ""); 

        emit RewardsRetrieved( staker, amount, reward, stakeId);
        
        return totalTransferAmount;
    }
    
    function unstake( uint256 amount, uint256 stakeId) external {
        unstakeContract( msgSender(), amount, stakeId);
    }

    /**
     * @notice Trusted contracts can stake users placing swap orders into this
     * ecosystem's token.
     * @param staker reward transfer address
     * @param amount amount to be virtually unstaked
     * @param stakeId unique staking id
     */
    function unstakeVirtual( address staker, uint256 amount, uint256 stakeId) external {
        //require trusted contract

        StakePosition storage _stakePosition = stakePosition[ staker ][ stakeId ];

        _stakePosition.amount -= amount; 
        
        uint32 elapsedTime = uint32( block.timestamp ) - _stakePosition.startTime;
        require(elapsedTime >= stakeTierDurations(_stakePosition.tier),"Can't unstake rewards until the mininmum duration has passed.");
      
        //calculate rewards
        uint256 reward = calculateReward(amount, _stakePosition.tier, _stakePosition.startTime);

        //send reward to user from STAKE_ACCOUNT
        _safeTransferFrom( STAKE_FUNDING_ADDRESS, staker, LibERC20.PRIMARY_CURRENCY_ID, reward, ""); 

        emit RewardsRetrieved( staker, amount, reward, stakeId);
    }
    /**
        Retrieves current reward amount from a given stake position. 
        To retrieve the reward, you must unstake after the minimum stake duration. 
     */
    function viewReward(uint256 stakeId) external view returns (uint256 reward_){
        StakePosition storage _stakePosition = stakePosition[ msgSender() ][ stakeId ];
        uint256 _amount = _stakePosition.amount;
        StakeTier _stakeTier = _stakePosition.tier;
        uint32 _startTime = _stakePosition.startTime;
        reward_ = calculateReward(_amount, _stakeTier, _startTime);
    }

    /**
        Retrieves the remaining time left until the minimum stake duration is completed, zero if already completed. 
     */
    function viewMinimumStakeDurationLeft(uint256 stakeId) external view returns (uint32 timeLeft_) {
        StakePosition storage _stakePosition = stakePosition[ msgSender() ][ stakeId ];
        uint32 _startTime = _stakePosition.startTime;
        uint32 _minimumDuration = stakeTierDurations( _stakePosition.tier );
        if(block.timestamp > _startTime + _minimumDuration ){
            timeLeft_ = uint32(block.timestamp) - _startTime;
        }
        else{
            timeLeft_ = 0;            
        }
    }


    /**
        Rewards are calculated via a two part function, one function having the domain of 0 to rateIncreaseStopDuration,
        the other from rateIncreaseStopDuration to infinity. 

        The first part is simply a linear increase in reward rate as a function of time with some intial reward rate, r(t). 
        The second is a flat reward rate which has the value r( rateIncreaseStopDuration );
     */
    function calculateReward(uint256 _amount, StakeTier _tier, uint32 _startTime ) internal view  returns (uint256 reward_) { 
        uint32 elapsedTime = uint32( block.timestamp ) - _startTime;
        if(_tier == StakeTier.Continious){
            reward_ = tierSpecificReward(_amount, elapsedTime, rewardRate[StakeTier.Continious]);      
        }
        else if(_tier == StakeTier.SevenDay){
            reward_ = tierSpecificReward(_amount, elapsedTime, rewardRate[StakeTier.SevenDay]);      
        } 
        else if(_tier == StakeTier.FourteenDay){
            reward_ = tierSpecificReward(_amount, elapsedTime, rewardRate[StakeTier.FourteenDay]);      
        }
        else if(_tier == StakeTier.TwentyEightDay){
            reward_ = tierSpecificReward(_amount, elapsedTime, rewardRate[StakeTier.TwentyEightDay]);      
        }
    }

    function tierSpecificReward(uint256 _amount, uint32 elapsedTime, RewardRate memory _rewardRate) private pure  returns (uint256 reward_){
        if( elapsedTime >= _rewardRate.rateIncreaseStopDuration ){
            reward_ += firstIntervalRewards(_amount, _rewardRate, _rewardRate.rateIncreaseStopDuration);
            uint32 remainingTime = elapsedTime - _rewardRate.rateIncreaseStopDuration;
            reward_ += remainingTime * rateFunction(_rewardRate.initialRate, _rewardRate.rateIncrease, _rewardRate.rateIncreaseStopDuration);
        }
        else{
            reward_ += firstIntervalRewards(_amount, _rewardRate, elapsedTime);
        }
    }
    function rateFunction(uint16 initialRate, uint16 rateIncrease, uint16 time) private pure returns (uint16 rate_){
        rate_ = initialRate + rateIncrease * time; 
    }

    //evaluates the integral of the first part of the reward function at zero and _maxTime
    function firstIntervalRewards(uint256 _amount, RewardRate memory _rewardRate, uint32 _maxTime) private pure returns (uint256 reward_){
        reward_ = ( _rewardRate.rateIncrease * _maxTime ** 2 ) / 2 + _rewardRate.initialRate * _maxTime;
    }

    function stakeTierDurations(StakeTier _stakeTier ) private pure returns (uint32 duration_ ){
        if(_stakeTier == StakeTier.SevenDay){
            duration_ = 604800; // 7 days 
        }
        else if(_stakeTier == StakeTier.FourteenDay){
            duration_ =  1209600;
        }
        else if(_stakeTier == StakeTier.TwentyEightDay){
            duration_ =  2419200;
        }
        else if (_stakeTier == StakeTier.Continious){
            duration_ = 0;
        }
    }

    //********************************************************************** */


    function fundStakeAccount(uint256 amount) external {
        _safeTransferFrom(msgSender(), STAKE_FUNDING_ADDRESS, LibERC20.PRIMARY_CURRENCY_ID, amount, "" );
        emit StakeRewardAccountFunded(msgSender(),amount);
    }

    /**
     * Multiply the target eth by feeScale_. 
     * 
     */
    function getGasStakeFee() external view returns( uint24 feeScale_, uint24 fee_){
        fee_ = GAS_STAKE_FEE;
        feeScale_ = GAS_STAKE_FEE_SCALE;
    }
}
/**
 * 
 * Change two things.
 * 1. Implicit staking via swaps is done virtually, meaning a swap order who's output swap is intended for a target ecosystem
 *    will be staked there IF partial or more of the swap is fulfilled. 
 * 2. Volume rewarded eth swapping to ecosystem token. Ecosystem can set a fee. 
 *
 */