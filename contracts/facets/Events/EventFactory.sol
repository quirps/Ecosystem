// contracts/facets/EventFacet.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19; // Use a consistent version matching others

// Interfaces
import { IEventFacet } from "./IEventFactory.sol"; // Adjust path
 
// Internal Logic
import { iEventFactory } from "./_EventFactory.sol"; // Adjust path (provides core event logic + app instance lookups)
 
// Libraries
import { LibEventFactory } from "./LibEventFactory.sol"; // Adjust path
import { iOwnership } from "../Ownership/_Ownership.sol"; // Assuming ownership stored here for example

// Security
import { ReentrancyGuardContract } from "../../ReentrancyGuard.sol";

/**
 * @title EventFacet
 * @notice Manages the creation, state, and core verification for ecosystem events.
 * @dev Implements IEventFacet. Uses internal logic from iEventFactory.
 * Handles the user-facing entry point for event creation and the verification
 * callback point for external Logic App instances during participation.
 */
contract EventFacet is  iEventFactory, ReentrancyGuardContract {

    // --- External Functions --- 

    /**
     * @notice Creates a new event, checking if an app is installed for the given type.
     * @dev Only callable by the contract owner (or designated creator role).
     */
     
    function createEvent(
        LibEventFactory.CreateEventParams calldata createEventParams
    ) external  onlyOwner returns (uint256 eventId) { // Apply access control
        // Calls internal function from iEventFactory 
        eventId = _createEvent( 
           createEventParams
        );
        // Event emitted by _createEvent
    }

    /**
     * @notice Verifies participation criteria and executes required token interaction.
     * @dev Called BY logic apps. Applies nonReentrant guard and checks caller is the installed logic app.
     */
    function verifyAndProcessParticipation(
        uint256 eventId,
        address user,
        uint256 ticketId,
        uint256 amount,
        LibEventFactory.TicketInteraction expectedInteraction
    ) external  ReentrancyGuard eventExists(eventId) returns (bool success) {
        // Access Control: Check caller is the specific INSTALLED logic app for this event's TYPE
        bytes32 eventType = LibEventFactory.eventStorage().events[eventId].eventType;

        // Use internal helper inherited via iEventFactory -> iAppManagementInternal
        address expectedAppInstance = _getLogicAppInstance(eventType);
        require(msg.sender == expectedAppInstance, "EventFacet: Caller is not installed logic app for event type");

        // Call internal logic (inherited from iEventFactory) to perform checks + token interaction
        _verifyAndExecuteTokenInteraction(eventId, user, ticketId, amount, expectedInteraction);

        success = true;
    }


    // --- Event Management Functions ---

    /**
     * @notice Cancels an event. Only callable by creator or owner.
     */
    function cancelEvent(uint256 eventId, bytes32 refundMerkleRoot) external  onlyOwner { // Apply access control
        _cancelEvent(eventId, refundMerkleRoot); // Call internal logic
    }
    function endEvent(uint256 eventId) external  onlyOwner { // Apply access control
        _endEvent(eventId); // Call internal logic
    }

    /**
     * @notice Updates event URIs. Only callable by creator or owner.
     */
    function updateEventURIs(uint256 eventId, string calldata imageUri, string calldata metadataUri) external  onlyOwner { // Apply access control
        // Call internal functions which handle checks and emit events
        _setImageUri(eventId, imageUri);
        _setMetadataUri(eventId, metadataUri);
    }

    /**
     * @notice Sets the Merkle root for refunds after completion/cancellation. Only callable by creator or owner.
     */
    function setRefundMerkleRoot(uint256 eventId, bytes32 root) external  onlyOwner { // Apply access control
        _setRefundMerkleRoot(eventId, root); // Call internal logic
    }


    // --- Getter Functions (Implementing Updated IEventFacet) ---

    function getEventCoreInfo(uint256 eventId) 
        external view  eventExists(eventId)  
        returns (
            address creator,
            bytes32 eventType,
            // no logicContract
            LibEventFactory.EventStatus status
        )
    {
        LibEventFactory.EventDetail storage eventDetail = LibEventFactory.eventStorage().events[eventId];
        return (
            eventDetail.creator,
            eventDetail.eventType,
            eventDetail.status
        );
    }

    function getEventTimeInfo(uint256 eventId)
        external view  eventExists(eventId)
        returns (
            uint32 startTime,
            uint32 endTime
        )
    {
        LibEventFactory.EventDetail storage eventDetail = LibEventFactory.eventStorage().events[eventId];
        return (eventDetail.startTime, eventDetail.endTime);
    }

    function getEventCreator(uint256 eventId) external view returns (address creator_){
        LibEventFactory.EventDetail storage _event = LibEventFactory.getEventDetail( eventId );
        creator_ = _event.creator;
    }

    function getEventLimitInfo(uint256 eventId)
        external view  eventExists(eventId)
        returns (
            int64 minMemberLevel, // Corrected type
            uint256 maxEntriesPerUser
        )
    {
        LibEventFactory.EventDetail storage eventDetail = LibEventFactory.eventStorage().events[eventId];
        return (eventDetail.minMemberLevel, eventDetail.maxEntriesPerUser);
    }

    function getEventURIs(uint256 eventId)
        external view  eventExists(eventId)
        returns (
            string memory imageUri,
            string memory metadataUri
        )
    {
        LibEventFactory.EventDetail storage eventDetail = LibEventFactory.eventStorage().events[eventId];
        return (eventDetail.imageUri, eventDetail.metadataUri);
    }

    function getEventStateInfo(uint256 eventId)
        external view  eventExists(eventId)
        returns (
            // uint256 currentEntries, // Definition still pending
            bytes32 merkleRoot
        )
    {
        LibEventFactory.EventDetail storage eventDetail = LibEventFactory.eventStorage().events[eventId];
        // uint256 entries = 0; // Calculate if needed (e.g., maybe size of userEntries mapping? Complex)
        return (/* entries, */ eventDetail.merkleRoot);
    }

    function getEventTicketRequirements(uint256 eventId)
        external view  eventExists(eventId)
        returns (LibEventFactory.TicketRequirement[] memory)
    {
        // Read directly from LibEventFactory storage
        return LibEventFactory.eventStorage().eventTicketRequirements[eventId];
    }

    function getEventStatus(uint256 eventId)
        external view  eventExists(eventId)
        returns (LibEventFactory.EventStatus)
    {
        // Read directly from LibEventFactory storage
        return LibEventFactory.eventStorage().events[eventId].status;
    }



    // Note: _getERC1155Address() is implemented in iEventFactory and returns address(this)
    // Note: _getUserMemberLevel() is implemented in iEventFactory
    // Note: _getLogicAppInstance() is inherited via iEventFactory <- iAppManagementInternal
    // Note: _verifyAndExecuteTokenInteraction() is inherited from iEventFactory
    // Note: _createEvent(), _cancelEvent(), etc. are inherited from iEventFactory
}