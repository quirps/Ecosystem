// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./_EventFactory.sol";
import "./IEventFactory.sol";
import "./LibEventFactory.sol"; 
import { LibOwnership } from "../Ownership/LibOwnership.sol";
 
contract EventFactory is IEventFactory, iEventFactory { 
     function setMerkleRoot(uint256 eventId, bytes32 root) external onlyOwner {
        _setMerkleRoot(eventId, root);
    }
    function setImageUri(uint256 eventId, string memory imageUri) external onlyOwner {
        _setImageUri(eventId, imageUri);
    }
    function createEvent(
        uint32 _startTime,
        uint32 _endTime,
        uint256 _minEntries,
        uint256 _maxEntries,
        string calldata _imageUri,
        uint256[] memory _ticketIds,
        LibEventFactory.TicketDetail[] memory _ticketDetails
    ) external returns (uint256) {
         isEcosystemOwnerVerification();
       return _createEvent(_startTime, _endTime, _minEntries, _maxEntries, _imageUri, _ticketIds, _ticketDetails);
    }
     function deactivateEvent(uint256 eventId, bytes32 root) external {
        isEcosystemOwnerVerification();
        _deactivateEvent(eventId, root);
     }

    function extendEvent(uint256 eventId, uint32 addedTime) external {
         isEcosystemOwnerVerification();
        _extendEvent(eventId, addedTime);
    }

    function redeemTickets(uint256 eventId, uint256[] calldata ticketIds, uint256[] calldata amounts) external {
        _redeemTickets(eventId, ticketIds, amounts);
    }


    function refundTicketsWithProof(
        uint256 eventId, 
        uint256[] memory ticketIds, 
        address lowerBound, 
        address upperBound, 
        bytes32[] calldata merkleProof
    ) external  {
        _refundTicketsWithProof(eventId, ticketIds, lowerBound, upperBound, merkleProof);
    }
}

/**
    facet per event architecture. 
    Would need to generate a new interface object, check for collisions,
    clean up when done (can't pollute 2^32 too much)
 */