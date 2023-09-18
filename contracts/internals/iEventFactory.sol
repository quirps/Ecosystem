    // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibEventFactory.sol";
import "../libraries/utils/MerkleProof.sol";
import "../interfaces/IERC1155Transfer.sol";
import "./iOwnership.sol";
import "../libraries/utils/Context.sol";

contract iEventFactory is iOwnership, Context {

    IERC1155Transfer public tokenContract;
    

 /// @dev Emitted when an event is deactivated by the owner.
/// @param eventId The unique identifier for the event.
event EventDeactivated(uint256 eventId);

/// @dev Emitted when an event transitions from a pending state to an active state, which generally happens when the first ticket for the event is redeemed.
/// @param eventId The unique identifier for the event.
event EventActivated(uint256 eventId);

/// @dev Emitted when one or more tickets are redeemed for an event. Contains details of the ticket IDs and the respective amounts that have been redeemed.
/// @param eventId The unique identifier for the event.
/// @param ticketIds An array of unique identifiers for the tickets that have been redeemed.
/// @param amounts An array of amounts representing the quantity redeemed for each corresponding ticket ID.
event TicketRedeemed(uint256 eventId, uint256[] ticketIds, uint256[] amounts);

/// @dev Emitted when a ticket is refunded. This occurs after a successful call to the `refundTicketsWithProof` function, indicating that the refund was processed successfully.
/// @param eventId The unique identifier for the event.
/// @param ticketId The unique identifier for the ticket that has been refunded.
/// @param amount The amount that has been refunded for the particular ticket id.
event TicketRefunded(uint256 eventId, uint256 ticketId, uint256 amount);

/// @dev Emitted when a new event is created. Contains all the essential details regarding the event including its schedule and entry conditions.
/// @param eventId The unique identifier for the event.
/// @param startTime The start time of the event, represented as a UNIX timestamp.
/// @param endTime The end time of the event, represented as a UNIX timestamp.
/// @param minEntries The minimum number of entries required for the event.
/// @param maxEntries The maximum number of entries allowed for the event.
/// @param imageUri A URI pointing to the event's image resource.
/// @param status The current status of the event.
event EventDetails(uint256 eventId, uint32 startTime, uint32 endTime, uint256 minEntries, uint256 maxEntries, string imageUri, LibEventFactoryStorage.EventStatus status);

/// @dev Emitted when ticket details for a specific event are defined or updated. Contains arrays of ticket IDs and their corresponding details.
/// @param eventId The unique identifier for the event.
/// @param ticketIds An array of unique identifiers for the tickets associated with the event.
/// @param ticketDetails An array of structures holding details for each ticket corresponding to the IDs in the `ticketIds` parameter.
event TicketDetails(uint256 eventId, uint256[] ticketIds, LibEventFactoryStorage.TicketDetail[] ticketDetails);

    constructor(address _tokenContract) {
        tokenContract = IERC1155Transfer(_tokenContract);
    }

    modifier onlyOwner() {
        require(msg.sender == _owner(), "Not owner");
        _;
    }

    function _extendEvent(uint256 eventId, uint32 addedTime) internal {
        
    }
    function _deactivateEvent(uint256 eventId, bytes32 root) internal onlyOwner {
        LibEventFactoryStorage.EventDetail storage eventDetail = LibEventFactoryStorage.getEventDetail(eventId);

        require(
            eventDetail.status == LibEventFactoryStorage.EventStatus.Active || eventDetail.status == LibEventFactoryStorage.EventStatus.Pending, 
            "Event has already terminated"
        );
        
        eventDetail.status = LibEventFactoryStorage.EventStatus.Deactivated;
        emit EventDeactivated(eventId);

        if (root != bytes32(0)) {
            eventDetail.merkleRoot = root;
        }
    }


    // Additional functions such as `_redeemTickets`, `_refundTicketsWithProof`, and `_createEvent` would be implemented here following the existing logic, but leveraging the `LibEventFactoryStorage` library to interact with storage.

    // Assuming the necessary imports and library setup are done at the top of your file


    function _createEvent(
        uint32 _startTime,
        uint32 _endTime,
        uint256 _minEntries,
        uint256 _maxEntries,
        string memory _imageUri,
        uint256[] memory _ticketIds,
        LibEventFactoryStorage.TicketDetail[] memory _ticketDetails
    ) internal returns (uint256) {
        LibEventFactoryStorage.EventStorage storage es = LibEventFactoryStorage.eventStorage();
        
        require(_ticketIds.length == _ticketDetails.length, "Must be same length.");
        require(_endTime > block.timestamp - 1, "Must be non-trivial event time window");

        uint256 eventId = uint256(keccak256(abi.encodePacked(_startTime, _endTime, _minEntries, _maxEntries, _imageUri, block.timestamp)));
        require(es.events[eventId].endTime == 0, "Event must not exist");
        LibEventFactoryStorage.EventDetail storage newEvent = es.events[eventId];
        newEvent.startTime = _startTime;
        newEvent.endTime = _endTime;
        newEvent.minEntries = _minEntries;
        newEvent.maxEntries = _maxEntries;
        newEvent.imageUri = _imageUri;
        newEvent.status = uint32(block.timestamp) < _startTime ? LibEventFactoryStorage.EventStatus.Pending : LibEventFactoryStorage.EventStatus.Active;

        emit EventDetails(eventId, _startTime, _endTime, _minEntries, _maxEntries, _imageUri, newEvent.status);

        for (uint256 i = 0; i < _ticketIds.length; i++) {
            require(_ticketDetails[i].maxAmount != 0, "Must have non-trivial maximum ticket amount");
            newEvent.ticketDetails[_ticketIds[i]] = _ticketDetails[i];
        }
        
        emit TicketDetails(eventId, _ticketIds, _ticketDetails);

        return eventId;
    }




     function _redeemTickets(
        uint256 eventId, 
        uint256[] memory ticketIds, 
        uint256[] memory amounts
    ) internal {
        LibEventFactoryStorage.EventDetail storage eventDetail = LibEventFactoryStorage.getEventDetail(eventId);
        LibEventFactoryStorage.EventStatus _status = eventDetail.status;
        
        require(block.timestamp >= eventDetail.startTime && block.timestamp <= eventDetail.endTime, "Event not active");
        require(ticketIds.length == amounts.length, "Mismatched ticketIds and amounts lengths");

        if (_status == LibEventFactoryStorage.EventStatus.Pending) {
            eventDetail.status = LibEventFactoryStorage.EventStatus.Active;
            emit EventActivated(eventId);
        }
        
        for (uint i = 0; i < ticketIds.length; i++) {
            LibEventFactoryStorage.TicketDetail storage ticketDetail = LibEventFactoryStorage.getTicketDetail(eventId,ticketIds[i]);
            require(eventDetail.currentEntries + 1 <= eventDetail.maxEntries, "Exceeding max entries");
            require(amounts[i] >= ticketDetail.minAmount && amounts[i] <= ticketDetail.maxAmount, "Invalid ticket amount");

            // Transfer ERC1155 tokens from user to contract
            tokenContract.safeTransferFrom(msgSender(), address(this), ticketIds[i], amounts[i], "");

            // Update event and ticket details
            eventDetail.currentEntries += 1;
            eventDetail.ticketsRedeemed[msgSender()][ticketIds[i]] += amounts[i];
        }
        emit TicketRedeemed(eventId, ticketIds, amounts);
    }

    function _refundTicketsWithProof(
        uint256 eventId, 
        uint256[] memory ticketIds, 
        address lowerBound, 
        address upperBound, 
        bytes32[] calldata merkleProof
            ) internal {
        LibEventFactoryStorage.EventDetail storage eventDetail = LibEventFactoryStorage.getEventDetail(eventId);

        require(validateNonInclusion(eventId, lowerBound, upperBound, merkleProof), "User was honored or proof is incorrect");

        for (uint i = 0; i < ticketIds.length; i++) {
            uint256 amountToRefund = eventDetail.ticketsRedeemed[msgSender()][ticketIds[i]];
            require(amountToRefund > 0, "No tickets to refund for this ID");

            // Update event details before transfer to ensure state consistency
            eventDetail.currentEntries -= 1;
            eventDetail.ticketsRedeemed[msgSender()][ticketIds[i]] = 0;

            // Transfer ERC1155 tokens back to the user
            tokenContract.safeTransferFrom(address(this), msgSender(), ticketIds[i], amountToRefund, "");
            emit TicketRefunded(eventId, ticketIds[i], amountToRefund);
        }
    }

    function validateNonInclusion(
        uint256 eventId,
        address lowerBound,
        address upperBound,
        bytes32[] calldata merkleProof
    ) internal view returns (bool) {
        LibEventFactoryStorage.EventStorage storage es = LibEventFactoryStorage.eventStorage();
        LibEventFactoryStorage.EventDetail storage eventDetail = LibEventFactoryStorage.getEventDetail(eventId);

        // Ensure sender is within bounds
        require(uint160(lowerBound) < uint160(msgSender()) && uint160(msgSender()) < uint160(upperBound), "Sender is not within the exclusive bounds");

        // Verify non-inclusion proof
        bytes32 leaf = keccak256(abi.encodePacked(lowerBound, upperBound));
        return !MerkleProof.verify(merkleProof, eventDetail.merkleRoot, leaf);
    }
}

