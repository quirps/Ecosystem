pragma solidity ^0.8.9;

import "./LibTimeManagement.sol";
import "./LibUnderflow.sol";

import { iOwnership } from "../facets/Ownership/_Ownership.sol";

import "./CleanupUser.sol";
import "./ERC1155Rewards.sol";
import { IERC20 } from "../facets/Tokens/ERC20/interfaces/IERC20.sol";
import { IERC1155 } from "../facets/Tokens/ERC1155/interfaces/IERC1155.sol";
import { IERC1155Transfer } from "../facets/Tokens/ERC1155/interfaces/IERC1155Transfer.sol";
import "hardhat/console.sol";

contract ExchangeRewardPool is  iOwnership, CleanupUser{
    using LibTimeManagement for uint32;
    using LibUnderflow for uint8;

    uint32 immutable GENESIS_TIMESTAMP;
    address immutable exchangeRewardERC1155; 

    event Staked (uint32 timeStart, LibTimeManagement.StakeDayInterval stakeInterval, uint256 stakeAmouunt, address staker);
    event StakerRewardsCollected(address staker, uint256 amount);
  
    enum StakeStatus { Staking, Collected }

    struct TimePool{
        uint32 startTimeSlot;
        address staker;
        LibTimeManagement.StakeDayInterval stakeInterval;
        uint256 amount;
        address tokenAddress; //used as the erc1155 id as well, uint256(tokenAddress)
        StakeStatus status;
    }
    //helps with precision for earningSumRatio
    uint64 constant PRECISION_RETAINER = uint64(10 ** 18);
    mapping (uint256 => TimePool) public timePoolStakes;
     
     /**
      * @dev 
      * @param exhangeTimePoolEarnings - amount of earnings allocated to the time pool for token at time slot
      * @param totalStakedSum - total amount of time pool tokens staked for token and time slot. The sum works
      * by maintaining a running total, and only adding and subtracting 
      * @param totalEarningsPerSum - exchangeTimePoolEarnings/totalStakedSum + previous
      */
     struct StakedSum{
        uint256 oneDay;
        uint256 threeDay;
        uint256 nineDay;
        uint256 eighteenDay;
        uint256 thirtySixDay;
     }
    struct RewardsManage{
        mapping(LibTimeManagement.StakeDayInterval => uint256) stakeSum;
        uint256 totalSlotSum;
        uint256 totalEarningsPerSum;
    }
    //total staked amount of all users for token at address at timeslot
    mapping (address => mapping (uint32 => RewardsManage)) public timeSlotRewards;
    uint256 public  rollingEarningsSumRatio;
    mapping(address => mapping(uint32 => bytes32) ) public  timeSlotActivationBitMap;


    constructor( address _exchangeRewardERC1155){
        GENESIS_TIMESTAMP = uint32(block.timestamp);
        exchangeRewardERC1155 = _exchangeRewardERC1155;  
    }

    /**
     * 
     * @param _tokenAddress 2
     * @param _timeSlot 2
     * @param _stakeDayInterval 2
     * @dev A function purely for testing purposes, as there's wasn't a straightforward solution to accessing
     * a mapping within a struct.
     */
    function stakeSumGetter(address _tokenAddress, uint32 _timeSlot, LibTimeManagement.StakeDayInterval _stakeDayInterval) external view returns (uint256){
        return timeSlotRewards[_tokenAddress][_timeSlot].stakeSum[_stakeDayInterval];
    }
    function batchStakeTimePool(uint256[] calldata _stakeIds, LibTimeManagement.StakeDayInterval[] memory _stakeIntervals, uint256[] calldata _stakeAmounts, address[] calldata _tokenAddresses) external {
        //require lengths matchg
        for( uint _stakeIndex; _stakeIndex < _stakeIds.length; _stakeIndex++){
            stakeTimePool(_stakeIds[_stakeIndex],_stakeIntervals[_stakeIndex],_stakeAmounts[_stakeIndex],_tokenAddresses[_stakeIndex]);
        }
    }
    /**
     */
    function stakeTimePool(uint256 _stakeId, LibTimeManagement.StakeDayInterval _stakeInterval,  uint256 _stakeAmount, address _tokenAddress) public {
        require( timePoolStakes[ _stakeId ].startTimeSlot == 0, "A Time Pool stake already exists with this id");
        //assert initial and final time slots are a multiple of TIME_INTERVAL
        
        require(_tokenAddress != address(this), "Reward tokens aren't stakeable"); //likely dont need this due to this doesnt employ erc20
        uint32 _stakeIntervalSeconds = LibTimeManagement.getDayIntervalSeconds(_stakeInterval);
        uint32 _timeStart = uint32(block.timestamp).getNextTimeSlot(_stakeIntervalSeconds);
        //calculate stake amount uniformally distributed over interval
        uint256 _uniformStake = _stakeAmount / LibTimeManagement.convertDenominationalUnits(_stakeInterval);
        //add stake 
        timeSlotRewards[ _tokenAddress ][ _timeStart ].stakeSum[_stakeInterval] +=  _uniformStake;
        //burn amount
        IERC1155(exchangeRewardERC1155).burn(msgSender(), uint256(uint160(_tokenAddress)), _stakeAmount);
        
        timePoolStakes[_stakeId] = TimePool( _timeStart, msgSender(), _stakeInterval, _stakeAmount, _tokenAddress, StakeStatus.Staking);

        emit Staked(_timeStart, _stakeInterval, _stakeAmount, msgSender());

    }
   

  /**
   * Sends user their earned rewards.
   * @param _stakeId stake identifier 
   */
    function collectReward(uint256 _stakeId) external{
        uint256 _stakerEarnings;
        TimePool storage _stake = timePoolStakes[_stakeId];
        LibTimeManagement.StakeDayInterval _stakeInterval = _stake.stakeInterval;
        address _tokenAddress = _stake.tokenAddress;
        uint32 _stakeStartSlot = _stake.startTimeSlot;
        uint256 _stakeAmount = _stake.amount;
        address _stakerAddress = _stake.staker;
        
        uint32 _stakeEndSlot = _stakeStartSlot + LibTimeManagement.getDayIntervalSeconds(_stakeInterval);

        require(_stake.status == StakeStatus.Staking, "Musn't have collected rewards yet");
        require(msgSender() == _stake.staker, "Must be the original staker");
        
        //add a day due to endSlot being the last day of the interval, yet the slot after would be the when the
        //interval actually ends
        require(_stakeEndSlot  + LibTimeManagement.getDayIntervalSeconds( LibTimeManagement.StakeDayInterval.One ) < uint32(block.timestamp),"Stake period is still ongoing");

        RewardsManage storage _timeSlotRewards = timeSlotRewards[ _tokenAddress ][ _stakeStartSlot ]; 
        
        uint256 _reward = calculateReward( _tokenAddress, _stakeInterval, _stakeStartSlot, _stakeAmount);

        _stake.status = StakeStatus.Collected; 
        //transfer rewards
        IERC20(_tokenAddress).transferFrom( address(this), _stakerAddress, _reward); 
        
        //transfer reward token? should be burned during stake so likely remove this transfer
        IERC1155Transfer(exchangeRewardERC1155).safeTransferFrom(address(this), msgSender(), uint256(uint160(_tokenAddress)), _stakerEarnings, "");
        
        emit StakerRewardsCollected(msgSender(), _stakerEarnings);
    }

    function collectRewardCleanupUser(address[] memory _tokenAddresses, uint32[] memory _startTimeSlots ) external{
        require(msgSender() == cleanupAddress, "Must use the cleanupAddress to access these funds.");
        require(_tokenAddresses.length == _startTimeSlots.length,"Input parameter argument lengths must match.");
        for(uint256 claimIndex; claimIndex < _tokenAddresses.length; claimIndex++){
            collectRewardCleanupUser(_tokenAddresses[claimIndex],_startTimeSlots[claimIndex]);
        }

    }
    //_startTimeSlot MUST have reward
    function collectRewardCleanupUser(address _tokenAddress, uint32 _startTimeSlot) public {
        // TODO
    }
    

    function calculateReward(address _tokenAddress, LibTimeManagement.StakeDayInterval _stakeInterval, uint32 _stakeStartTimeSlot, uint256 _stakeAmount) public view  returns (uint256 reward_){
        //retrieve starting timeslots of bitmaps that instersect stake interval time slots (max stake interval is smaller than 256 days, but can exist at a boundary)
        (bool _zeroReward, uint32 firstActivatedTimeSlot, uint32 lastActivatedTimeSlot) =  getRewardTimeSlots(_tokenAddress, _stakeInterval, _stakeStartTimeSlot);
        console.log("bool value is %s",_zeroReward); 
        if(  _zeroReward){
            return 0;
        }
        
        (uint256 _beginningRewards, uint256 _finalRewards) = getEarningSumRatios(_tokenAddress, firstActivatedTimeSlot, lastActivatedTimeSlot);
        console.log("final rewards arae %s",_finalRewards);  

        reward_ = ( (_finalRewards - _beginningRewards) * _stakeAmount ) / PRECISION_RETAINER;
        
    }
    function getEarningSumRatios(address _tokenAddress,  uint32 _firstActivatedTimeSlot, uint32 _lastActivatedTimeSlot) internal view returns( uint256 beginningReward_,uint256 finalReward_){
        beginningReward_ = timeSlotRewards[_tokenAddress][_firstActivatedTimeSlot].totalEarningsPerSum;
        finalReward_ = timeSlotRewards[_tokenAddress][_lastActivatedTimeSlot].totalEarningsPerSum;

    }
    /**
     * @dev ( start -1 ) and end of interval time slots may not have transactions on them hence we need to check the 
     *      last activated timeslots to get reward information. 
     */
    function getRewardTimeSlots(address _tokenAddress, LibTimeManagement.StakeDayInterval _stakeInterval, uint32 _stakeStartTimeSlot) internal view returns (bool isZeroReward_, uint32 firstActivatedTimeSlot_, uint32 finalActivatedTimeSlot_){
        finalActivatedTimeSlot_ =  getFinalActivatedTimeSlot(_tokenAddress, _stakeInterval, _stakeStartTimeSlot );
        console.log("this is the final reward slot %s",finalActivatedTimeSlot_);
        if( finalActivatedTimeSlot_ == 0){
            return (true, uint32(0), uint32(0) );
        }
        //can have non-zero reward only in very small purchase, just calculate anyway
        firstActivatedTimeSlot_ = getStartActivatedTimeSlot(_tokenAddress, _stakeStartTimeSlot);
        console.log(firstActivatedTimeSlot_);

        return (false, firstActivatedTimeSlot_, finalActivatedTimeSlot_);
    }
    /**
     * @param _intervalSize This corresponds to the stake interval size with respect to the denominational interval size 
     */
    /**
     * @dev We must check for an activated slot starting from the final slot down to the starting slot. This involves potentially
     *      accesssing the previous activationBitMap. 
     */
    function getFinalActivatedTimeSlot(address _tokenAddress, LibTimeManagement.StakeDayInterval _stakeInterval, uint32 _stakeStartTimeSlot ) internal view returns (uint32 finalActivatedTimeSlot_){
        uint32 _finalSlot; 
        uint32 _bitMapStartSlot;
        uint8 _finalSlotPosition;
        bytes32 _activationBitMap; 
        uint8 _intervalDenominationalSize;
        console.log("start slot is %s",_stakeStartTimeSlot);
        //right now this will work but _intervalDenominationalSize needs to be shortened after recursion by amount of underflow
        //also names need to be changed to make sense after recursion


        _finalSlot = _stakeStartTimeSlot.getFinalTimeSlot(_stakeInterval);
        console.log("final slot is %s",_finalSlot);
        (_bitMapStartSlot, _finalSlotPosition) = _finalSlot.bitFlagRemainder(LibTimeManagement.StakeDayInterval.One);
        _activationBitMap = timeSlotActivationBitMap[_tokenAddress][_bitMapStartSlot];
        _intervalDenominationalSize =  LibTimeManagement.convertDenominationalUnits(_stakeInterval);
        console.log(_bitMapStartSlot);

        console.log('start position %s',_finalSlotPosition);
        (bool _isUnderflow, uint8 _amountUnderflow) = _finalSlotPosition.uint8Underflow( _intervalDenominationalSize);
        console.logBytes32(_activationBitMap); 
        //_intevalDenominationlUnits - _amountUnderflow must be >= 0
        uint8 _endOfBitMap = _isUnderflow ?  _intervalDenominationalSize - _amountUnderflow : _intervalDenominationalSize;
        for(uint8 shiftIndex; shiftIndex < _endOfBitMap; shiftIndex++  ){
            uint8 _newPosition = _finalSlotPosition - shiftIndex;
            if( _activationBitMap & bytes32 (2**(_newPosition)  )  != bytes32(0) ){
                console.log("final positiio %s", _newPosition);
                return  _bitMapStartSlot  + _newPosition * LibTimeManagement.denominationalSize() ;
            }
        }
        //no activated slots from start to finish slots of stake period
        if( _finalSlotPosition - _endOfBitMap + 1 == _intervalDenominationalSize){
            return 0;
        }

        require(_isUnderflow,"Must be underflowed to reach this point - Critical Error");

        //assert underflow
        //If we're here it means one more we underflowed and must check bitmap before the previous
        uint8 _previousFinalPosition = type(uint8).max;
        //ignore calculating second argument when we already know we're starting from the max bit position 
        //just need to get a timeslot in that bitmap
        (bytes32 _isPreviousTimeSlotActivated,) =  getRewardAcitvationBitMap( _tokenAddress,  _stakeStartTimeSlot.shiftDownBitMap());
        for(uint8 shiftIndex; shiftIndex <  _amountUnderflow; shiftIndex++  ){
            uint8 _newPosition =_previousFinalPosition - shiftIndex;
            if(_isPreviousTimeSlotActivated & bytes32( 2 ** (_newPosition)  )  != bytes32(0) ){
                return _bitMapStartSlot.shiftDownBitMap()  + _newPosition * LibTimeManagement.denominationalSize();
            }
        }
        //we passed the starting stake slot, no reward
        return 0;
    }
    /**
     * @param _tokenAddress address of token used to purchase ticket(s).
     * @param _startingTimeSlot the time slot we begin decrementing from. On the initial call it
     * corresponds to the starting slot of a user's stake, shifted one slot down.  
     */
    function getStartActivatedTimeSlot(address _tokenAddress, uint32 _startingTimeSlot) internal  view returns (  uint32 startingTimeSlot_){
        
        uint32 _startingTimeSlotShifted = _startingTimeSlot - LibTimeManagement.denominationalSize();
        (uint32 _bitMapStartTimeSlot, uint8 _stakeStartTimeSlotPosition) = _startingTimeSlotShifted.bitFlagRemainder( LibTimeManagement.denominationalSize() );
        (bytes32 _isTimeSlotActivatedBitMap, )=  getRewardAcitvationBitMap( _tokenAddress,   _bitMapStartTimeSlot);
        //shift left, check 
            
        bytes32 _shiftedBitMap = _isTimeSlotActivatedBitMap << type(uint8).max - _stakeStartTimeSlotPosition;
        if(_shiftedBitMap & bytes32(type(uint256).max) ==  bytes32(0)){
            if( _bitMapStartTimeSlot < GENESIS_TIMESTAMP ){
                return 0;
            }
            else{   
                uint32 _newTimeSlot = _startingTimeSlotShifted -  (_stakeStartTimeSlotPosition + 1 )* LibTimeManagement.denominationalSize();
                getStartActivatedTimeSlot(_tokenAddress, _newTimeSlot);
            }
        }

        for(uint8 _shiftIndex; _shiftIndex < _stakeStartTimeSlotPosition; _shiftIndex++ ){
            uint8 _newPosition = _stakeStartTimeSlotPosition -  _shiftIndex;
            if(_isTimeSlotActivatedBitMap & bytes32 (2**(_newPosition) - 1)  != bytes32(0) ){
                return _bitMapStartTimeSlot + _newPosition * LibTimeManagement.denominationalSize();
            }
        }

        if( _bitMapStartTimeSlot < GENESIS_TIMESTAMP ){
                return 0;
        }

        uint32 _newTimeSlot = _startingTimeSlot -  (_stakeStartTimeSlotPosition + 1 )* LibTimeManagement.denominationalSize();
        getStartActivatedTimeSlot(_tokenAddress, _newTimeSlot);

    }



    
    /**
     * @dev Responsible for updating time pool rewards related data, including:
     *  bitmap - flags which timeslots contained a transaction 
     *  totalTimeSlotSum - caches the total staked sum in one storage slot
     *  rollingEarningsRatio -  updates the rolling earnings sum ratio in the current 
     * time slot and the global variable   
     * @param _tokenAddress token used to purchase ticket
     * @param _timePoolFee the amount of fee added to current time slots earnings  
     */
    function updateRewardsData(address _tokenAddress, uint256 _timePoolFee) internal {
        //updates sum if flag not set, maybe no flag since always non-zero 

        //get current timeslot and it's corresponding rewards
        uint32 _intervalSeconds = LibTimeManagement.getDayIntervalSeconds(LibTimeManagement.StakeDayInterval.One);
        uint32 _currentTimeSlot = uint32( block.timestamp ) .getCurrentIntervalStartTimeSlot(_intervalSeconds);
        console.log("timeslot is %s", _currentTimeSlot);
        RewardsManage storage _timeSlotRewards = timeSlotRewards[ _tokenAddress ][ _currentTimeSlot ];
        
        //current total sum for current slot
        uint256 _totalSlotSum = _timeSlotRewards.totalSlotSum;

        //if true, implies first transaction in timeslot 
        if( _totalSlotSum == 0){
            //sum all staked amounts from each stake interval
            uint256 _stakedAmountSum;
            for( uint8 _stakeIntervalIndex; _stakeIntervalIndex <  uint8(type(LibTimeManagement.StakeDayInterval).max); _stakeIntervalIndex ++){
                uint32 _stakeIntervalSeconds = LibTimeManagement.getDayIntervalSeconds(  _stakeIntervalIndex);
                uint32 _intervalCurrentStartTimeSlot =  uint32(block.timestamp).getCurrentIntervalStartTimeSlot(_stakeIntervalSeconds);
                LibTimeManagement.StakeDayInterval _stakeDayInterval = LibTimeManagement.uint8ToStakeDay(_stakeIntervalIndex); 
                _stakedAmountSum += timeSlotRewards[_tokenAddress][_intervalCurrentStartTimeSlot].stakeSum[  _stakeDayInterval ];
            }
            _stakedAmountSum += CLEANUP_STAKE_AMOUNT;//see CleanupUser contract
            _totalSlotSum  = _stakedAmountSum;
            _timeSlotRewards.totalSlotSum = _totalSlotSum;
            //must update sum and the bitmap stating this timeslot was activated
            updateBitMap(_tokenAddress, _currentTimeSlot);
        }

        // update global rolling earnings and timeslot
        uint256 _rollingEarningsSumRatio = rollingEarningsSumRatio;
        uint256 _newAddedFee = ( _timePoolFee * PRECISION_RETAINER )/_totalSlotSum;
        _rollingEarningsSumRatio += _newAddedFee;

        _timeSlotRewards.totalEarningsPerSum = _rollingEarningsSumRatio;
        rollingEarningsSumRatio = _rollingEarningsSumRatio;
    }
    /**
     * We keep a bitmap of all timeslots, and flag the timeslots that have one transaction or more.
     * This way we can efficiently calculate rewards. 
     * 
     * Gets the bitmap that contains _timeSlot;
     */
    function getRewardAcitvationBitMap(address _tokenAddress, uint32 _timeSlot) internal  view returns( bytes32 bitMap_, uint8 timeSlotPosition_){
        uint32 _minimumIntervalSeconds = LibTimeManagement.getDayIntervalSeconds(LibTimeManagement.StakeDayInterval.One);
        (uint32 _bitFlagTimeSlot, uint8 timeSlotPosition_ ) =  _timeSlot.bitFlagRemainder( _minimumIntervalSeconds);
        bytes32 bitMap_ = timeSlotActivationBitMap[_tokenAddress][ _bitFlagTimeSlot ];
        
    }
    /**
     * Denotes the timeslot contains a transaction
     * @param _tokenAddress Address of token used for ticket sale
     * @param _timeSlot Timeslot that will be now marked for containing a transaction
     */
    function updateBitMap(address _tokenAddress, uint32 _timeSlot) internal {
        //retrieve the starting timeslot of the bitmap containing _timeSlot and the corresponding offset of its corresponding bit
        ( uint32 _bitMapTimeSlotStartTimestamp, uint8 _timeSlotPosition ) =  _timeSlot.bitFlagRemainder(LibTimeManagement.StakeDayInterval.One); 
        console.log("Bitmap timeslot is %s",_bitMapTimeSlotStartTimestamp );
        console.log(_timeSlotPosition);
        bytes32 _outdatedBitMap = timeSlotActivationBitMap[_tokenAddress][ _bitMapTimeSlotStartTimestamp ];
        bytes32 _updatedBitMap = _outdatedBitMap | bytes32( ( 2 ** (_timeSlotPosition) ) );
        timeSlotActivationBitMap[_tokenAddress][ _bitMapTimeSlotStartTimestamp ] = _updatedBitMap;
    }
    // function updateTimePoolEarnings(uint256 _timePoolFee, uint256 _totalSlotSum) internal {
       

    //     //Users can unstake anytime they want, but will forfeit their earnings in the current time slot
    //     //can use one time interval
    //     //we still need to use fixed intervals  due to rewards and sums needed to be updated every 
    //     //transacted timeslot 

    //     /**
    //      So since sums are well defined due to fixed intervals,
    //      we simply find the respective timeslot, go to the beginning day of that interval 
    //      and loading the sum from each interval. 
    //      Only has to be done once per time slot. So transactor would check flag and store it
    //      as well. 
    //      */
    // }


}


