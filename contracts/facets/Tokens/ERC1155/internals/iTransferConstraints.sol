pragma solidity ^0.8.9;


contract iTransferConstraints {


    /**
        Checks all the constraints that apply to the given ticketId
        @notice Ticket Id's are
     */
    function constraintCheck(uint256 ticketId) internal{
        // divide out multiple, extract flag
        uint16 _flag = 0;

        if( _flag == 0){
            //Unconstrained No logic
        }
        else if( _flag == 1){
            //limited transfers check
        }
        else if (_flag == 2){
            //member rank transfer, only certain ranks may have access to these tickets
        }
        else if (_flag == 3){
            // Expireable - reject if ticket is expired
        }
        else if(_flag == 4){
            // Blacklist - reject certain members for a given period of time
        }
        else if(_flag == 5){
            //Max Ticket Constraint
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