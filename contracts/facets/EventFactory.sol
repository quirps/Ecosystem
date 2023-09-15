// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC1155Transfer.sol";
import "../libraries/utils/MerkleProof.sol";


contract EventFactory {
    struct TicketDetail {
        uint256 minAmount;
        uint256 maxAmount;
    }

    enum EventStatus {
        Pending,
        Active,
        Deactivated,
        Completed
    }

    struct EventDetail {
        uint32 startTime;
        uint32 endTime;
        uint256 minEntries;
        uint256 maxEntries;
        uint256 currentEntries;
        string imageUri;
        EventStatus status;
        bytes32 merkleRoot;
        mapping(uint256 => TicketDetail) ticketDetails;
        mapping(address => mapping(uint256 => uint256)) ticketsRedeemed; // Moved inside
    }
    address public owner;
    IERC1155Transfer public immutable tokenContract;
    mapping(uint256 => EventDetail) public events;

    event EventDetails(
        uint256 indexed eventId,
        uint32 startTime,
        uint32 endTime,
        uint256 minEntries,
        uint256 maxEntries,
        string imageUri,
        EventStatus status
    );

    event TicketDetails(uint256 indexed eventId, uint256[] indexed ticketIds, TicketDetail[] ticketDetails);
    event RefundsEnabled(uint256 eventId);
    event EventActivated(uint256 eventId);
    event EventCreated(uint256 eventId);
    event TicketRedeemed(uint256 eventId, uint256[] ticketId, uint256[] amount);
    event EventDeactivated(uint256 eventId);
    event TicketRefunded(uint256 eventId, uint256 ticketId, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(address _trustedTokenContract) {
        owner = msg.sender;
        tokenContract = IERC1155Transfer(_trustedTokenContract);
    }

    function setMerkleRoot(uint256 eventId, bytes32 root) external onlyOwner {
        EventStatus _eventStatus = events[eventId].status;
        require(_eventStatus == EventStatus.Deactivated || _eventStatus == EventStatus.Completed, "Event must be finished.");

        _setMerkleRoot(eventId, root);
    }

    function _setMerkleRoot(uint256 eventId, bytes32 root) internal {
        bytes32 _merkleRoot = events[eventId].merkleRoot;

        require(_merkleRoot == bytes32(0), "Merkle root has already been set for this event.");

        events[eventId].merkleRoot = root;
        emit RefundsEnabled(eventId);
    }

    function setUri(uint256 eventId, string memory imageUri) external onlyOwner {
        require(events[eventId].endTime != 0, "Event does not exist");
        events[eventId].imageUri = imageUri;
    }

    function getUri(uint256 eventId) external view returns (string memory) {
        return events[eventId].imageUri;
    }

    function deactivateEvent(uint256 eventId, bytes32 root) external onlyOwner {
        require(events[eventId].endTime != 0, "Event does not exist");
        require(events[eventId].status == EventStatus.Active || events[eventId].status == EventStatus.Pending, "Event has already terminated");
        events[eventId].status = EventStatus.Deactivated;
        emit EventDeactivated(eventId);
        if (root != bytes32(0)) {
            _setMerkleRoot(eventId, root);
        }
    }

    function validateNonInclusion(
        uint256 eventId,
        address lowerBound,
        address upperBound,
        bytes32[] calldata merkleProof
    ) internal view returns (bool) {
        //ensure sender is within bounds
        require(uint160(lowerBound) < uint160(msg.sender) && uint160(msg.sender) < uint160(upperBound), "Sender is not within the exclusive bounds");

        // Verify non-inclusion proof
        bytes32 leaf = keccak256(abi.encodePacked(lowerBound, upperBound));
        return !MerkleProof.verify(merkleProof, events[eventId].merkleRoot, leaf);
    }

    function redeemTickets(uint256 eventId, uint256[] memory ticketIds, uint256[] memory amounts) public {
        EventDetail storage eventDetail = events[eventId];
        EventStatus _status = eventDetail.status;
        require(uint32(block.timestamp) >= eventDetail.startTime && uint32(block.timestamp) <= eventDetail.endTime, "Event not active");
        require(ticketIds.length == amounts.length, "Mismatched ticketIds and amounts lengths");

        if (_status == EventStatus.Pending) {
            eventDetail.status = EventStatus.Active;
            emit EventActivated(eventId);
        }
        for (uint i = 0; i < ticketIds.length; i++) {
            TicketDetail storage ticketDetail = eventDetail.ticketDetails[ticketIds[i]];
            require(eventDetail.currentEntries + amounts[i] <= eventDetail.maxEntries, "Exceeding max entries");
            require(amounts[i] >= ticketDetail.minAmount && amounts[i] <= ticketDetail.maxAmount, "Invalid ticket amount");

            // Transfer ERC1155 tokens from user to contract
            tokenContract.safeTransferFrom(msg.sender, address(this), ticketIds[i], amounts[i], "");

            // Update event and ticket details
            eventDetail.currentEntries += amounts[i];
            eventDetail.ticketsRedeemed[msg.sender][ticketIds[i]] += amounts[i];
        }
        emit TicketRedeemed(eventId, ticketIds, amounts); // This event can be adjusted or looped based on your requirements
    }

    function refundTicketsWithProof(
        uint256 eventId,
        uint256[] memory ticketIds,
        address lowerBound,
        address upperBound,
        bytes32[] calldata merkleProof
    ) external {
        require(validateNonInclusion(eventId, lowerBound, upperBound, merkleProof), "User was honored or proof is incorrect");

        EventDetail storage eventDetail = events[eventId];

        for (uint i = 0; i < ticketIds.length; i++) {
            uint256 amountToRefund = eventDetail.ticketsRedeemed[msg.sender][ticketIds[i]];
            require(amountToRefund > 0, "No tickets to refund for this ID");

            // Update event details before transfer to ensure state consistency
            eventDetail.currentEntries -= amountToRefund;
            eventDetail.ticketsRedeemed[msg.sender][ticketIds[i]] = 0;

            // Transfer ERC1155 tokens back to the user
            tokenContract.safeTransferFrom(address(this), msg.sender, ticketIds[i], amountToRefund, "");
            emit TicketRefunded(eventId, ticketIds[i], amountToRefund); // This event can be adjusted or looped based on your requirements
        }
    }

    function createEvent(
        uint32 _startTime,
        uint32 _endTime,
        uint256 _minEntries,
        uint256 _maxEntries,
        string memory _imageUri,
        uint256[] memory _ticketIds,
        TicketDetail[] memory _ticketDetails
    ) external onlyOwner returns (uint256) {
        require(_ticketIds.length == _ticketDetails.length, "Must be same length.");
        require(_endTime > block.timestamp - 1, "Must be non-trivial event time window");

        uint256 eventId = uint256(keccak256(abi.encodePacked(_startTime, _endTime, _minEntries, _maxEntries, _imageUri, block.timestamp)));
        require(events[eventId].endTime == 0, "Event must not exist");
        events[eventId].startTime = _startTime;
        events[eventId].endTime = _endTime;
        events[eventId].minEntries = _minEntries;
        events[eventId].maxEntries = _maxEntries;
        events[eventId].imageUri = _imageUri;
        events[eventId].status = uint32(block.timestamp) < _startTime ? EventStatus.Pending : EventStatus.Active;

        emit EventDetails(eventId, _startTime, _endTime, _minEntries, _maxEntries, _imageUri, EventStatus.Pending);

        for (uint256 i = 0; i < _ticketIds.length; i++) {
            require(_ticketDetails[i].maxAmount != 0, "Must have non-trivial maximum ticket amount");

            events[eventId].ticketDetails[_ticketIds[i]] = _ticketDetails[i];
        }
        emit TicketDetails(eventId, _ticketIds, _ticketDetails);

        return eventId;
    }
}
