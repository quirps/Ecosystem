// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { LibEventFacet } from "./LibEventFacet.sol";
import { IEventFacet, IERC1155, ITieredPermission } from "./IEventFacet.sol"; // Import its own interface and dependencies
import { iMembers } from "../MemberLevel/_Members.sol";  //imports iOwnership
import {iERC1155Transfer} from "../Tokens/ERC1155/internals/iERC1155Transfer.sol";
import "hardhat/console.sol";
/**
 * @title EventFacet
 * @notice Manages generic event data and participation within the Ecosystem Diamond.
 * @dev This facet directly interacts with the ERC1155 and TieredPermission systems.
 * All functions are designed to be called by external App Logic Contracts,
 * not via delegatecall from other facets (except potentially internal helper functions).
 */
contract EventFacet is IEventFacet, iMembers, iERC1155Transfer{ 
    // --- Error Definitions ---
    error ZeroAddress();
    error InvalidRegistryAddress(address passedAddress);
    error InvalidEventId(uint256 eventId);
    error UnauthorizedApp(address caller);
    error EventNotActive(uint256 eventId);
    error EventAlreadyEnded(uint256 eventId);
    error EventAlreadyCancelled(uint256 eventId);
    error InsufficientMemberLevel(address participant, int64 required, int64 actual);
    error InsufficientTickets(address participant, uint256 ticketId, uint256 required, uint256 actual);
    error UnexpectedTicketInteraction(LibEventFacet.TicketInteraction interactionType);
    error OnlyDiamondOwner(address caller); // For admin functions like registerApp

    // --- Internal Libraries for shared storage access ---
    using LibEventFacet for LibEventFacet.EventFacetStorage;
    address immutable REGISTRY_ADDRESS;
    // --- Constructor (Facets typically don't have constructors if they rely solely on Diamond Storage) ---
    // The Diamond will initialize storage via its DiamondCut function.

    // --- Core Functions Implementation ---
    constructor(address _registryAddress){
        REGISTRY_ADDRESS = _registryAddress;
    }
    /**
     * @inheritdoc IEventFacet
     */
    function createEvent(LibEventFacet.CreateEventParams memory params) external returns (uint256 eventId_) {
        LibEventFacet.EventFacetStorage storage ds = LibEventFacet.eventFacetStorage();

        // 1. Basic Validations
        if (params.appLogic == address(0)) revert ZeroAddress();
        if (params.creator == address(0)) revert ZeroAddress();
        // Ensure the calling app is a registered app for event creation
        if (msg.sender != params.appLogic) revert UnauthorizedApp(msg.sender); // Ensure the app passes itself as the appLogic
        if (!ds.registeredApps[params.appLogic]) revert UnauthorizedApp(params.appLogic);

        // 2. Generate new eventId
        eventId_ = ds.nextEventId;
        ds.nextEventId++;

        // 3. Store event details
        LibEventFacet.Event storage newEvent = ds.events[eventId_];
        newEvent.eventId = eventId_;
        newEvent.creator = params.creator;
        newEvent.appLogic = params.appLogic;
        newEvent.startTime = params.startTime;
        newEvent.endTime = params.endTime;
        newEvent.status = params.startTime > block.timestamp ? LibEventFacet.EventStatus.Pending : LibEventFacet.EventStatus.Active; // Initial status based on startTime
        newEvent.minMemberLevel = params.minMemberLevel;
        newEvent.ticketRequirements = params.ticketRequirements; // Copy array
        newEvent.metadataURI = params.metadataURI;
        newEvent.imageURI = params.imageURI;
        newEvent.appSpecificData = params.appSpecificData;

        // 4. Emit event
        emit EventCreated(
            eventId_,
            newEvent.creator,
            newEvent.appLogic,
            newEvent.status,
            newEvent.startTime,
            newEvent.endTime,
            newEvent.metadataURI
        );
    }

    /**
     * @inheritdoc IEventFacet
     */
    function verifyAndProcessParticipation(
        uint256 eventId,
        address participant,
        uint256 ticketId,
        uint256 amount
    ) external returns (bool success) {
        LibEventFacet.EventFacetStorage storage ds = LibEventFacet.eventFacetStorage();
        LibEventFacet.Event storage event_ = ds.events[eventId];
        // 1. Basic Validations
        if (event_.appLogic == address(0)) revert InvalidEventId(eventId);
        // Ensure only the registered app for this event can call this function
        if (msg.sender != event_.appLogic) revert UnauthorizedApp(msg.sender);
        // Check if event is active (optional, could also allow participation during Pending if desired by event type)
        // For polling, it must be active.
        if (event_.status != LibEventFacet.EventStatus.Active) revert EventNotActive(eventId);
        // 2. Check Member Level (via ITieredPermission interface)
        if (event_.minMemberLevel > 0) {
            int64 participantLevel = _getMemberLevel(participant); // Assuming TieredPermission is owned/integrated with the Diamond
            if (participantLevel < event_.minMemberLevel) {
                revert InsufficientMemberLevel(participant, event_.minMemberLevel, participantLevel); 
            }
        }
        // 3. Process Ticket Requirements
        bool ticketFoundAndProcessed = false;
        uint256 ticketRequirementLength = event_.ticketRequirements.length;
        for (uint i = 0; i < ticketRequirementLength; i++) {
            LibEventFacet.TicketRequirement storage req = event_.ticketRequirements[i];
            if (req.ticketId == ticketId && req.amount == amount) { // Match the specific ticket being used
                uint256 participantBalance = _balanceOf(participant, ticketId);
                if (participantBalance < amount) {
                    revert InsufficientTickets(participant, ticketId, amount, participantBalance);
                }

                // Execute the defined interaction
                if (req.interaction == LibEventFacet.TicketInteraction.Burn) {
                    // msg.sender for safeTransferFrom must be the participant
                    _safeTransferFrom(participant, address(this), ticketId, amount, ""); // Transfer to this (Diamond) contract to burn
                } else if (req.interaction == LibEventFacet.TicketInteraction.Hold || req.interaction == LibEventFacet.TicketInteraction.Stake) {
                    // Transfer to the Diamond address itself for holding/staking
                    _safeTransferFrom(participant, address(this), ticketId, amount, "");
                    // NOTE: If holding/staking is complex, you'd need dedicated functions
                    // here or in another facet to manage specific `heldTickets` mappings and release logic.
                    // For now, `address(this)` means the Diamond holds them.
                } else if (req.interaction == LibEventFacet.TicketInteraction.RedeemToEvent) {
                    // No direct transfer or burn here. The ticket is "marked" as used for this event.
                    // The App Logic (e.g., TalkShowSchedulerApp) is responsible for internal tracking
                    // and eventual claim/refund logic. The Ecosystem only verifies its existence and validity.
                    // For now, we'll assume the ERC1155 check is enough, and actual 'redemption' is app-specific.
                    // If the Ecosystem needs to track "redeemed" tickets centrally, another mapping would be needed.
                } else {
                    revert UnexpectedTicketInteraction(req.interaction);
                }
                ticketFoundAndProcessed = true;
                break; // Only process one matching ticket requirement for simplicity.
                       // If multiple tickets can be used, this logic needs adjustment.
            }
        }
        if ( ticketRequirementLength > 0 && !ticketFoundAndProcessed ) {
            // No matching ticket requirement found for the provided ticketId/amount
            revert InsufficientTickets(participant, ticketId, amount, 0); // Revert with generic insufficient, or a more specific error
        }


        // 4. Emit event
        emit ParticipantVerified(eventId, participant, ticketId, amount); // Emit for the first matched ticket

        success = true;
    }

    /**
     * @inheritdoc IEventFacet
     */
    function endEvent(uint256 eventId) external {
        LibEventFacet.EventFacetStorage storage ds = LibEventFacet.eventFacetStorage();
        LibEventFacet.Event storage event_ = ds.events[eventId];

        // 1. Basic Validations
        if (event_.appLogic == address(0)) revert InvalidEventId(eventId);
        if (msg.sender != event_.appLogic) revert UnauthorizedApp(msg.sender); // Only the app that owns the event can end it
        if (event_.status == LibEventFacet.EventStatus.Completed) revert EventAlreadyEnded(eventId);
        if (event_.status == LibEventFacet.EventStatus.Cancelled) revert EventAlreadyCancelled(eventId);

        // 2. Update status
        LibEventFacet.EventStatus oldStatus = event_.status;
        event_.status = LibEventFacet.EventStatus.Completed;

        // 3. Emit event
        emit EventStatusUpdated(eventId, oldStatus, LibEventFacet.EventStatus.Completed, msg.sender);
    }

    /**
     * @inheritdoc IEventFacet
     */
    function cancelEvent(uint256 eventId) external {
        // Only the Diamond owner (governance) can cancel events globally
        isEcosystemOwnerVerification();

        LibEventFacet.EventFacetStorage storage ds = LibEventFacet.eventFacetStorage();
        LibEventFacet.Event storage event_ = ds.events[eventId];

        // 1. Basic Validations
        if (event_.appLogic == address(0)) revert InvalidEventId(eventId);
        if (event_.status == LibEventFacet.EventStatus.Completed) revert EventAlreadyEnded(eventId);
        if (event_.status == LibEventFacet.EventStatus.Cancelled) revert EventAlreadyCancelled(eventId);

        // 2. Update status
        LibEventFacet.EventStatus oldStatus = event_.status;
        event_.status = LibEventFacet.EventStatus.Cancelled;

        // 3. Emit event
        emit EventStatusUpdated(eventId, oldStatus, LibEventFacet.EventStatus.Cancelled, msg.sender);
    }

    // --- Read Functions Implementation ---

    /**
     * @inheritdoc IEventFacet
     */
    function getEvent(uint256 eventId) external view returns (LibEventFacet.Event memory eventDetails) {
        LibEventFacet.EventFacetStorage storage ds = LibEventFacet.eventFacetStorage();
        eventDetails = ds.events[eventId];
        if (eventDetails.appLogic == address(0)) {
            // If appLogic is address(0), it means the eventId does not exist
            // or the event struct is not initialized, so we revert.
            revert InvalidEventId(eventId);
        }
    }

    /**
     * @inheritdoc IEventFacet
     */
    function getEventCreator(uint256 eventId) external view returns (address creator) {
        LibEventFacet.EventFacetStorage storage ds = LibEventFacet.eventFacetStorage();
        address _creator = ds.events[eventId].creator;
        if (_creator == address(0)) revert InvalidEventId(eventId);
        return _creator;
    }

    /**
     * @inheritdoc IEventFacet
     */
    function getEventStatus(uint256 eventId) external view returns (LibEventFacet.EventStatus status) {
        LibEventFacet.EventFacetStorage storage ds = LibEventFacet.eventFacetStorage();
        LibEventFacet.Event storage event_ = ds.events[eventId];
        if (event_.appLogic == address(0)) revert InvalidEventId(eventId);

        // Auto-update status if endTime has passed and it's still active/pending
        if (event_.status == LibEventFacet.EventStatus.Active && block.timestamp >= event_.endTime && event_.endTime != type(uint32).max) {
             return LibEventFacet.EventStatus.Completed; // Implied end due to time
        }
        if (event_.status == LibEventFacet.EventStatus.Pending && block.timestamp >= event_.startTime) {
             return LibEventFacet.EventStatus.Active; // Implied start due to time
        }
        return event_.status;
    }


    /**
     * @inheritdoc IEventFacet
     */
    function isRegisteredApp(address appAddress) external view returns (bool isRegistered) {
        LibEventFacet.EventFacetStorage storage ds = LibEventFacet.eventFacetStorage();
        return ds.registeredApps[appAddress];
    }

    // --- Admin Functions Implementation ---

    /**
     * @inheritdoc IEventFacet
     */
    function registerApp(address appAddress, bool isRegistered) external {
        // This function should be callable only by the Diamond's owner/governance.
        // Assuming LibDiamond.sol provides `diamondStorage().owner()` to get the diamond's owner.
        //Ecosystem owner checked from the calling method, which is restricted to THE AppRegistry contract
        if (appAddress == address(0)) revert ZeroAddress();
        if (msgSender() != REGISTRY_ADDRESS) revert InvalidRegistryAddress( msgSender() );
        LibEventFacet.EventFacetStorage storage ds = LibEventFacet.eventFacetStorage();
        ds.registeredApps[appAddress] = isRegistered;
    }
}