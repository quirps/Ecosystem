// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

/// @title An interface for the EventFactory contract
interface IEventFactory {

    /// @notice This event is emitted when a new event is created
    event EventCreated(uint256 indexed eventId, uint32 startTime, uint32 endTime);

    /// @notice This event is emitted when the details for a token are set for an event
    event TokenDetailsSet(uint256 indexed eventId, uint256 indexed tokenId, uint256 limitPerUser, uint256 totalLimit);

    /// @notice This event is emitted when tokens are submitted for an event
    event TokensSubmitted(uint256 indexed eventId, uint256 indexed tokenId, address indexed user, uint256 amount);

    /// @notice This event is emitted when a user is reimbursed for their tokens
    event UserReimbursed(uint256 indexed eventId, uint256 indexed tokenId, address indexed user, uint256 amount);

    /// @notice This event is emitted when an event is cancelled
    event EventCancelled(uint256 indexed eventId);

    /// @notice This event is emitted when a user withdraws their tokens from a cancelled event
    event TokensWithdrawn(uint256 indexed eventId, uint256 indexed tokenId, address indexed user, uint256 amount);

    /// @notice Creates a new event with the given details
    /// @param eventId The ID of the event
    /// @param startTime The start time of the event
    /// @param endTime The end time of the event
    function createEvent(uint256 eventId, uint32 startTime, uint32 endTime) external;

    /// @notice Sets the details for a token for a specific event
    /// @param eventId The ID of the event
    /// @param tokenId The ID of the token
    /// @param limitPerUser The limit of tokens a user can submit for the event
    /// @param totalLimit The total limit of tokens that can be submitted for the event
    function setTokenDetails(uint256 eventId, uint256 tokenId, uint256 limitPerUser, uint256 totalLimit) external;

    /// @notice Submits tokens for a user for a specific event
    /// @param eventId The ID of the event
    /// @param tokenId The ID of the token
    /// @param amount The amount of tokens to submit
    function submitTokens(uint256 eventId, uint256 tokenId, uint256 amount) external;

    /// @notice Reimburses a user for their tokens for a specific event
    /// @param eventId The ID of the event
    /// @param tokenId The ID of the token
    /// @param amount The amount of tokens to reimburse
    function reimburseUser(uint256 eventId, uint256 tokenId, uint256 amount) external;

    /// @notice Cancels a specific event
    /// @param eventId The ID of the event
    function cancelEvent(uint256 eventId) external;

    /// @notice Allows a user to withdraw their tokens from a cancelled event
    /// @param eventId The ID of the event
    /// @param tokenId The ID of the token
    function withdrawTokens(uint256 eventId, uint256 tokenId) external;
}
