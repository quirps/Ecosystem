// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
// Import the IEventFacet for interacting with the Ecosystem Diamond
import { IEventFacet } from "../facets/Events/IEventFacet.sol";
// Import the LibEventFacet for shared structs like CreateEventParams
import { LibEventFacet } from "../facets/Events/LibEventFacet.sol";
import "hardhat/console.sol";
// Import standard ERC1155 for the setApprovalForAll call if needed externally
interface IERC1155 {
    function setApprovalForAll(address operator, bool approved) external;
}

/**
 * @title PollApp
 * @notice Handles logic for polling events within a specific ecosystem instance.
 * @dev This contract acts as an "app logic" contract. Users and creators interact
 * directly with this contract. This contract then makes external calls to the
 * Ecosystem Diamond (via ECOSYSTEM_ADDRESS) for event registration,
 * participation verification, and core permission checks.
 * Users must approve the Ecosystem Diamond address on the ERC1155 contract
 * (which is an internal part of the Diamond) to allow burning/holding of their voting tickets.
 */
contract PollApp is Ownable {

    // --- State Variables ---

    address public immutable ECOSYSTEM_ADDRESS;

    struct PollConfig {
        string[] pollOptions;
        string pollQuestion;
    }

    enum PollStatus { Inactive, Active, Ended }
    mapping(uint256 => PollStatus) public pollStatus; // eventId => Status

    // Stores the configuration for each poll event
    mapping(uint256 => PollConfig) public pollConfigs; // eventId => {options, question}

    // Vote tallies per eventId and optionIndex
    mapping(uint256 => mapping(uint8 => uint256)) public voteCounts; // eventId => optionIndex => count

    // Tracks who has voted per eventId to prevent double voting
    mapping(uint256 => mapping(address => bool)) public hasVoted; // eventId => voter => bool

    // --- Events ---

    event PollInitialized(uint256 indexed eventId, PollConfig pollConfig, address indexed initializer);
    event Voted(uint256 indexed eventId, address indexed voter, uint8 optionIndex);
    event AppApproved(address indexed participant, bool approved); // Still useful for UI feedback
    event PollEnded(uint256 indexed eventId, address indexed closer);

    // --- Errors ---

    error ZeroAddress();
    error NotAppCreator(address caller); // Modifier error, now checked against Ecosystem
    error InsufficientOptions(uint256 provided); // Must have at least 2 options
    error PollAlreadyInitialized(uint256 eventId);
    error PollNotInitialized(uint256 eventId);
    error PollNotActive(uint256 eventId);
    error PollAlreadyEnded(uint256 eventId);
    error NotEventCreator(uint256 eventId, address caller, address expectedCreator); // Still needed
    error InvalidOptionIndex(uint256 eventId, uint8 received, uint8 maxAllowed);
    error AlreadyVoted(uint256 eventId, address voter);
    // CoreParticipationFailed is no longer needed as EventFacet handles its own reverts.
    // We just allow the EventFacet's specific revert to bubble up.

    // --- Constructor ---

    /**
     * @param _ecosystemAddress The address of the parent Ecosystem Diamond contract.
     */
    constructor(address _ecosystemAddress) Ownable(msg.sender) {
        if (_ecosystemAddress == address(0)) revert ZeroAddress();
        ECOSYSTEM_ADDRESS = _ecosystemAddress;
    }

    // --- Modifiers ---

    /**
     * @dev Checks if the caller is a registered 'AppCreator' within the Ecosystem.
     * Calls the `isRegisteredApp` view function on the EventFacet of the Ecosystem Diamond.
     */
    modifier onlyAppCreator() {
        if (!IEventFacet(ECOSYSTEM_ADDRESS).isRegisteredApp(address(this))) {
            console.log(0);
            revert NotAppCreator(msg.sender);
        }
        _;
    }

    /**
     * @dev Checks if the caller is the original creator of the event, by querying the Ecosystem.
     * Calls the `getEventCreator` view function on the EventFacet of the Ecosystem Diamond.
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
     * The PollApp makes an EXTERNAL CALL to the Ecosystem to create the global event.
     * @param _pollConfig Specific configuration for this poll (options, question).
     * @param _ecosystemEventParams Parameters required by the core `IEventFacet.createEvent` function.
     * Note: `_ecosystemEventParams.creator` should ideally be set to `msg.sender` here by the PollApp.
     */
    function createEventAndInitializePoll(
        PollConfig memory _pollConfig,
        LibEventFacet.CreateEventParams memory _ecosystemEventParams // Note: Renamed from LibEventFactory
    ) external onlyAppCreator returns (uint256 eventId_) { // Ensures only authorized creators can setup polls
        // 1. Validate poll options (app-specific)
        uint8 numOptionsProvided = uint8(_pollConfig.pollOptions.length);
        if (numOptionsProvided < 2) revert InsufficientOptions(numOptionsProvided);
        console.log(1);
        // 2. Set creator and appLogic in ecosystem event parameters
        _ecosystemEventParams.creator = msg.sender;
        _ecosystemEventParams.appLogic = address(this); // This PollApp instance is the logic for this event

        // 3. Call the Ecosystem contract to create the underlying event (EXTERNAL CALL)
        // This is safe because it's a regular call, not delegatecall.
        // The Ecosystem's createEvent will record eventId, creator, appLogic (this contract), etc.
        eventId_ = IEventFacet(ECOSYSTEM_ADDRESS).createEvent(_ecosystemEventParams);
console.log(2);
        // 4. Check if poll somehow already initialized (safety check for this app's state)
        if (pollConfigs[eventId_].pollOptions.length != 0) revert PollAlreadyInitialized(eventId_);
        console.log(3);
        if (pollStatus[eventId_] != PollStatus.Inactive) revert PollAlreadyInitialized(eventId_);
    console.log(4);
        // 5. Store poll settings locally using the new eventId (app-specific)
        pollConfigs[eventId_] = _pollConfig;
        pollStatus[eventId_] = PollStatus.Active; // Mark poll as active immediately

        // 6. Emit event
        emit PollInitialized(eventId_, _pollConfig, msg.sender);
    }

    // --- User-Facing Functions ---

    /**
     * @notice Allows a user to cast their vote for an active poll event.
     * @dev User interacts directly with PollApp. PollApp then makes an EXTERNAL CALL
     * to the Ecosystem for participation verification (e.g., ticket burning).
     * User must have approved the Ecosystem Diamond contract address for the ticketId/amount
     * on the main ERC1155 contract (which is managed by the Diamond).
     * @param eventId The ID of the poll event.
     * @param ticketId The ID of the ERC1155 voting ticket.
     * @param amount The amount of the ticket required (must match event config).
     * @param optionIndex The index of the option the user is voting for (0-based).
     */
    function castVote(uint256 eventId, uint256 ticketId, uint256 amount, uint8 optionIndex) public {
        // 1. Check Poll Status and Initialization (app-specific)
        if (pollStatus[eventId] != PollStatus.Active) revert PollNotActive(eventId);
        uint8 numOptionsAvailable = uint8(pollConfigs[eventId].pollOptions.length);
        if (numOptionsAvailable == 0) revert PollNotInitialized(eventId); // Should not happen if init was successful

        // 2. Local Poll Validations (app-specific)
        if (optionIndex >= numOptionsAvailable) revert InvalidOptionIndex(eventId, optionIndex, numOptionsAvailable - 1);
        if (hasVoted[eventId][msg.sender]) revert AlreadyVoted(eventId, msg.sender);

        // 3. Verify core participation via EventFacet (EXTERNAL CALL)
        // The EventFacet will handle checks like minMemberLevel and actual token transfers.
        // If it reverts, the transaction will revert here.
        IEventFacet(ECOSYSTEM_ADDRESS).verifyAndProcessParticipation(
            eventId,
            msg.sender, // The user casting the vote
            ticketId,
            amount
        );
        // 4. Record Vote Locally
        voteCounts[eventId][optionIndex]++;
        hasVoted[eventId][msg.sender] = true;

        // 5. Emit Event
        emit Voted(eventId, msg.sender, optionIndex);
    }

    /**
     * @notice Convenience function: Approves the Ecosystem Diamond and then casts a vote.
     * @dev User must explicitly call this. Assumes the ERC1155 interface is exposed directly on the Diamond.
     */
    function castVoteApprove(uint256 eventId, uint256 ticketId, uint256 amount, uint8 optionIndex) external {
        // Assume standard ERC1155 interface for external approval on the Diamond address
        IERC1155(ECOSYSTEM_ADDRESS).setApprovalForAll(msg.sender, true);
        emit AppApproved(msg.sender, true);
        castVote(eventId, ticketId, amount, optionIndex);
    }

    // --- Administrative Function ---

    /**
     * @notice Ends the voting period for a specific poll event.
     * @dev Can only be called by the original creator of the event (fetched from EventFacet).
     * Calls `endEvent` on the core Ecosystem contract (EXTERNAL CALL).
     * @param eventId The ID of the poll event to end.
     */
    function endPoll(uint256 eventId) external onlyEventCreator(eventId) {
        // 1. Check Poll Status (app-specific)
        if (pollStatus[eventId] == PollStatus.Inactive) revert PollNotInitialized(eventId);
        if (pollStatus[eventId] == PollStatus.Ended) revert PollAlreadyEnded(eventId);

        // 2. Update local status first (prevents re-entrancy/double-ending issues for this app)
        pollStatus[eventId] = PollStatus.Ended;

        // 3. Call the Ecosystem contract to formally end the underlying event (EXTERNAL CALL)
        // This will update the Ecosystem's global event status (e.g., to `Completed`).
        IEventFacet(ECOSYSTEM_ADDRESS).endEvent(eventId);

        // 4. Emit Event
        emit PollEnded(eventId, msg.sender);
    }

    // --- Getter Functions (Remain as is, mostly) ---
    // All getter functions are app-specific read views and remain here.
    function getPollOptions(uint256 eventId) external view returns (string[] memory descriptions) {
        return pollConfigs[eventId].pollOptions;
    }

    function getPollQuestion(uint256 eventId) external view returns (string memory question) {
        return pollConfigs[eventId].pollQuestion;
    }

    function getVoteCount(uint256 eventId, uint8 optionIndex) external view returns (uint256 count) {
        return voteCounts[eventId][optionIndex];
    }

    function getPollResults(uint256 eventId) external view returns (uint256[] memory results) {
        uint256 numOptionsAvailable = pollConfigs[eventId].pollOptions.length;
        results = new uint256[](numOptionsAvailable);
        for (uint8 i = 0; i < numOptionsAvailable; i++) {
            results[i] = voteCounts[eventId][i];
        }
        return results;
    }

    function getWinningOption(uint256 eventId) external view returns (uint8[] memory winningIndices) {
        uint256 numOptionsAvailable = pollConfigs[eventId].pollOptions.length;
        if (numOptionsAvailable == 0) {
            return new uint8[](0); // No options, no winner
        }

        uint256 maxVotes = 0;
        uint256 winnersCount = 0;

        for (uint8 i = 0; i < numOptionsAvailable; i++) {
            if (voteCounts[eventId][i] > maxVotes) {
                maxVotes = voteCounts[eventId][i];
            }
        }

        if (maxVotes == 0) {
              return new uint8[](0); // No votes, no winner
        }

        for (uint8 i = 0; i < numOptionsAvailable; i++) {
            if (voteCounts[eventId][i] == maxVotes) {
                winnersCount++;
            }
        }

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

    function getHasVoted(uint256 eventId, address user) external view returns (bool hasVotedStatus) {
        return hasVoted[eventId][user];
    }

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
        // This is a view call to the Ecosystem, which is perfectly safe.
        return IEventFacet(ECOSYSTEM_ADDRESS).getEventCreator(eventId);
    }

    /**
     * @notice Gets the current status of the event as per the Ecosystem.
     * @dev Provides a more holistic view by consulting the Ecosystem's status.
     * @param eventId The ID of the event.
     * @return status The current status from the Ecosystem's perspective.
     */
    function getEcosystemEventStatus(uint256 eventId) external view returns (LibEventFacet.EventStatus status) {
        return IEventFacet(ECOSYSTEM_ADDRESS).getEventStatus(eventId);
    }
}