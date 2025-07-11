pragma solidity ^0.8.9;

import {LibERC1155TransferConstraints} from "../Tokens/ERC1155/libraries/LibERC1155TransferConstraints.sol";
import {iERC1155} from "../Tokens/ERC1155/internals/iERC1155.sol";
import {iTransferSetConstraints} from "../Tokens/ERC1155/internals/iTransferSetConstraints.sol";
import {iOwnership} from "../Ownership/_Ownership.sol";
contract TicketCreate is iTransferSetConstraints, iERC1155 {
    struct TicketMeta {
        string title;
        string description;
        string imageHash;
    }

    event TicketsCreated(uint256, uint256, TicketMeta);
    /**
        Owner verification at ticketCreate
     */
    function ticketCreateBatch(
        uint256[] memory _amount,
        TicketMeta[] memory _ticketMeta,
        LibERC1155TransferConstraints.Constraints[] memory _constraints
    ) external {
        //check equal lengths
        for (uint256 _constraintIndex; _constraintIndex < _constraints.length; _constraintIndex++) {
            ticketCreate(_amount[_constraintIndex], _ticketMeta[_constraintIndex], _constraints[_constraintIndex]);
        }
    }

    //The order of the Constraint struct matches the order of the if statements
    //and correspond to the constraint bitmap in ascending order.
    function ticketCreate(uint256 _amount, TicketMeta memory _ticketMeta, LibERC1155TransferConstraints.Constraints memory _constraints) public returns (uint256 ticketId_){
        isEcosystemOwnerVerification();
 
        ticketId_ = ticketConstraintHandler(_constraints);

        _mint(msgSender(), ticketId_, _amount, ""); 

        emit TicketsCreated(ticketId_, _amount, _ticketMeta);
    }

    function getTicketConstraints( uint256 ticketId ) external view returns (LibERC1155TransferConstraints.Constraints memory contraints_){
        LibERC1155TransferConstraints.ConstraintStorage storage cs = LibERC1155TransferConstraints.erc1155ConstraintStorage()

        constraints_ = 
    }
}

/**
    So we need to create ids for each ticket. These ids must be in the appropriate range. This range is determined by the ticket type
    which is defined by iTicketConstraints
 */
