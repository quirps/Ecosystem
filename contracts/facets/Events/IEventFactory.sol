// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibEventFactory} from "./LibEventFactory.sol"; 
/// @title IEventFacet
/// @dev Interface for the event management facet
interface IEventFactory {
    /// @notice Sets the Merkle root for the specified event.
    /// @dev Only callable by the owner or authorized addresses.
    /// @param eventId The ID of the event to set the Merkle root for.
    /// @param merkleRoot The new Merkle root.
    function setMerkleRoot(uint256 eventId, bytes32 merkleRoot) external;

    /// @notice Sets a new image URI for the specified event.
    /// @dev Only callable by the owner or authorized addresses.
    /// @param eventId The ID of the event to set the image URI for.
    /// @param imageUri The new image URI as a string.
    function setImageUri(uint256 eventId, string memory imageUri) external;

    /// @notice Deactivates the specified event and optionally updates the Merkle root.
    /// @dev Only callable by the owner or authorized addresses. Can be used to deactivate an event prematurely.
    /// @param eventId The ID of the event to deactivate.
    /// @param root Optionally, a new Merkle root to set. Pass bytes32(0) to not update the Merkle root.
    function deactivateEvent(uint256 eventId, bytes32 root) external;

    /// @notice Extends the duration of the specified event by the added time.
    /// @dev Only callable by the owner or authorized addresses. The event time extension should respect any set maximum limits.
    /// @param eventId The ID of the event to extend.
    /// @param addedTime The additional time to add to the event's duration, in seconds.
    function extendEvent(uint256 eventId, uint32 addedTime) external;

    /// @notice Creates a new event
    /// @dev External function that allows for the creation of a new event
    /// @param _startTime The start time of the event
    /// @param _endTime The end time of the event
    /// @param _minEntries The minimum number of entries for the event
    /// @param _maxEntries The maximum number of entries for the event
    /// @param _imageUri The URI for the event's image
    /// @return The ID of the created event
    function createEvent(
        uint32 _startTime,
        uint32 _endTime,
        uint256 _minEntries,
        uint256 _maxEntries,
        string calldata _imageUri,
        uint256[] memory _ticketIds,
        LibEventFactory.TicketDetail[] memory _ticketDetails
    ) external returns (uint256);

    /// @notice Allows the redemption of multiple tickets for an event
    /// @dev Batch process to redeem multiple tickets at once
    /// @param eventId The ID of the event
    /// @param ticketIds The IDs of the tickets to be redeemed
    /// @param amounts The amounts corresponding to each ticket to be redeemed
    function redeemTickets(uint256 eventId, uint256[] calldata ticketIds, uint256[] calldata amounts) external;

    /// @notice Allows the refund of tickets
    /// @dev Batch process to refund multiple tickets at once. We refund a user
          ///   if they can prove their addre
    /// @param eventId The ID of the event
    /// @param ticketIds The IDs of the tickets to be refunded
    /// @param lowerBound Lower bound address 
    /// @param upperBound upper bound address 
    /// @param merkleProof Lower bound address 

    function refundTicketsWithProof(uint256 eventId, uint256[] calldata ticketIds, address lowerBound, 
        address upperBound, 
        bytes32[] calldata merkleProof) external;
}
