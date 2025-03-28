// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol"; // Optional: for easier participant iteration

contract Raffle is Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;

    IERC1155 public immutable tokenContract;

    string public eventName;
    string public prizeDescription;

    uint256 public startTime;
    uint256 public endTime;

    // Requirements
    uint256 public immutable requiredTokenId;
    uint256 public immutable ticketsPerEntry; // Usually 1

    // Limits & State
    uint256 public maxEntriesPerUser; // 0 means unlimited
    address[] public participants; // Stores address for each entry (duplicates allowed)
    mapping(address => uint256) public entriesPerUser;
    // EnumerableSet.AddressSet private uniqueParticipants; // Optional: track unique users easily

    // Winner
    bool public winnerDeclared;
    address public winner;

    event EnteredRaffle(address indexed user, uint256 entryCount);
    event WinnerDrawn(address indexed winner);

    modifier withinEventWindow() {
        require(block.timestamp >= startTime, "Raffle: Not started");
        require(block.timestamp < endTime, "Raffle: Ended");
        _;
    }

     modifier drawAllowed() {
        require(block.timestamp >= endTime, "Raffle: Not ended yet");
        require(!winnerDeclared, "Raffle: Winner already drawn");
        _;
    }

    constructor(
        address _tokenAddress,
        address _initialOwner,
        string memory _eventName,
        string memory _prize,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _requiredTokenId,
        uint256 _ticketsPerEntry,
        uint256 _maxEntriesPerUser
    ) Ownable(_initialOwner) {
        require(_tokenAddress != address(0));
        require(_startTime < _endTime);
        require(_requiredTokenId != 0);
        require(_ticketsPerEntry > 0);

        tokenContract = IERC1155(_tokenAddress);
        eventName = _eventName;
        prizeDescription = _prize;
        startTime = _startTime;
        endTime = _endTime;
        requiredTokenId = _requiredTokenId;
        ticketsPerEntry = _ticketsPerEntry;
        maxEntriesPerUser = _maxEntriesPerUser;
    }

    function enterRaffle() external withinEventWindow nonReentrant {
        address entrant = msg.sender; // Recovered signer in meta-tx

        if (maxEntriesPerUser > 0) {
            require(entriesPerUser[entrant] < maxEntriesPerUser, "Raffle: Max entries reached");
        }

        // Check balance
        uint256 balance = tokenContract.balanceOf(entrant, requiredTokenId);
        require(balance >= ticketsPerEntry, "Raffle: Insufficient tickets");

        // Take tickets (Requires approval or permit)
        tokenContract.safeTransferFrom(entrant, address(this), requiredTokenId, ticketsPerEntry, "");
        // Consider burning or sending to owner

        // Record entry
        participants.push(entrant);
        entriesPerUser[entrant]++;
        // uniqueParticipants.add(entrant); // Optional

        emit EnteredRaffle(entrant, entriesPerUser[entrant]);
    }

    // --- Winner Selection (Manual Example) ---
    // NOTE: On-chain randomness (Chainlink VRF) is better but more complex.
    // This manual method relies on the owner being trustworthy.

    function drawWinnerManual() external onlyOwner drawAllowed {
        uint256 totalEntries = participants.length;
        require(totalEntries > 0, "Raffle: No entries");

        // VERY BASIC pseudo-randomness (Not secure for high value prizes!)
        uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, totalEntries))) % totalEntries;
        winner = participants[randomIndex];
        winnerDeclared = true;

        emit WinnerDrawn(winner);
    }

    // --- View Functions ---
    function getTotalEntries() external view returns (uint256) {
        return participants.length;
    }

    function getEntriesForUser(address _user) external view returns (uint256) {
        return entriesPerUser[_user];
    }

    // function getUniqueParticipantCount() external view returns (uint256) { // Optional
    //     return uniqueParticipants.length();
    // }
}