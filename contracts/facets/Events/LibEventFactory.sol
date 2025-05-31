// LibEventStorage.sol
pragma solidity ^0.8.0;

import "../Tokens/ERC1155/interfaces/IERC1155Transfer.sol";  

library LibEventFactory {
    bytes32 constant STORAGE_POSITION = keccak256("diamond.storage.EventFactory");

    struct TicketDetail {
        uint256 minAmount;
        uint256 maxAmount;
    }
 struct CreateEventParams {
        address creator;
        bytes32 eventType;
        uint32 startTime;
        uint32 endTime;
        int64 minMemberLevel;
        uint256 maxEntriesPerUser;
        string imageUri;
        string metadataUri;
        TicketRequirement requirements; // Assuming TicketRequirement is defined elsewhere
    }
     enum EventStatus {
        Pending,        // Created, before startTime
        RegistrationOpen, // After startTime, before participation cutoff (if any)
        InProgress,     // Event is actively running (e.g., poll open, tournament ongoing)
        ProcessingResults, // Event ended, results being calculated/finalized (e.g., VRF request pending)
        Completed,      // Event finished, results available, rewards claimable (if any)
        Cancelled,      // Terminated prematurely by owner (potentially allowing refunds)
        Expired         // Reached endTime without completion/cancellation (grace period over)
    }
  enum TicketInteraction {
        Hold,           // User must temporarily transfer the ticket requirement 
        Burn,           // Ticket is burned upon participation
        Stake,          // Ticket is transferred to the logicContract for duration
        RedeemToEvent,   // Ticket is transferred to this core Event contract (like original _redeemTickets)
        None, // No interaction needed
        Possess // Must Possess the ticket requirement
    }

       // Store requirements per ticket for an event
    struct TicketRequirement {
        uint256 tokenId;
        TicketInteraction interactionType;
        uint256 requiredAmount; // Amount needed per interaction/entry
        uint256 maxAmount; // Specific limit for this ticket type? (Optional)
    }

      struct EventDetail {
        uint32 startTime;
        uint32 endTime;
        uint256 maxEntries; // Overall event entry limit (if applicable)
        string imageUri;
        string metadataUri; // Link to off-chain JSON for richer details (rules, description)
        EventStatus status;
        bytes32 eventType; // Identifier for the type of event (e.g., keccak256("POLL_V1"))
        address logicContract; // Address of the specific app logic contract
        uint256 currentEntries; // Counter (definition depends on event type - unique users? total tickets?)
        bytes32 merkleRoot; // For refunds or allowlists, as needed
        address creator; // Store creator for potential reference
        int64 minMemberLevel;

        // Mapping: eventId => requirementIndex => TicketRequirement
        // We'll store requirements in an array within the event mapping in EventStorage instead
        // uint256[] ticketRequirementIndices; // Indices pointing to a global requirements array? Or store directly?

        // Mapping to track user participation details, potentially moved to logicContract
        // mapping(address => mapping(uint256 => uint256)) ticketsRedeemed; // User => TokenId => Amount
        mapping(address => uint256) userEntries; // Tracks entries per user for maxEntriesPerUser check
        uint256 maxEntriesPerUser; // Global limit per user for the event

        // Min entries concept might be better handled by logicContract's activation rules
        // uint256 minEntries;
    }
      struct EventStorage {
        // mapping eventId => EventDetail
        mapping(uint256 => EventDetail) events;
        // Store requirements per event
        mapping(uint256 => TicketRequirement) eventTicketRequirements;
        // ... potentially other storage ...
        uint256 eventNonce; // Simple incrementing nonce for unique ID generation
    }

    function eventStorage() internal pure returns (EventStorage storage es) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }

    function getEventDetail(uint256 eventId) internal view returns (EventDetail storage) {
        EventStorage storage es = eventStorage();
        require( es.events[eventId].endTime != 0 , "Event does not exist");
        return es.events[eventId];
    }



    function getRedeemedTickets(uint256 eventId, address user) internal view returns (uint256 ) {
        EventDetail storage _eventDetail = getEventDetail(eventId);
        return _eventDetail.userEntries[ user ]; 
    }

    function getMerkleRoot(uint256 eventId) internal view returns (bytes32) {
        return getEventDetail(eventId).merkleRoot;
    }

    function getEventTimes(uint256 eventId) internal view returns (uint32 startTime, uint32 endTime) {
        EventDetail storage es = getEventDetail(eventId);
        return (es.startTime, es.endTime);
    }

    function getEventEntries(uint256 eventId) internal view returns (uint256 maxEntries, uint256 currentEntries) {
        EventDetail storage es = getEventDetail(eventId);
        return ( es.maxEntries, es.currentEntries); 
    }

    function getEventImageUri(uint256 eventId) internal view returns (string memory) {
        EventDetail storage es = getEventDetail(eventId);
        return es.imageUri; 
    }

    function getEventStatus(uint256 eventId) internal view returns (EventStatus) {
        EventDetail storage es = getEventDetail(eventId);
        return es.status;
    }
}
