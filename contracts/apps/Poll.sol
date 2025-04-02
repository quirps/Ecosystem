// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Or custom access control
import { ReentrancyGuardContract } from "../ReentrancyGuard.sol"; 

interface IEcosystem {
    function getMemberLevel(address _user) external view returns (uint256);
    // function ecosystemOwner() external view returns (address); // Assuming Ownable uses this logic
}

contract Poll is Ownable, ReentrancyGuardContract {
    IEcosystem public immutable ecosystemContract;
    IERC1155 public immutable tokenContract;

    string public eventName;
    string public question;
    string[] public options; // Keep strings short or use bytes32 for options

    uint256 public startTime;
    uint256 public endTime;

    // Requirements
    uint256 public requiredLevel;
    uint256 public requiredTokenId;
    bool public spendTicket; // If true, spend 1 ticket; if false, just check balance >= 1

    mapping(uint256 => uint256) public votesPerOptionIndex;
    mapping(address => bool) public hasVoted;
    uint256 public totalVotes;

    event Voted(address indexed voter, uint256 indexed optionIndex);
    event PollEnded(uint256 timestamp);

    modifier withinEventWindow() {
        require(block.timestamp >= startTime, "Poll: Not started");
        require(block.timestamp < endTime, "Poll: Ended");
        _;
    }

    constructor(
        address _ecosystemAddress,
        address _tokenAddress,
        address _initialOwner,
        string memory _eventName,
        string memory _question,
        string[] memory _options,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _requiredLevel,
        uint256 _requiredTokenId,
        bool _spendTicket
    ) Ownable(_initialOwner) {
        require(_ecosystemAddress != address(0), "Invalid ecosystem address");
        require(_tokenAddress != address(0), "Invalid token address");
        require(_startTime < _endTime, "Invalid times");
        require(_options.length >= 2, "Need at least 2 options");

        ecosystemContract = IEcosystem(_ecosystemAddress);
        tokenContract = IERC1155(_tokenAddress);
        eventName = _eventName;
        question = _question;
        options = _options;
        startTime = _startTime;
        endTime = _endTime;
        requiredLevel = _requiredLevel;
        requiredTokenId = _requiredTokenId;
        spendTicket = _spendTicket;
    } 

    function vote(uint256 _optionIndex) external withinEventWindow ReentrancyGuard {
        address voter = msg.sender; // In meta-tx context, this might be recovered signer
        require(!hasVoted[voter], "Poll: Already voted");
        require(_optionIndex < options.length, "Poll: Invalid option");

        // Check Requirements
        if (requiredLevel > 0) {
            require(ecosystemContract.getMemberLevel(voter) >= requiredLevel, "Poll: Insufficient level");
        }
        if (requiredTokenId > 0) { // Assuming Token ID 0 is invalid/unused
            uint256 balance = tokenContract.balanceOf(voter, requiredTokenId);
            require(balance >= 1, "Poll: Insufficient tokens");

            if (spendTicket) {
                // Requires voter to have approved this contract beforehand
                // OR use permit-style signature if supported by token
                tokenContract.safeTransferFrom(voter, address(this), requiredTokenId, 1, "");
                // Consider transferring to address(0) to burn, or to owner/treasury
            }
        }

        // Record Vote
        hasVoted[voter] = true;
        votesPerOptionIndex[_optionIndex]++;
        totalVotes++;

        emit Voted(voter, _optionIndex);
    }

    // Function for owner to manually trigger end if needed, e.g., after endTime
    function manualEndPoll() external onlyOwner {
         require(block.timestamp >= endTime, "Poll: Not ended yet");
         // Can add logic here if needed, like snapshotting final results
         emit PollEnded(block.timestamp);
         // Could potentially self-destruct or transfer remaining tokens if needed
    }

    // View functions for results
    function getOptionCount() external view returns (uint256) {
        return options.length;
    }

     function getVotesForOption(uint256 _optionIndex) external view returns (uint256) {
         require(_optionIndex < options.length, "Poll: Invalid option");
         return votesPerOptionIndex[_optionIndex];
     }
}