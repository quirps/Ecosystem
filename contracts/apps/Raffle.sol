// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.19;

// // No longer implements IEventLogic directly in the old way
// // Import interfaces needed for VRF and EventFacet interaction
// import { VRFCoordinatorV2Interface } from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
// import { VRFConsumerBaseV2 } from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol"; 
// import "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol"; // Purely here for the purpose of generating its artifact for testing
// import { IEventFacet } from "../facets/Events/IEventFactory.sol"; // Adjust path as needed  
// import { LibEventFactory } from "../facets/Events/LibEventFactory.sol"; // Needed for enum 
// // Access control (e.g., Ownable)
// import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
// // Remove SafeMath if not used (modulo is native)
// // import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";

// contract RaffleApp is VRFConsumerBaseV2, Ownable {
//     // Remove SafeMath using directive if removed import
//     // using SafeMath for uint256;

//     // --- State Variables ---

//     // Chainlink VRF configuration (remains the same)
//     // Make Facet Address immutable, set in constructor
//     address public immutable EVENT_FACET_ADDRESS;
//     // VRF Coordinator and KeyHash likely immutable too
//     VRFCoordinatorV2Interface public immutable VRF_COORDINATOR;
//     bytes32 public immutable s_keyHash;
//     uint32 public immutable s_callbackGasLimit; 
//     // Subscription ID MUST be mutable now
//     uint64 public s_subscriptionId; 
//     uint16 internal constant REQUEST_CONFIRMATIONS = 3;
//     uint32 internal constant NUM_WORDS = 1;


//     // Raffle state per eventId (remains the same)
//     mapping(uint256 => address[]) public participants;
//     mapping(uint256 => address) public winner;
//     mapping(uint256 => uint256) public randomnessRequestId;
//     mapping(uint256 => bool) public isWinnerDrawn;

//     // Mapping VRF request ID back to our event ID (remains the same)
//     mapping(uint256 => uint256) internal requestIdToEventId;

//     // --- Events --- (remain the same)
//     event EnteredRaffle(uint256 indexed eventId, address indexed user);
//     event RandomnessRequested(uint256 indexed eventId, uint256 indexed requestId, address requester);
//     event WinnerDrawn(uint256 indexed eventId, address indexed winner, uint256 indexed requestId);

//     // --- Constructor --- (remains the same)

//     constructor(
//         address _eventFacetAddress, // Parent Diamond Proxy address
//         address _vrfCoordinator,
//         uint64 _initialSubscriptionId, // Can be 0 if setter is used
//         bytes32 _keyHash,
//         uint32 _callbackGasLimit
//     ) VRFConsumerBaseV2(_vrfCoordinator) Ownable(msg.sender) {
//         require(_eventFacetAddress != address(0), "Raffle: Invalid Event Facet");
//         require(_vrfCoordinator != address(0), "Raffle: Invalid VRF Coordinator");
//         // Removed subId != 0 check
 
//         EVENT_FACET_ADDRESS = _eventFacetAddress; // Set immutable parent
//         VRF_COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
//         s_subscriptionId = _initialSubscriptionId; // Set initial (maybe 0)
//         s_keyHash = _keyHash;
//         s_callbackGasLimit = _callbackGasLimit;
//     }

//     // --- REMOVED `participate` function ---
//     // function participate(...) external override { ... } // REMOVED
//   function setSubscriptionId(uint64 _subId) external onlyOwner {
//         require(_subId != 0, "Raffle: Subscription ID cannot be 0");
//         s_subscriptionId = _subId;
//         // emit SubscriptionIdSet(_subId); // Optional event
//     } 
//     // --- NEW User Entry Point ---

//     /**
//      * @notice Allows a user to enter a specific raffle event.
//      * @dev User calls this function directly. It verifies participation rules and
//      * token interaction via the EventFacet before recording the entry here.
//      * @param eventId The ID of the raffle event to enter.
//      * @param ticketId The ID of the ERC1155 ticket required for entry.
//      * @param amount The amount of the ticket required (must match event config).
//      */
//     function enterRaffle(uint256 eventId, uint256 ticketId, uint256 amount) external {
//         // 1. Define the expected interaction type for raffle entry (e.g., Burn)
//         // This could potentially be fetched from EventFacet if requirements were complex,
//         // but for a simple raffle, Burn is typical.
//         LibEventFactory.TicketInteraction expectedInteraction = LibEventFactory.TicketInteraction.Burn;

