// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19; // Use a consistent recent version

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IEventFacet } from "../facets/Events/IEventFactory.sol"; // Adjust path if needed
import { LibEventFactory } from "../facets/Events/LibEventFactory.sol"; // Adjust path if needed
 
/**
 * @title PollApp
 * @notice Handles logic for simple polling events within a specific ecosystem instance.
 * @dev Meant to be deployed per ecosystem. Calls back to the parent EventFacet
 * for core checks and token interactions. Users must approve this contract
 * to spend their voting tickets (if burning is required).
 */
contract PollApp is Ownable {

    // --- State Variables ---

    // Address of the parent Ecosystem Diamond's EventFacet interface
    address public immutable EVENT_FACET_ADDRESS;

    // Poll configuration per eventId within this app's context
    mapping(uint256 => uint8) public numOptions; // eventId => number of choices

    // Vote tallies per eventId and optionIndex
    mapping(uint256 => mapping(uint8 => uint256)) public voteCounts;

    // Tracking who has voted per eventId
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // --- Events ---

    event PollInitialized(uint256 indexed eventId, uint8 numOptions, address indexed initializer);
    event Voted(uint256 indexed eventId, address indexed voter, uint8 optionIndex);

    // --- Errors ---

    error PollAlreadyInitialized(uint256 eventId);
    error PollNotInitialized(uint256 eventId);
    error InvalidOptionIndex(uint256 eventId, uint8 received, uint8 maxAllowed);
    error AlreadyVoted(uint256 eventId, address voter);
    error CoreParticipationFailed(uint256 eventId, address user);
    error InvalidNumberOfOptions(uint8 numOptions);
    error NotEventCreator(uint256 eventId, address caller, address expectedCreator);
    error ZeroAddress();


    // --- Constructor ---

    /**
     * @param _eventFacetAddress The address of the parent Ecosystem Diamond proxy.
     */
    constructor(address _eventFacetAddress) Ownable(msg.sender) {
        if (_eventFacetAddress == address(0)) revert ZeroAddress();
        EVENT_FACET_ADDRESS = _eventFacetAddress;
    }

    // --- Setup Function ---

    /**
     * @notice Initializes the poll settings for a specific event.
     * @dev Must be called once by the event creator before voting can begin.
     * Fetches creator address from the parent EventFacet.
     * @param eventId The ID of the event created on the EventFacet.
     * @param _numOptions The total number of voting options (e.g., 2 for Yes/No). Min 2.
     */
    function initializePoll(uint256 eventId, uint8 _numOptions) external {
        // 1. Check if already initialized for this event within this app instance
        if (numOptions[eventId] != 0) revert PollAlreadyInitialized(eventId);

        // 2. Check valid number of options
        if (_numOptions < 2) revert InvalidNumberOfOptions(_numOptions);

        // 3. Access Control: Only the creator of the event on the Facet can initialize
        // Requires EVENT_FACET_ADDRESS to be correctly set and accessible
        IEventFacet eventFacet = IEventFacet(EVENT_FACET_ADDRESS);
        // Fetch only the creator address using the specific getter
        (address creator,,,) = eventFacet.getEventCoreInfo(eventId);
        if (msg.sender != creator) revert NotEventCreator(eventId, msg.sender, creator);

        // 4. Store settings
        numOptions[eventId] = _numOptions;

        // 5. Emit event
        emit PollInitialized(eventId, _numOptions, msg.sender);
    }


    // --- User-Facing Function ---

    /**
     * @notice Allows a user to cast their vote for a specific poll event.
     * @dev User calls this function directly on this PollApp instance.
     * It verifies core participation rules (including token interaction like Burn)
     * via the parent EventFacet before recording the vote locally.
     * @param eventId The ID of the poll event configured on the EventFacet.
     * @param ticketId The ID of the ERC1155 voting ticket.
     * @param amount The amount of the ticket required (must match event config on Facet).
     * @param optionIndex The index of the option the user is voting for (0-based).
     */
    function castVote(uint256 eventId, uint256 ticketId, uint256 amount, uint8 optionIndex) external {
        // 1. Define expected interaction (typically Burn for voting)
        LibEventFactory.TicketInteraction expectedInteraction = LibEventFactory.TicketInteraction.Burn;

        // 2. Verify core participation via EventFacet
        // Note: User (msg.sender) must have approved THIS PollApp contract address
        //       for the specified ticketId and amount on the parent Diamond's ERC1155.
        IEventFacet eventFacet = IEventFacet(EVENT_FACET_ADDRESS);
        bool success = eventFacet.verifyAndProcessParticipation(
            eventId,
            msg.sender, // The user casting the vote
            ticketId,
            amount,
            expectedInteraction
        );

        // 3. Check Facet Verification Result
        if (!success) revert CoreParticipationFailed(eventId, msg.sender);

        // 4. Local Poll Validations (Checks specific to this app's state)
        uint8 _numOptions = numOptions[eventId];
        if (_numOptions == 0) revert PollNotInitialized(eventId);
        if (optionIndex >= _numOptions) revert InvalidOptionIndex(eventId, optionIndex, _numOptions - 1);
        if (hasVoted[eventId][msg.sender]) revert AlreadyVoted(eventId, msg.sender);

        // 5. Record Vote Locally
        voteCounts[eventId][optionIndex]++;
        hasVoted[eventId][msg.sender] = true;

        // 6. Emit Event
        emit Voted(eventId, msg.sender, optionIndex);
    }

    // --- Getter Functions ---

    function getVoteCount(uint256 eventId, uint8 optionIndex) external view returns (uint256) {
        // Optional check: if (optionIndex >= numOptions[eventId]) return 0;
        return voteCounts[eventId][optionIndex];
    }

    function getNumOptions(uint256 eventId) external view returns (uint8) {
        return numOptions[eventId];
    }

    function getHasVoted(uint256 eventId, address user) external view returns (bool) {
        return hasVoted[eventId][user];
    }

    // No setter for EVENT_FACET_ADDRESS as it's immutable
}