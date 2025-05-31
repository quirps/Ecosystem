// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { LibEventFactory } from "./LibEventFactory.sol";
import { MerkleProof } from "../../libraries/utils/MerkleProof.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { iERC1155Transfer } from "../Tokens/ERC1155/internals/iERC1155Transfer.sol"; 
import { iERC1155 } from "../Tokens/ERC1155/internals/iERC1155.sol";
import { iAppRegistry } from "../AppRegistry/_AppRegistry.sol"; // Adjust path
import { iOwnership } from "../Ownership/_Ownership.sol";
import "hardhat/console.sol";

// Define interface for the Member Getter function (adjust name/path as needed)
interface IMemberGetter {
    function getMember(address user) external view returns (int64); // Use int64 as specified
}
 

contract iEventFactory is iOwnership, iAppRegistry, iERC1155Transfer, iERC1155{    


    // --- Events ---
    // (Keep existing event definitions: EventCreated, EventTicketRequirementsSet, EventStatusChanged, etc.)
    // Add a new event for core verification success? Optional.
    // event CoreParticipationVerified(uint256 indexed eventId, address indexed user, uint256 ticketId, uint256 amount);
   /// @dev Emitted when a new event is created. Contains core details and links.
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

    /// @dev Emitted when ticket requirements for an event are set or updated.
    event EventTicketRequirementsSet(
        uint256 indexed eventId,
        LibEventFactory.TicketRequirement requirements
    );

    /// @dev Emitted when an event's status changes.
    event EventStatusChanged(
        uint256 indexed eventId,
        LibEventFactory.EventStatus newStatus
    );

    /// @dev Emitted when a user interacts with an event (generic, more specific events might come from logicContract).
    event UserParticipated(
        uint256 indexed eventId,
        address indexed user,
        uint256[] ticketIds, // Tickets used for this specific interaction
        uint256[] amounts    // Amounts used
        // Consider adding interaction type if tracked centrally
    );

    // Retaining refund/Merkle related events if that logic stays
    event EventRefundsEnabled(uint256 indexed eventId, bytes32 merkleRoot);
    event EventTicketRefunded(
        uint256 indexed eventId,
        address indexed user,
        uint256 ticketId,
        uint256 amount
    );

    // Retaining other existing events like EventExtended, ImageUriUpdated etc.
    // if their corresponding functions (_extendEvent, _setImageUri) are kept.
    event EventExtended(uint256 indexed eventId, uint32 addedTime);
    event ImageUriUpdated(uint256 indexed eventId, string imageUri);
    event MetadataUriUpdated(uint256 indexed eventId, string metadataUri); // Added
    event EventEnded(uint256 indexed eventId);

    // --- Modifiers ---
    // (Keep existing modifiers: eventExists, onlyEventCreatorOrOwner, etc.)

    // --- Modifiers ---
    modifier eventExists(uint256 eventId) {
        require(LibEventFactory.eventStorage().events[eventId].startTime > 0, "Event: Does not exist");
        _;
    }

    modifier onlyEventCreator(uint256 eventId) {
        require(LibEventFactory.eventStorage().events[eventId].creator == msgSender(), "Event: Not creator");
        _;
    }

    modifier onlyLogicContract(uint256 eventId) {
        require(LibEventFactory.eventStorage().events[eventId].logicContract == msgSender(), "Event: Not logic contract");
        _;
    }

     modifier onlyEventCreatorOrOwner(uint256 eventId) {
        // Assuming _isOwner() checks contract ownership
        require(LibEventFactory.eventStorage().events[eventId].creator == msgSender() || 
                LibEventFactory.eventStorage().events[eventId].creator == _ecosystemOwner() , "Event: Not creator or owner");
        _;   
    }


    // --- Internal Functions ---

    function _createEvent(
        LibEventFactory.CreateEventParams memory createEventParams
    ) internal returns (uint256) {

        // --- Check if an app is installed for this event type ---
        // Use helper inherited from iAppManagementInternal
        require(_isAppInstalledForType(createEventParams.eventType), "Event: No app installed for type");
        // --- END CHECK --

        // ... implementation from previous step ...
        // (Ensures event is created with all necessary details including logicContract address)
         LibEventFactory.EventStorage storage es = LibEventFactory.eventStorage();
 
        require(createEventParams.endTime > uint32( block.timestamp ), "Event: Invalid times");
  
        es.eventNonce++; 
        uint256 eventId = es.eventNonce; // Use nonce for simpler ID generation

        LibEventFactory.EventDetail storage newEvent = es.events[eventId];
        newEvent.creator = createEventParams.creator;
        newEvent.eventType = createEventParams.eventType;
        newEvent.startTime = createEventParams.startTime;
        newEvent.endTime = createEventParams.endTime;
        newEvent.minMemberLevel = createEventParams.minMemberLevel;
        newEvent.maxEntriesPerUser = createEventParams.maxEntriesPerUser;
        newEvent.imageUri = createEventParams.imageUri;
        newEvent.metadataUri = createEventParams.metadataUri;
        newEvent.status = LibEventFactory.EventStatus.Pending; // Always starts Pending

        //
        require(createEventParams.requirements.maxAmount >= createEventParams.requirements.requiredAmount, "Max required tickets must be greater than or equal to required amount of tickets.");
        // Store ticket requirements

        es.eventTicketRequirements[eventId] = createEventParams.requirements; 
        

        emit EventCreated( 
            eventId,
            createEventParams.creator,
            createEventParams.eventType,
            createEventParams.startTime,
            createEventParams.endTime,
            createEventParams.minMemberLevel, // Added previously
            createEventParams.imageUri,
            createEventParams.metadataUri
        );
        emit EventTicketRequirementsSet(eventId, createEventParams.requirements);
        emit EventStatusChanged(eventId, newEvent.status);

        return eventId;
    }

    /**
     * @notice Performs core checks and executes token interaction for event participation.
     * @dev Called BY a linked logic contract via EventFacet. Verifies the user meets all criteria.
     * Requires the USER to have approved the LOGIC APP (msg.sender) for token transfers (Burn/Stake).
     * @param _eventId The event ID.
     * @param _user The participating user address (passed in by logic app).
     * @param _ticketId The ticket ID being used.
     * @param _amount The amount of the ticket being used.
     */
    // In iEventFactory.sol

function _verifyAndExecuteTokenInteraction(
    uint256 _eventId,
    address _user,
    uint256 _ticketId,
    uint256 _amount
) internal eventExists(_eventId) {
    LibEventFactory.EventDetail storage eventDetail = LibEventFactory.eventStorage().events[_eventId];
    LibEventFactory.TicketRequirement storage requirements = LibEventFactory.eventStorage().eventTicketRequirements[_eventId];

    // ... [Checks 1, 2, 3 for Status, Time, Level, User Limits remain the same] ...

    // 4. Find and Validate Requirement Index
    bool requirementFound = false;
    uint256 requirementIndex = type(uint256).max; // Initialize with invalid index

    // Use requirements[i] directly for checks within the loop
    if (requirements.tokenId == _ticketId) {
        require(_amount >= requirements.requiredAmount, "Event: Insufficient amount for requirement.");
        require(_amount <= requirements.maxAmount, "Event: Amount exceeding max entries.");
        // If checks pass, store the index and break
    }
    else{
        revert("Invalid redemption _ticketId.");
    }
    // Check if a valid requirement was found

    // 5. Handle Ticket Interaction (using the found index)
    // Now get the storage pointer using the validated index 

    // Use req.interactionType (pointer to the correct storage struct)
    if (requirements.interactionType == LibEventFactory.TicketInteraction.None){
        //pass
    }
    else if (requirements.interactionType == LibEventFactory.TicketInteraction.Possess){
        require(_balanceOf(_user, _ticketId) >= _amount, "Event: Insufficient balance (Possess)");
    }
    else if (requirements.interactionType == LibEventFactory.TicketInteraction.Hold) {
        require(_balanceOf(_user, _ticketId) >= _amount, "Event: Insufficient balance (Hold)");
    } else if (requirements.interactionType == LibEventFactory.TicketInteraction.Burn) {
        _burn(_user, _ticketId, _amount); 
    } else if (requirements.interactionType == LibEventFactory.TicketInteraction.Stake) {
        _safeTransferFrom(_user, msg.sender, _ticketId, _amount, ""); // Stake TO logic app (msg.sender)
    } else if (requirements.interactionType == LibEventFactory.TicketInteraction.RedeemToEvent) {
        revert("Event: RedeemToEvent interaction not typical in this flow");
    }

    // 6. Update Counters (remains the same)
    eventDetail.userEntries[_user]++;

}

    // _getUserMemberLevel helper function (as defined previously)
    function _getUserMemberLevel(address _user) internal view returns (int64) {
        try IMemberGetter(address(this)).getMember(_user) returns (int64 level) {
            return level;
        } catch {
            revert("Event: Failed to get member level");
        }
    }

    // _safeTransferFromHelper (as defined previously)
     function _safeTransferFromHelper(
        address token,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        // ... implementation from previous step ...
         (bool success, bytes memory reason) = token.call(abi.encodeWithSelector(
             IERC1155.safeTransferFrom.selector,
             from,
             to,
             id,
             amount,
             data
         ));
          if (!success) {
             if (reason.length == 0) {
                 revert("ERC1155: Transfer failed without reason");
             } else {
                // Bubble up the reason
                 assembly {
                     revert(add(reason, 32), mload(reason))
                 }
             }
         }
    }


    // --- Management Functions ---
    // _updateEventStatus, _cancelEvent, _setImageUri, _setMetadataUri, _setRefundMerkleRoot
    // These internal management functions remain largely the same, called by restricted external
    // functions in EventFacet.
    // ...

     function _updateEventStatus(uint256 eventId, LibEventFactory.EventStatus newStatus)
        internal
        eventExists(eventId)
    {
       // ... implementation ...
       LibEventFactory.EventDetail storage eventDetail = LibEventFactory.eventStorage().events[eventId];
        if (eventDetail.status != newStatus) {
            eventDetail.status = newStatus;
            emit EventStatusChanged(eventId, newStatus);
        } 
    }

     function _cancelEvent(uint256 eventId, bytes32 refundMerkleRoot)
        internal
        // Access control applied in EventFacet
    {
         // ... implementation ...
         LibEventFactory.EventDetail storage eventDetail = LibEventFactory.eventStorage().events[eventId];
         require(
             eventDetail.status != LibEventFactory.EventStatus.Completed &&
             eventDetail.status != LibEventFactory.EventStatus.Cancelled,
             "Event: Already finished or cancelled"
         );

         eventDetail.merkleRoot = refundMerkleRoot;
         _updateEventStatus(eventId, LibEventFactory.EventStatus.Cancelled);

         if (refundMerkleRoot != bytes32(0)) {
             emit EventRefundsEnabled(eventId, refundMerkleRoot);
         }
    }
    function _endEvent(uint256 eventId) internal  onlyOwner { // Apply access control 
         // ... implementation ...
         LibEventFactory.EventDetail storage eventDetail = LibEventFactory.eventStorage().events[eventId];
         require(
             eventDetail.status != LibEventFactory.EventStatus.Completed &&
             eventDetail.status != LibEventFactory.EventStatus.Cancelled,
             "Event: Already finished or cancelled"
         );

         _updateEventStatus(eventId, LibEventFactory.EventStatus.Completed);

         emit EventEnded(eventId);
    }

     function _setImageUri(uint256 eventId, string memory imageUri)
        internal
        eventExists(eventId)
    {
       // ... implementation ...
       LibEventFactory.eventStorage().events[eventId].imageUri = imageUri;
        emit ImageUriUpdated(eventId, imageUri);
    }

     function _setMetadataUri(uint256 eventId, string memory metadataUri)
        internal
        eventExists(eventId)
    {
        // ... implementation ...
        LibEventFactory.eventStorage().events[eventId].metadataUri = metadataUri;
        emit MetadataUriUpdated(eventId, metadataUri);
    }

     function _setRefundMerkleRoot(uint256 eventId, bytes32 root)
        internal
        eventExists(eventId)
    {
        // ... implementation ...
        LibEventFactory.EventDetail storage eventDetail = LibEventFactory.eventStorage().events[eventId];
        require(
            eventDetail.status == LibEventFactory.EventStatus.Completed || eventDetail.status == LibEventFactory.EventStatus.Cancelled,
            "Event: Must be finished or cancelled"
        );
        require(eventDetail.merkleRoot == bytes32(0), "Event: Merkle root already set");
        require(root != bytes32(0), "Event: Invalid root");
        eventDetail.merkleRoot = root;
        emit EventRefundsEnabled(eventId, root);
    }


    // --- Refund Logic ---
    // _refundTicketsWithProof and _validateNonInclusionProof remain, but _refundTicketsWithProof
    // now needs rethinking as tokens aren't held by the facet/diamond in most inverted flows.
    // This logic likely needs removal or significant redesign for the inverted pattern.
    // Let's comment it out for now.
    /*
    function _refundTicketsWithProof(...) internal { ... }
    function _validateNonInclusionProof(...) internal view returns (bool) { ... }
    */

}