//         // 2. Call the EventFacet to verify/process core participation
//         // User (msg.sender) must have approved THIS RaffleApp contract address
//         // for the specified ticketId and amount if interaction is Burn or Stake.
//         IEventFacet eventFacet = IEventFacet(EVENT_FACET_ADDRESS);
//         bool success = eventFacet.verifyAndProcessParticipation( 
//             eventId,
//             msg.sender, // The user calling enterRaffle
//             ticketId,
//             amount 
//         );

//         // 3. Check Facet Verification Result
//         require(success, "Raffle: Core participation check failed"); // Revert if facet call failed or returned false

//         // 4. Check Raffle Status Locally (redundant check is okay)
//         require(!isWinnerDrawn[eventId], "Raffle: Winner already drawn");

//         // 5. Record Participant Locally
//         participants[eventId].push(msg.sender);

//         // 6. Emit Event
//         emit EnteredRaffle(eventId, msg.sender);
//     }


//     // --- Winner Drawing Logic --- (Remains mostly the same)

//     /**
//      * @notice Initiates the process to draw a winner for a completed raffle.
//      * @dev Can only be called by the creator of the event (fetched from EventFacet).
//      */
//     function drawWinner(uint256 eventId) external {
//     // 1. Fetch Event Details from Facet using the NEW specific getters
//     IEventFacet eventFacet = IEventFacet(EVENT_FACET_ADDRESS);

//     // --- Call new getters ---
//     // Get creator and status 
//     (address creator,,, LibEventFactory.EventStatus status) = eventFacet.getEventCoreInfo(eventId);
//     // Get end time 
//     (, uint32 endTime) = eventFacet.getEventTimeInfo(eventId); // We only need endTime from this call

//     // 2. Access Control
//     require(msg.sender == creator, "Raffle: Not event creator");

//     require(s_subscriptionId != 0, "Raffle: Subscription ID not set");
//     // 3. Validations
//     require(block.timestamp >= endTime, "Raffle: Event not ended");
//     // Optional: Check status is appropriate for drawing. Example:
//     require(
//         status == LibEventFactory.EventStatus.RegistrationOpen || status == LibEventFactory.EventStatus.InProgress,
//         "Raffle: Event not in correct state on Facet"
//     );
//     require(!isWinnerDrawn[eventId], "Raffle: Winner already drawn");
//     require(randomnessRequestId[eventId] == 0, "Raffle: Draw already initiated");
//     address[] storage eventParticipants = participants[eventId];
//     require(eventParticipants.length > 0, "Raffle: No participants");

//     // 4. Request Randomness (This part remains the same)
//     uint256 requestId = VRF_COORDINATOR.requestRandomWords(
//         s_keyHash,
//         s_subscriptionId,
//         REQUEST_CONFIRMATIONS,
//         s_callbackGasLimit,
//         NUM_WORDS
//     );

//     // 5. Store Request ID and Link (This part remains the same)
//     randomnessRequestId[eventId] = requestId;
//     requestIdToEventId[requestId] = eventId;

//     // 6. Emit Event (This part remains the same)
//     emit RandomnessRequested(eventId, requestId, msg.sender);

//     }

//     /**
//      * @notice VRF Callback function. Selects and stores the winner.
//      * @dev Remains internal override. Callback to Facet is not possible in this flow.
//      */
//     function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
//         // 1. Get Event ID (same as before)
//         uint256 eventId = requestIdToEventId[requestId];
//         require(eventId != 0, "Raffle: Invalid request ID");

//         // 2. Ensure not already processed (same as before)
//         require(!isWinnerDrawn[eventId], "Raffle: Winner already drawn (fulfillment)");

//         // 3. Select Winner (same as before, using native modulo)
//         address[] storage eventParticipants = participants[eventId];
//         uint256 numParticipants = eventParticipants.length;
//         require(numParticipants > 0, "Raffle: No participants (fulfillment)");

//         uint256 winnerIndex = randomWords[0] % numParticipants; // Use native modulo
//         address drawnWinner = eventParticipants[winnerIndex];

//         // 4. Store Winner and Update Status (same as before)
//         winner[eventId] = drawnWinner;
//         isWinnerDrawn[eventId] = true;

//         // 5. Emit Event (same as before)
//         emit WinnerDrawn(eventId, drawnWinner, requestId);

//         // Cannot call back to EventFacet here to update status.
//         // Status update on Facet would need separate manual trigger if desired.
//     }

//     // --- Getter Functions --- (remain the same)
//     function getParticipants(uint256 eventId) external view returns (address[] memory) {
//         return participants[eventId];
//     }

//     function getWinner(uint256 eventId) external view returns (address) {
//         return winner[eventId];
//     }

//     // --- Admin Functions (Optional) --- (remain the same)
//     // ...
// }