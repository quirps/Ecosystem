pragma solidity ^0.8.9;

library LibUnderflow{

    function uint8Underflow(uint8 _minuend, uint8 _subtrahend) internal pure returns(bool isUnderflow_, uint8 amount_) {
        unchecked{ 
            uint8  _difference =  _minuend - _subtrahend;
            if(_difference > _minuend){
                return (true , type(uint8).max + 1 - _difference);
            }
            return (false, _difference);
        }
    }
}