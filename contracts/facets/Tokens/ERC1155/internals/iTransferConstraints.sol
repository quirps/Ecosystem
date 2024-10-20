pragma solidity ^0.8.9;


contract iTransferConstraints {

    uint256 INTERVAL_SIZE = 2**196; 
    uint256 NUMBER_INTERVALS = 2**60; // max 60 constraints
    uint8 CURRENT_MAX_INTERVALS = 8;
    /**
        Checks all the constraints that apply to the given ticketId
        @notice Ticket Id's are
     */
    function constraintCheck(uint256 ticketId) internal{
        // divide out multiple, extract flag

        bytes32 constraintBitMap = bytes32( ticketId / INTERVAL_SIZE);

        for( uint8 _flag; _flag < CURRENT_MAX_INTERVALS; _flag ++){

            if ( (constraintBitMap & bytes32( uint256 ( uint8(1) << _flag ) ) ) == bytes32(uint256(1)) ){

                if( _flag == 0 ){
                    //Unconstrained No logic
                }
                else if( _flag == 1){
                    //limited transfers check
                }
                else if (_flag == 2){
                    //member rank transfer, only certain ranks may have access to these tickets
                }
                else if (_flag == 4){
                    // Expireable - reject if ticket is expired
                }
                else if(_flag == 8){
                    // Blacklist - reject certain members for a given period of time
                }
                else if(_flag == 16){
                    //Max Ticket Constraint
                }
            }
        }
    }
}



/**
    We will be using 10E18 intervals (denoted INTERVAL_SIZE) for the various ticket categories. 

    How do we route the categories? 
    We would extract the flag from the ticketId via modulo INTERVAL_SIZE??

    Let's list all the possible transfer modifiers: 
        - Limited trades from a user for a given ticket
        - Limited trades from a user in a given time interval
        - Member rank limited transfer
        - Expire Date 
        - Transfer between specific ranks

 

    Need a category nonce


    I think we just 
 */