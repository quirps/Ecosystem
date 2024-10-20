pragma solidity ^0.8.9;

import {LibERC1155TransferConstraints} from "../Tokens/ERC1155/libraries/LibERC1155TransferConstraints.sol";
contract TicketCreate{

    struct TicketMeta{
        string title;
        string description;
        
    }
    
    function ticketCreateBatch(LibERC1155TransferConstraints.Constraints[] memory  _constraints) external {
        for( uint256 _constraintIndex; _constraintIndex < _constraints.length; _constraintIndex++){
            ticketCreate( _constraints[ _constraintIndex ] );
        }
    }

    //The order of the Constraint struct matches the order of the if statements
    //and correspond to the constraint bitmap in ascending order. 
    function ticketCreate(LibERC1155TransferConstraints.Constraints memory _constraints) public {

        if(_constraints.transferLimit.isActive){

        }
    }

}


/**
    So we need to 
 */