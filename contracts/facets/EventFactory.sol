// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../internals/iEventFactory.sol";

contract EventFactory is iEventFactory {
    function createEvent(
        uint32 _startTime,
        uint32 _endTime,
        uint256 _minEntries,
        uint256 _maxEntries,
        string calldata _imageUri
    ) external returns (uint256) {
       return _createEvent(_startTime, _endTime, _minEntries, _maxEntries, _imageUri);
    }
     function deactivateEvent(uint256 eventId, bytes32 root) external {
        _deactivateEvent(eventId, root);
     }

    function extendEvent(uint256 eventId, uint32 addedTime) external {
        _extendEvent(eventId, addedTime);
    }

    function redeemTickets(uint256 eventId, uint256[] calldata ticketIds, uint256[] calldata amounts) external {
        _redeemTickets(eventId, ticketIds, amounts);
    }


    function _refundTicketsWithProof(
        uint256 eventId, 
        uint256[] memory ticketIds, 
        address lowerBound, 
        address upperBound, 
        bytes32[] calldata merkleProof
    ) external {
        _refundTicketsWithProof(eventId, ticketIds, lowerBound, upperBound, merkleProof);
    }
}
