// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
// Adjust paths if these interfaces are defined elsewhere
import { IEventFacet } from "../facets/Events/IEventFactory.sol";
import { LibEventFactory } from "../facets/Events/LibEventFactory.sol";
// import { IERC1155Transfer } from "../facets/Tokens/ERC1155/interfaces/IERC1155Transfer.sol";
// import { ITieredPermission } from "../interfaces/ITieredPermission.sol"; // Assuming path

// --- Interfaces (Define locally if not imported) ---

// Forward declaration for LibEventFactory struct


interface IERC1155Transfer {
    function setApprovalForAll(address operator, bool approved) external;
    // Add other relevant ERC1155 functions if needed by EventFacet
}



interface ITieredPermission {
    function isAppCreator(address creator) external view returns (bool isAppCreator_);
}

/**
 * @title PollApp
 * @notice Handles logic for polling events within a specific ecosystem instance.
 * @dev Deployed per ecosystem. Interacts with the parent Ecosystem Diamond (via ECOSYSTEM_ADDRESS)
 * for event creation, participation verification, and permission checks.
 * Users must approve this contract address on the ERC1155 contract (at ECOSYSTEM_ADDRESS)
 * to allow burning of their voting tickets.
 */
contract PollApp is Ownable {

    // --- State Variables ---

    address public immutable ECOSYSTEM_ADDRESS;

    struct PollConfig{
        string[] pollOptions;
        string pollQuestion;
    }

    enum PollStatus { Inactive, Active, Ended }
    mapping(uint256 => PollStatus) public pollStatus; // eventId => Status

    // Stores the description for each voting option per event
    mapping(uint256 => PollConfig) public pollOptions; // eventId => ["Option A", "Option B", ...]

    // Vote tallies per eventId and optionIndex
    mapping(uint256 => mapping(uint8 => uint256)) public voteCounts; // eventId => optionIndex => count

    // Tracks who has voted per eventId to prevent double voting
    mapping(uint256 => mapping(address => bool)) public hasVoted; // eventId => voter => bool

    // --- Events ---

    event PollInitialized(uint256 indexed eventId, PollConfig pollConfig, address indexed initializer);
    event Voted(uint256 indexed eventId, address indexed voter, uint8 optionIndex);
    event AppApproved(address indexed participant, bool approved);
    event PollEnded(uint256 indexed eventId, address indexed closer);

    // --- Errors ---

    error ZeroAddress();
    error NotAppCreator(address caller); // Modifier error
    error InsufficientOptions(uint256 provided); // Must have at least 2 options
    error PollAlreadyInitialized(uint256 eventId); // Should not happen with unique event IDs from factory
    error PollNotInitialized(uint256 eventId);
    error PollNotActive(uint256 eventId);
    error PollAlreadyEnded(uint256 eventId); // If trying to interact after ending
    error NotEventCreator(uint256 eventId, address caller, address expectedCreator);
    error InvalidOptionIndex(uint256 eventId, uint8 received, uint8 maxAllowed);
    error AlreadyVoted(uint256 eventId, address voter);
    error CoreParticipationFailed(uint256 eventId, address user); // Facet verification failed

    // --- Constructor ---

    /**
     * @param _ecosystemAddress The address of the parent Ecosystem Diamond contract.
     */
    constructor(address _ecosystemAddress) Ownable(msg.sender) {
        if (_ecosystemAddress == address(0)) revert ZeroAddress();
        ECOSYSTEM_ADDRESS = _ecosystemAddress;
    }

    // --- Modifier ---

    /**
     * @dev Checks if the caller has the 'AppCreator' role within the Ecosystem.
     * Calls the ITieredPermission interface expected at ECOSYSTEM_ADDRESS.
     */
    modifier onlyAppCreator() {
        if (!ITieredPermission(ECOSYSTEM_ADDRESS).isAppCreator(msg.sender)) {
            revert NotAppCreator(msg.sender);
        }
        _;
    }

     /**
     * @dev Checks if the caller is the original creator of the event.
     * Calls the IEventFacet interface expected at ECOSYSTEM_ADDRESS.
     */
    modifier onlyEventCreator(uint256 eventId) {
        address expectedCreator = IEventFacet(ECOSYSTEM_ADDRESS).getEventCreator(eventId); 
        if (msg.sender != expectedCreator) {
            revert NotEventCreator(eventId, msg.sender, expectedCreator);
        }
        _;
    }

    // --- Setup Function ---
 
    /**
     * @notice Creates an event on the core Ecosystem contract and initializes poll settings here.
     * @dev Must be called by an address with 'AppCreator' role (verified via ECOSYSTEM_ADDRESS).
     * The poll requires at least two options.
     * @param _optionConfig An array of strings describing each voting option and the corresponding question.
     * @param eventParams Parameters required by the core `IEventFacet.createEvent` function.
     */
    function createEventAndInitializePoll(
        PollConfig memory _optionConfig,
        LibEventFactory.CreateEventParams memory eventParams
    ) external onlyAppCreator returns ( uint256 eventId_) { // Ensures only authorized creators can setup polls
        // 1. Validate poll options
        uint8 numOptionsProvided = uint8(_optionConfig.pollOptions.length);
        if (numOptionsProvided < 2) revert InsufficientOptions(numOptionsProvided);
        // Consider adding a max limit for gas reasons if needed:
        // if (numOptionsProvided > MAX_POLL_OPTIONS) revert TooManyOptions(...);

        // 2. Set creator in params (caller of this function is the intended creator)
        eventParams.creator = msg.sender;

        // 3. Call the Ecosystem contract to create the underlying event
        eventId_ = IEventFacet(ECOSYSTEM_ADDRESS).createEvent(eventParams);

        // 4. Check if poll somehow already initialized (safety check)
        // Accessing length of a non-existent array is 0
        if (pollOptions[eventId_].pollOptions.length != 0) revert PollAlreadyInitialized(eventId_); 
         // Also check status - should be Inactive before init
        if (pollStatus[eventId_] != PollStatus.Inactive) revert PollAlreadyInitialized(eventId_);

        // 5. Store poll settings locally using the new eventId
        pollOptions[eventId_] = _optionConfig;
        pollStatus[eventId_] = PollStatus.Active; // Mark poll as active

        // 6. Emit event
        emit PollInitialized(eventId_, _optionConfig, msg.sender);
    }

    // --- User-Facing Functions ---

    /**
     * @notice Allows a user to cast their vote for an active poll event.
     * @dev Verifies participation rules (e.g., ticket burn) via the parent EventFacet.
     * User must have approved this PollApp contract to manage their voting tickets
     * on the main ERC1155 contract (at ECOSYSTEM_ADDRESS).
     * @param eventId The ID of the poll event.
     * @param ticketId The ID of the ERC1155 voting ticket.
     * @param amount The amount of the ticket required (must match event config).
     * @param optionIndex The index of the option the user is voting for (0-based).
     */
    function castVote(uint256 eventId, uint256 ticketId, uint256 amount, uint8 optionIndex) public {
        // 1. Check Poll Status and Initialization
        if (pollStatus[eventId] != PollStatus.Active) revert PollNotActive(eventId);
        // pollOptions length check also implicitly confirms initialization
        uint8 numOptionsAvailable = uint8(pollOptions[eventId].pollOptions.length);
        // This check might be redundant if PollNotActive is checked first, but good for clarity
        if (numOptionsAvailable == 0) revert PollNotInitialized(eventId);

        // 3. Verify core participation via EventFacet
        // User (_msgSender()) must have approved THIS PollApp contract address for the ticketId/amount
        // on the parent Diamond's ERC1155 implementation.
        IEventFacet eventFacet = IEventFacet(ECOSYSTEM_ADDRESS);
        bool success = eventFacet.verifyAndProcessParticipation(
            eventId,
            msg.sender, // The user casting the vote
            ticketId,
            amount 
        );

        // 4. Check Facet Verification Result
        if (!success) revert CoreParticipationFailed(eventId, msg.sender);

        // 5. Local Poll Validations
        if (optionIndex >= numOptionsAvailable) revert InvalidOptionIndex(eventId, optionIndex, numOptionsAvailable - 1);
        if (hasVoted[eventId][msg.sender]) revert AlreadyVoted(eventId, msg.sender);

        // 6. Record Vote Locally
        voteCounts[eventId][optionIndex]++;
        hasVoted[eventId][msg.sender] = true;

        // 7. Emit Event
        emit Voted(eventId, msg.sender, optionIndex);
    }

    /**
     * @notice Convenience function: Approves this contract and then casts a vote.
     * @dev Useful for UIs to combine steps, but user must understand they are granting approval.
     * Assumes the ERC1155 contract is at ECOSYSTEM_ADDRESS.
     */
    function castVoteApprove(uint256 eventId, uint256 ticketId, uint256 amount, uint8 optionIndex) external {
        // Approve this PollApp contract to spend the user's tokens held by the Ecosystem contract
        IERC1155Transfer(ECOSYSTEM_ADDRESS).setApprovalForAll(_msgSender(), true);
        emit AppApproved(_msgSender(), true); // Emit approval event
        castVote(eventId, ticketId, amount, optionIndex); // Call the main voting logic
    }

    // --- Administrative Function ---

    /**
     * @notice Ends the voting period for a specific poll event.
     * @dev Can only be called by the original creator of the event (fetched from EventFacet).
     * Calls `endEvent` on the core Ecosystem contract.
     * @param eventId The ID of the poll event to end.
     */
    function endPoll(uint256 eventId) external onlyEventCreator(eventId) {
         // 1. Check Poll Status
        if (pollStatus[eventId] == PollStatus.Inactive) revert PollNotInitialized(eventId);
        if (pollStatus[eventId] == PollStatus.Ended) revert PollAlreadyEnded(eventId);

        // 2. Update local status first (prevents race conditions/re-entrancy issues)
        pollStatus[eventId] = PollStatus.Ended;

        // 3. Call the Ecosystem contract to formally end the underlying event
        // This might handle things like unfreezing staked tokens, etc.
        IEventFacet(ECOSYSTEM_ADDRESS).endEvent(eventId);

        // 4. Emit Event
        emit PollEnded(eventId, msg.sender);
    }


    // --- Getter Functions ---

    /**
     * @notice Gets the description strings for all options of a specific poll.
     * @param eventId The ID of the poll event.
     * @return descriptions An array of strings representing the poll options.
     */
    function getPollOptions(uint256 eventId) external view returns (string[] memory descriptions) {
        return pollOptions[eventId].pollOptions;
    }

    /**
     * @notice Gets the current vote count for a specific option within a poll.
     * @param eventId The ID of the poll event.
     * @param optionIndex The index of the option.
     * @return count The number of votes cast for this option.
     */
    function getVoteCount(uint256 eventId, uint8 optionIndex) external view returns (uint256 count) {
        // Optional check: if (optionIndex >= pollOptions[eventId].length) return 0; // Or revert
        return voteCounts[eventId][optionIndex];
    }

   /**
    * @notice Gets all vote counts for a specific poll.
    * @param eventId The ID of the poll event.
    * @return results An array containing the vote count for each option index.
    */
    function getPollResults(uint256 eventId) external view returns (uint256[] memory results) {
        uint256 numOptionsAvailable = pollOptions[eventId].pollOptions.length;
        results = new uint256[](numOptionsAvailable);
        for (uint8 i = 0; i < numOptionsAvailable; i++) {
            results[i] = voteCounts[eventId][i];
        }
        return results;
    }

   /**
    * @notice Determines the winning option(s) for a poll based on current counts.
    * @dev Returns an array of indices in case of a tie. Returns empty array if no votes cast.
    * @param eventId The ID of the poll event.
    * @return winningIndices An array of the option indices with the highest vote count.
    */
    function getWinningOption(uint256 eventId) external view returns (uint8[] memory winningIndices) {
        uint256 numOptionsAvailable = pollOptions[eventId].pollOptions.length;
        if (numOptionsAvailable == 0) {
            return new uint8[](0); // No options, no winner
        }

        uint256 maxVotes = 0;
        uint256 winnersCount = 0; // How many winners currently tied

        // First pass: find the maximum vote count
        for (uint8 i = 0; i < numOptionsAvailable; i++) {
            if (voteCounts[eventId][i] > maxVotes) {
                maxVotes = voteCounts[eventId][i];
            }
        }

        // Handle case where no votes were cast at all
        if (maxVotes == 0) {
             return new uint8[](0); // No votes, no winner
        }

        // Second pass: count how many options have the max vote count
        for (uint8 i = 0; i < numOptionsAvailable; i++) {
            if (voteCounts[eventId][i] == maxVotes) {
                winnersCount++;
            }
        }

        // Third pass: populate the results array
        winningIndices = new uint8[](winnersCount);
        uint256 winnerIdx = 0;
        for (uint8 i = 0; i < numOptionsAvailable; i++) {
            if (voteCounts[eventId][i] == maxVotes) {
                winningIndices[winnerIdx] = i;
                winnerIdx++;
            }
        }

        return winningIndices;
    }


    /**
     * @notice Checks if a specific user has already voted in a given poll.
     * @param eventId The ID of the poll event.
     * @param user The address of the user to check.
     * @return hasVotedStatus True if the user has voted, false otherwise.
     */
    function getHasVoted(uint256 eventId, address user) external view returns (bool hasVotedStatus) {
        return hasVoted[eventId][user];
    }

    /**
     * @notice Gets the current status of the poll (Inactive, Active, Ended).
     * @param eventId The ID of the poll event.
     * @return status The current PollStatus enum value.
     */
    function getPollStatus(uint256 eventId) external view returns (PollStatus status) {
        return pollStatus[eventId];
    }

     /**
     * @notice Gets the address that created the event associated with this poll ID.
     * @dev Calls the IEventFacet interface on the ECOSYSTEM_ADDRESS.
     * @param eventId The ID of the poll event.
     * @return creator The address of the event creator.
     */
    function getEventCreator(uint256 eventId) external view returns (address creator) {
        // Ensure the poll exists (or handle potential revert from getEventCreator if eventId is invalid)
        // if (pollStatus[eventId] == PollStatus.Inactive) revert PollNotInitialized(eventId);
        // Note: Calling getEventCreator for an uninitialized poll might revert or return address(0)
        // depending on the IEventFacet implementation. Returning address(0) might be acceptable here.
        return IEventFacet(ECOSYSTEM_ADDRESS).getEventCreator(eventId);
    }

    // ECOSYSTEM_ADDRESS is immutable, no setter needed.
    // Ownable handles ownership transfer if required.
}