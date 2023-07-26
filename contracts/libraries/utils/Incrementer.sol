pragma solidity ^0.8.6;

library Incrementer {

     function decrementKey(bytes28 self) internal pure returns( bytes28 ){
        if( bytes8(self)  == bytes8(0) ) {
            return self;
        }
        bytes8 decrementedIndex = bytes8( uint64( bytes8( self ) ) - 1 );
        bytes28 decrementedKey = bytes28( abi.encodePacked(decrementedIndex, bytes20( self << 64) ) );
        return decrementedKey ;
    }
    
     function incrementKey(bytes28 self) internal pure returns( bytes28 ){
        bytes8 decrementedIndex = bytes8( uint64( bytes8( self ) ) + 1 );
        bytes28 decrementedKey = bytes28( abi.encodePacked(decrementedIndex, bytes20( self << 64) ) );
        return decrementedKey ;
    }
    function decrementIndex(bytes8 self) internal returns( bytes8 decrementMaxIndex_ ){
        decrementMaxIndex_ = bytes8( uint64( self ) - 1 );
    }
    function incrementIndex(bytes8 self) internal returns( bytes8 incrementMaxIndex_ ){
        incrementMaxIndex_ = bytes8( uint64( self ) + 1 );
    }
}