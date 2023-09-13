// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract EventFactory {
    struct TicketDetail {
        uint256 minAmount;
        uint256 maxAmount;
    }

    struct EventDetail {
        uint32 startTime;
        uint32 endTime;
        uint256 minEntries;
        uint256 maxEntries;
        uint256 currentEntries;
        bytes imageUri;
        mapping(uint256 => TicketDetail) ticketDetails;  // ticketId to TicketDetail
    }

    address public owner;
    IERC1155 public trustedTokenContract;
    mapping(uint256 => EventDetail) public events;  // eventId to EventDetail
    event EventCreated(uint256 eventId);
    event TicketRedeemed(uint256 eventId, uint256 ticketId, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(address _trustedTokenContract) {
        owner = msg.sender;
        trustedTokenContract = IERC1155(_trustedTokenContract);
    }
    function setUri( 
        uint256 eventId,
        bytes memory imageLink
    ) external onlyOwner{

    }
    function createEvent(
        uint256 eventId,
        uint32 startTime,
        uint32 endTime,
        uint256 minEntries,
        uint256 maxEntries
    ) public onlyOwner {
        require(endTime > startTime, "End time must be greater than start time");

        EventDetail storage newEvent = events[eventId];
        newEvent.startTime = startTime;
        newEvent.endTime = endTime;
        newEvent.minEntries = minEntries;
        newEvent.maxEntries = maxEntries;
        newEvent.currentEntries = 0;

        emit EventCreated(eventId);
    }

    function setTicketDetails(
        uint256 eventId,
        uint256 ticketId,
        uint256 minAmount,
        uint256 maxAmount
    ) public onlyOwner {
        require(events[eventId].startTime > 0, "Event must exist");

        TicketDetail storage newTicketDetail = events[eventId].ticketDetails[ticketId];
        newTicketDetail.minAmount = minAmount;
        newTicketDetail.maxAmount = maxAmount;
    }

    function redeemTicket(
        uint256 eventId,
        uint256 ticketId,
        uint256 amount
    ) public {
        EventDetail storage eventDetail = events[eventId];
        TicketDetail storage ticketDetail = eventDetail.ticketDetails[ticketId];

        require(block.timestamp >= eventDetail.startTime && block.timestamp <= eventDetail.endTime, "Event not active");
        require(eventDetail.currentEntries < eventDetail.maxEntries, "Event at max entries");
        require(amount >= ticketDetail.minAmount && amount <= ticketDetail.maxAmount, "Invalid ticket amount");

        // Transfer ERC1155 tokens from user to contract
        trustedTokenContract.safeTransferFrom(msg.sender, address(this), ticketId, amount, "");

        // Update event and ticket details
        eventDetail.currentEntries += amount;
        emit TicketRedeemed(eventId, ticketId, amount);
    }
}
