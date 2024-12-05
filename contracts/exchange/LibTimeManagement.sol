pragma solidity ^0.8.9;

library LibTimeManagement{
    
    enum StakeDayInterval{ One, Three, Nine, Eighteen, ThirtySix}

    //StakeDayInterval helpers
    function getDayIntervalSeconds( StakeDayInterval _stakeDayInterval) internal pure returns (uint32){
         return stakeDayIntervals()[uint8(_stakeDayInterval)];
    }
    function getDayIntervalSeconds( uint8 _stakeEnumIndexer) internal pure returns (uint32){
         return stakeDayIntervals()[ _stakeEnumIndexer];
    }
    function stakeDayIntervals() internal pure returns ( uint32[5] memory){
        return [uint32(86400), 259200, 777600, 1555200, 3110400];
    }
    function uint8ToStakeDay(uint8 _stakeDayIntervalIndex) internal pure returns ( StakeDayInterval stakeDayInterval_){
        return StakeDayInterval(_stakeDayIntervalIndex);
    }
    /**
     * 
     * @param _unix initial time slot
     * @param _incrementAmount amount of denmoninatinal interval sizes to increment
     */ 
    function incrementTimeSlot( uint32 _unix, uint16 _incrementAmount) internal pure returns (uint32 incrementedTimeSlot_){
        
    }
    
    //must be ordered from least to greatest
    //smallest item IS the denomination unit of stake interval
    
  
    function getCurrentIntervalStartTimeSlot(uint32 _unix, uint32 _TIME_INTERVAL) internal pure returns(uint32 timeSlot_){
        timeSlot_ = _unix - (_unix % _TIME_INTERVAL );
    } 
    function getNextTimeSlot(uint32 _unix, uint32 _TIME_INTERVAL) internal pure returns(uint32 timeSlot_){
        timeSlot_ = _unix - (_unix % _TIME_INTERVAL ) + _TIME_INTERVAL;
    } 
    /*
     *  Already know _unix is a multiple of time interval, so now we find out what bit in _BIT_FLAG_INTERVAL
     *  corresponds to the inverval 
     * @param _unix 
     * @param _BIT_FLAG_INTERVAL 
     */
    
    function bitFlagRemainder(uint32 _unix, uint32 _INTERVAL_SIZE ) internal pure returns (uint32 bitFlagTimestamp_, uint8 bitStartPosition_){
        uint32 _bitFlagInterval = _INTERVAL_SIZE * type(uint8).max;
        bitStartPosition_ =  uint8 ( ( _unix % _bitFlagInterval ) / _INTERVAL_SIZE) ; 
        bitFlagTimestamp_ = _unix - (_unix % _bitFlagInterval );
    }
    
    function shiftDownBitMap(uint32 _unix) internal pure returns (uint32 shiftedSlot_){
        shiftedSlot_ = _unix - denominationalSize() * type(uint8).max;
    }
    
    function getTimeSlotFromPosition(uint32 _activatedBitMapStartingSlot, uint8 _timeSlotPosition) internal pure returns(uint32 timeSlot_){
        _activatedBitMapStartingSlot + _timeSlotPosition ;//FIX
    }
    function getFinalTimeSlot(uint32 _startTimeSlot, StakeDayInterval _stakeDayInterval) internal pure returns(uint32 finalTimeSlot_){
        //subtract denominational interval due to the startTimeSlot being included 
        finalTimeSlot_ = _startTimeSlot + getDayIntervalSeconds(_stakeDayInterval) - getDayIntervalSeconds(StakeDayInterval.One);
    }
    /**
     * Converting an interval to a denomination size is useful for getting the size of an
     * interval in amount of timeslots, which is handy with indexing
     */
    function denominationalSize() internal pure returns(uint32 size_){
        size_ = getDayIntervalSeconds(StakeDayInterval.One);

    }
    /**
     * 
     * @param _stakeInterval stake interval to be converted
     * @dev We can perform this division so long as max interval is <= 255 times bigger than denominational size 
     */
    function convertDenominationalUnits(StakeDayInterval _stakeInterval) internal pure returns(uint8 denominationalSize_){
        uint32 _intervalSeconds = getDayIntervalSeconds(_stakeInterval);
        denominationalSize_ = uint8(_intervalSeconds / denominationalSize());
    }
    function bitFlagRemainder(uint32 _unix, StakeDayInterval _interval ) internal pure returns (uint32 bitFlagTimestamp_, uint8 bitFlagPosition_){
         uint32 _intervalSeconds = getDayIntervalSeconds(_interval);
        ( bitFlagTimestamp_,  bitFlagPosition_) = bitFlagRemainder(_unix, _intervalSeconds);
    }
} 


