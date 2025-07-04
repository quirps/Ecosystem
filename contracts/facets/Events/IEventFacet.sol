// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { LibEventFacet } from "./LibEventFacet.sol"; 

// Interfaces for external dependencies of the EventFacet
interface IERC1155 {
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

interface ITieredPermission {
    function getMemberLevel(address user) external view returns (uint256 level);
    // Potentially more functions if the Ecosystem needs to verify AppCreator status etc.
    // function isAppCreator(address _creator) external view returns (bool isAppCreator_);
}

/**
 * @title IEventFacet
 * @notice Interface for the EventFacet, exposed by the Ecosystem Diamond.
 * @dev App logic contracts will call these functions externally.
 */
interface IEventFacet {
    // --- Events emitted by the EventFacet ---
    event EventCreated(
        uint256 indexed eventId,
        address indexed creator,
        address indexed appLogic,
        LibEventFacet.EventStatus status,
        uint32 startTime,
        uint32 endTime,
        string metadataURI
    );

    event EventStatusUpdated(
        uint256 indexed eventId,
        LibEventFacet.EventStatus oldStatus,
        LibEventFacet.EventStatus newStatus,
        address indexed caller
    );

    event ParticipantVerified(
        uint256 indexed eventId,
        address indexed participant,
        uint256 indexed ticketId,
        uint256 amount
    );

    // --- Core Functions (Called by app logic contracts) ---

    /**
     * @notice Creates a new generic event entry in the Ecosystem.
     * @dev Called by an app logic contract (e.g., PollApp) after its own initial setup.
     * The `appLogic` address is the `msg.sender` of this call.
     * @param params Parameters for the event. The `creator` and `appLogic` fields
     * in `params` should be correctly set by the calling app.
     * @return eventId_ The unique ID of the newly created event.
     */
    function createEvent(LibEventFacet.CreateEventParams memory params) external returns (uint256 eventId_);

    /**
     * @notice Verifies participant eligibility and processes ticket requirements for an event.
     * @dev Called by an app logic contract (e.g., PollApp.castVote) during user participation.
     * Handles ERC1155 transfers (burn, hold, stake) based on event's `ticketRequirements`.
     * Reverts if participation fails (e.g., insufficient tickets, too low member level).
     * @param eventId The ID of the event.
     * @param participant The address of the user attempting to participate.
     * @param ticketId The specific ERC1155 ticket ID being used for this participation.
     * @param amount The amount of the ticket being used.
     * @return success True if participation was successful.
     */
    function verifyAndProcessParticipation(
        uint256 eventId,
        address participant,
        uint256 ticketId,
        uint256 amount
    ) external returns (bool success);

    /**
     * @notice Formally ends an event in the Ecosystem.
     * @dev Called by the event's `appLogic` contract (e.g., PollApp.endPoll),
     * which internally verifies `onlyEventCreator`.
     * Sets the event's status to `Completed`.
     * @param eventId The ID of the event to end.
     */
    function endEvent(uint256 eventId) external;

    /**
     * @notice Cancels an event prematurely.
     * @dev Can only be called by a designated admin or perhaps the original creator.
     * Sets the event's status to `Cancelled`.
     * This needs careful access control (e.g., `onlyOwner` of the Diamond).
     * @param eventId The ID of the event to cancel.
     */
    function cancelEvent(uint256 eventId) external;

    // --- Read Functions ---

    /**
     * @notice Gets the full details of an event.
     * @param eventId The ID of the event.
     * @return eventDetails The full Event struct.
     */
    function getEvent(uint256 eventId) external view returns (LibEventFacet.Event memory eventDetails);

    /**
     * @notice Gets the creator of a specific event.
     * @param eventId The ID of the event.
     * @return creator The address of the event creator.
     */
    function getEventCreator(uint256 eventId) external view returns (address creator);

    /**
     * @notice Gets the status of a specific event.
     * @param eventId The ID of the event.
     * @return status The current status of the event.
     */
    function getEventStatus(uint256 eventId) external view returns (LibEventFacet.EventStatus status);

    /**
     * @notice Checks if an app address is a registered/whitelisted app for event creation.
     * @param appAddress The address of the app logic contract.
     * @return isRegistered True if the app is registered.
     */
    function isRegisteredApp(address appAddress) external view returns (bool isRegistered);

    // --- Admin Functions (for Diamond owner/governance) ---

    /**
     * @notice Registers a new app logic contract that can create events in the ecosystem.
     * @dev Only callable by the Diamond owner/governance.
     * @param appAddress The address of the app contract to register.
     * @param isRegistered True to register, false to unregister.
     */
    function registerApp(address appAddress, bool isRegistered) external;

    // Functions to retrieve tickets held/staked by the Ecosystem for an event
    // function getHeldTickets(uint256 eventId, address user, uint256 ticketId) external view returns (uint256 amount);
}