/**
 * What if we have multiple stake length tiers i.e. 3 Day, 9 Day, 27 Day
 * Bonuses given to 30 day.
 * You'd have to wait a long time to get into a 30 day if you miss it. 
 * 3,9,18,36 works well in the sense the catchup time isn't long. 
 * a 27 period only has to check once for the 3 day and the once for the 7day
 * 
 * So if you register for the 9 days and suppose you're on day 5, 
 * to get the sum you'd only need to check the 9 day + the latest 3 day
 * could we make it work such that someone can enter a 9 day at day 5?
 * no that wouldn't work 
 * 
 * How do we perform stores of sums? seperate for each interval? that would
 * be the easy first obvious solution. A way to make it more efficient though?
 * the longer intervals are constant, hardly costs any gas.
 */
/**
 * How to we implement sum? We need running sum along with delta. So each time slot has a delta and
 * when the time slot starts the 
 * 
 * Issue is we don't want to store sums over all time slots for a user staking an extended duration. 
 * But we want to access sums in each time slot. So we'd want a running sum that impacts a delta at the start
 * of a time slot.
 * How would we track the running sum efficiently?
 * 
 * 
 * 
 * 
 * So build sum from nearest reference point.
 * reference point is the current sum at a given time slot
 * longest anyone would have backtrack calculate the sum is MAX_TIME_SLOTS?  
 * No. 
 * 
 * Reference point with a bonus? It still seems daunting.
 * Why not a bonus for when staking? This way we could potentially 
 * make some optimizations for drought periods. 
 * If last stake was longer than MAX_STAKE_PERIOD, it's implied 
 * we're able to set a new reference point on new stake. 
 * So when loading new reference point we have the timestamp and last sum,
 * we know the new sum must be zero after MAX_STAKE_PERIOD, IF we force
 * stakers to update new reference point
 */

/**
 * So no future staking, only current timestamp solve issues?
 * Well we certainly help update the sum more frequently, the worst 
 * case scenario is MAX_TIME_INTERVALS. 
 * But we still have issues with sum updates, at some point a stake will
 * end and the sum won't be updated until another transaction. 
 * Why does user need to specify how long? So the weight can be distributed. 
 * So if we set it so users have uniform stakes but no end time. The end time
 * is when they unstake and collect rewards. This commpletely solves the problem.
 * 
 * We still need to figure out the sum is calculated. Before the sum was governed 
 * by the current sum at time t < timeSlot_n. So currently the sum is set before 
 * the timeSlot starts. but then how would you unstake and leave sum? 
 * 
 * you update the sum but forfeit your profit for that timeslot. 
 * issue with this is people could stake and leave when it didnt pan out well for
 * them. maybe require a minimum stake
 * 
 * 
 * So single time interval, no extensions past that time interval.
 * i.e. 8hr
 */