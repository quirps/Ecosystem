// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IEventFacet
/// @dev Interface for the event management facet
interface IEventFacet {

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
        string calldata _imageUri
    ) external returns (uint256);

    /// @notice Updates the details of an existing event
    /// @dev Allows the owner to update event details
    /// @param eventId The ID of the event to be updated
    /// @param newStartTime The new start time for the event
    /// @param newEndTime The new end time for the event
    /// @param newImageUri The new image URI for the event
    function updateEventDetails(uint256 eventId, uint32 newStartTime, uint32 newEndTime, string calldata newImageUri) external;

    /// @notice Allows the redemption of multiple tickets for an event
    /// @dev Batch process to redeem multiple tickets at once
    /// @param eventId The ID of the event
    /// @param ticketIds The IDs of the tickets to be redeemed
    /// @param amounts The amounts corresponding to each ticket to be redeemed
    function redeemTickets(uint256 eventId, uint256[] calldata ticketIds, uint256[] calldata amounts) external;

    /// @notice Allows the refund of tickets
    /// @dev Batch process to refund multiple tickets at once
    /// @param eventId The ID of the event
    /// @param ticketIds The IDs of the tickets to be refunded
    function refundTickets(uint256 eventId, uint256[] calldata ticketIds) external;
}