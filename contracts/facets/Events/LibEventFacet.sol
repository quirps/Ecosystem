// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library LibEventFacet {
    // Unique storage slot for the EventFactory's state.
    // This hash must be unique across all libraries/facets to prevent storage collisions.
    // Example: keccak256("com.yourproject.eventfactory.storage")
    bytes32 constant EVENT_FACET_STORAGE_POSITION = keccak256("com.ecosystem.eventfactory.storage");

    enum EventStatus {
        Pending,   // Event created but not yet active (e.g., waiting for startTime)
        Active,    // Event is currently running
        Completed, // Event ended normally
        Cancelled  // Event ended prematurely (e.g., by creator or admin)
    }

    // Defines how a required ticket should be interacted with upon participation.
    enum TicketInteraction {
        Burn,    // Ticket is destroyed
        Hold,    // Ticket is transferred to the Ecosystem for temporary holding
        Stake,   // Ticket is staked (held with specific release conditions)
        RedeemToEvent // Ticket is "redeemed" by being associated with a specific event/app, not burned immediately.
                      // This implies a later "claim" or "refund" mechanism.
    }

    // Struct to define a specific ticket requirement for an event.
    struct TicketRequirement {
        uint256 ticketId;        // The ERC1155 token ID
        uint256 amount;          // The quantity required
        TicketInteraction interaction; // How the ticket should be handled
    }

    // Generic Event struct stored by the Ecosystem
    struct Event {
        uint256 eventId;            // Unique identifier for the event
        address creator;            // Address of the event creator
        address appLogic;           // Address of the specific app logic contract (e.g., PollApp)
        uint32 startTime;           // Unix timestamp when the event becomes active
        uint32 endTime;             // Unix timestamp when the event ends (or type(uint32).max for indefinite)
        EventStatus status;         // Current status of the event
        int64 minMemberLevel;     // Minimum member level required to participate (from TieredPermission)
        TicketRequirement[] ticketRequirements; // Array of tickets required for participation
        string metadataURI;         // URI for event metadata (e.g., IPFS hash to a JSON)
        string imageURI;            // URI for event image (e.g., IPFS hash)
        bytes appSpecificData;      // Optional: data passed to the app during creation (e.g., initial setup bytes)
    }

    // Parameters for creating a new event.
    // This is passed from the AppLogic contract to the EventFacet.
    struct CreateEventParams {
        address creator;            // Will be `msg.sender` from the calling App (e.g., PollApp)
        address appLogic;           // Will be `address(this)` from the calling App
        uint32 startTime;
        uint32 endTime;
        int64 minMemberLevel;
        TicketRequirement[] ticketRequirements;
        string metadataURI;
        string imageURI;
        bytes appSpecificData;
    }

    // Main storage struct for the EventFactory facet.
    // This struct defines the layout of storage for this facet in the Diamond.
    struct EventFacetStorage {
        uint256 nextEventId;                       // Counter for generating unique event IDs
        mapping(uint256 => Event) events;          // eventId => Event details
        mapping(address => bool) registeredApps;   // Whitelist of valid app logic contracts
        // Add a mapping to track held/staked tickets by event and user if needed
        // mapping(uint256 => mapping(address => mapping(uint256 => uint256))) public heldTickets; // eventId => user => ticketId => amount
    }

    // Function to access the unique storage for this facet.
    // This is how all functions in the facet will access state variables.
    function eventFacetStorage() internal pure returns (EventFacetStorage storage ds) {
        bytes32 position = EVENT_FACET_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}