// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { LibEventFactory } from "./LibEventFactory.sol";

interface IEventFacet {

    // --- Events ---
    // (Keep EventCreated, EventTicketRequirementsSet, EventStatusChanged, etc.)
    // (UserParticipated event is no longer emitted from here)

        event EventCreated(
        uint256 indexed eventId,
        address indexed creator,
        bytes32 indexed eventType,
        uint32 startTime,
        uint32 endTime,
        int64 minMemberLevel, 
        string imageUri,
        string metadataUri // Added
        // Removed min/max entries from event, handled by logic or core checks
    );
    
    event EventTicketRequirementsSet(uint256 indexed eventId, LibEventFactory.TicketRequirement requirements);
    event EventStatusChanged(uint256 indexed eventId, LibEventFactory.EventStatus newStatus);
    event EventRefundsEnabled(uint256 indexed eventId, bytes32 merkleRoot);
    event EventTicketRefunded(uint256 indexed eventId, address indexed user, uint256 ticketId, uint256 amount); // Keep if refund logic remains
    event EventExtended(uint256 indexed eventId, uint32 addedTime); // Keep if needed
    event ImageUriUpdated(uint256 indexed eventId, string imageUri);
    event MetadataUriUpdated(uint256 indexed eventId, string metadataUri);


    // --- External Functions ---

    // Create Event (remains the same signature as before)
    function createEvent(
        LibEventFactory.CreateEventParams calldata createEventParams
    ) external returns (uint256 eventId);

    /**
     * @notice Verifies participation criteria and executes required token interaction.
     * @dev Called BY logic apps to ensure core rules are met before they proceed.
     * Requires the user to have approved the calling logic app for token transfers.
     * @param eventId The event ID.
     * @param user The participating user address.
     * @param ticketId The ticket ID being used.
     * @param amount The amount of the ticket being used.
     * @return success Boolean indicating if core verification and interaction succeeded.
     */
    function verifyAndProcessParticipation(
        uint256 eventId,
        address user,
        uint256 ticketId,
        uint256 amount
    ) external returns (bool success);


    // --- Event Management Functions ---
    // (Keep cancelEvent, updateEventURIs, setRefundMerkleRoot signatures as before)
    function cancelEvent(uint256 eventId, bytes32 refundMerkleRoot) external;
    function endEvent(uint256 eventId) external;
    function updateEventURIs(uint256 eventId, string calldata imageUri, string calldata metadataUri) external;
    function setRefundMerkleRoot(uint256 eventId, bytes32 root) external;


    // --- Refund Functions ---
    // Keep claimRefundWithProof signature if logic remains, otherwise remove.
    // function claimRefundWithProof(...) external;


    // --- Getter Functions ---
    // (Keep getEventDetails, getEventTicketRequirements, getEventStatus, getLogicContract signatures as before)
     function getEventDetails(uint256 eventId) external view returns (
        address creator,
        bytes32 eventType,
        address logicContract,
        uint32 startTime,
        uint32 endTime,
        uint64 minMemberLevel,
        uint256 maxEntriesPerUser,
        string memory imageUri,
        string memory metadataUri,
        LibEventFactory.EventStatus status,
        uint256 currentEntries, // Revisit definition if needed
        bytes32 merkleRoot
    );
   
    // In IEventFacet.sol
    function getEventCreator(uint256 eventId) external view returns (address creator);


    function getEventCoreInfo(uint256 eventId) external view returns (
        address creator,
        bytes32 eventType,
        address logicContract,
        LibEventFactory.EventStatus status
    );

    function getEventTimeInfo(uint256 eventId) external view returns (
        uint32 startTime,
        uint32 endTime
    );

    function getEventLimitInfo(uint256 eventId) external view returns (
        int64 minMemberLevel,      // Corrected type
        uint256 maxEntriesPerUser
    );

    function getEventURIs(uint256 eventId) external view returns (
        string memory imageUri, 
        string memory metadataUri
    );

    function getEventStateInfo(uint256 eventId) external view returns (
        // uint256 currentEntries, // Decide how/if to expose this
        bytes32 merkleRoot
    );

    // Keep getEventTicketRequirements, getEventStatus, getLogicContract as they are okay
     function getEventTicketRequirements(uint256 eventId) external view returns (LibEventFactory.TicketRequirement[] memory);
     function getEventStatus(uint256 eventId) external view returns (LibEventFactory.EventStatus);
     function getLogicContract(uint256 eventId) external view returns (address);


    // ... other functions/events ...


}