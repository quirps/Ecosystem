// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "../internals/ERC1155/iERC1155Transfer.sol";

contract EventFactory is iERC1155Transfer {
    struct EventDetails {
        uint32 startTime;
        uint32 endTime;
        bool isCancelled;
    }

    struct TokenDetails {
        uint256 limitPerUser;
        uint256 totalLimit;
        uint256 currentTotal;
    }
    address owner;
    // Mapping from event ID to EventDetails
    mapping (uint256 => EventDetails) public events;
    // Mapping from event ID to token ID to TokenDetails
    mapping (uint256 => mapping(uint256 => TokenDetails)) public tokenDetails;
    // Mapping from event ID to user's token amount
    mapping (uint256 => mapping(uint256 => mapping(address => uint256))) public userTokens;

    modifier onlyModerator(){
        require(msgSender() == owner);
        _;
    }
    
    constructor(){
        owner = msgSender();
    }
    function createEvent(uint256 eventId, uint32 startTime, uint32 endTime) external  {
        require(endTime > startTime, "End time must be greater than start time");

        EventDetails memory newEvent = EventDetails({
            startTime: startTime,
            endTime: endTime,
            isCancelled: false
        });

        events[eventId] = newEvent;
    }

    function setTokenDetails(uint256 eventId, uint256 tokenId, uint256 limitPerUser, uint256 totalLimit) external  {
        require(totalLimit >= limitPerUser, "Total limit must be greater or equal to limit per user");

        TokenDetails memory newTokenDetails = TokenDetails({
            limitPerUser: limitPerUser,
            totalLimit: totalLimit,
            currentTotal: 0
        });

        tokenDetails[eventId][tokenId] = newTokenDetails;
    }

    function submitTokens(uint256 eventId, uint256 tokenId, uint256 amount) external {
        EventDetails memory eventDetails = events[eventId];
        TokenDetails storage tokenDetailsForEvent = tokenDetails[eventId][tokenId];
        require(block.timestamp >= eventDetails.startTime && block.timestamp <= eventDetails.endTime, "The event is not active");
        require(!eventDetails.isCancelled, "The event has been cancelled");
        require(tokenDetailsForEvent.currentTotal + amount <= tokenDetailsForEvent.totalLimit, "Exceeds total limit");
        require(userTokens[eventId][tokenId][msg.sender] + amount <= tokenDetailsForEvent.limitPerUser, "Exceeds user limit");

        _safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        userTokens[eventId][tokenId][msg.sender] += amount;
        tokenDetailsForEvent.currentTotal += amount;
    }

    function reimburseUser(uint256 eventId, uint256 tokenId, uint256 amount) external {
        require(userTokens[eventId][tokenId][msg.sender] >= amount, "Not enough tokens to reimburse");

        _safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
        userTokens[eventId][tokenId][msg.sender] -= amount;
        tokenDetails[eventId][tokenId].currentTotal -= amount;
    }

    function cancelEvent(uint256 eventId) external  {
        EventDetails storage eventDetails = events[eventId];
        require(block.timestamp < eventDetails.endTime, "The event has ended");

        eventDetails.isCancelled = true;
    }

    function withdrawTokens(uint256 eventId, uint256 tokenId) external {
        EventDetails memory eventDetails = events[eventId];
        require(eventDetails.isCancelled, "The event has not been cancelled");

        uint256 userTokenAmount = userTokens[eventId][tokenId][msg.sender];
        _safeTransferFrom(address(this), msg.sender, tokenId, userTokenAmount, "");
        userTokens[eventId][tokenId][msg.sender] = 0;
        tokenDetails[eventId][tokenId].currentTotal -= userTokenAmount;
    }
}
