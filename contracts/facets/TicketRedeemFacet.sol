pragma solidity ^0.8.9;

import "../internals/ERC1155/iERC1155Transfer.sol";

/**
 * Gas efficient way to use time intervals
 * Mapping? Wouldn't reference times on-chain
 * Use event to emit Window object
 * mapping with key being start and end time concatenated? Only way to prevent
 */
contract TicketRedeemFacet is iERC1155Transfer {
    //Each window has a mapping per type
    /**
     * Create a list of start and stop times
     * How to do ticketIds and maxTickets in gas efficient way?
     * Must create mapping of allowed tickets
     */

    struct EventTickets {
        uint256[] ticketIds;
        uint256[] maxTickets;
        uint32[] startTimes;
        uint32[] endTimes;
    }
    struct EventTicketInfo{
        uint256 ticketId;
        uint256 maxTickets;
    }
    mapping(uint256 => mapping(address => uint256)) ticketsPerWindow;
    mapping(uint256 => EventTickets) redeemEvent;
    mapping(uint256 => mapping(uint256 => uint256)) ticketIdMax;
    mapping(uint32 => mapping(uint32 => bool)) windowOnTime;

    event TicketEvent(uint256 ticketId, uint32[] startTimes, uint32[] endTimes,  uint256[] ticketIds, uint256[] maxAmounts);
    event RedeemEvent(uint256 eventId, uint256[] ticketIds, uint256[] amounts);

    function setTicketEvent(uint256[] ticketIds, uint256[] maxTickets, uint32[] startTimes, uint32[] endTimes) internal {
        uint256 ticketEventId = uint256(keccak256(abi.encode(startTimes, endTimes, ticketIds, maxTickets)));
        redeemEvent[ticketEventId] = EventTickets(ticketIds, maxTickets, startTimes, endTimes);
        require(startTimes.length == endTimes.length, "WL - Start times and End Times lengths must match.");
        for (uint256 i; i < startTimes.length; i++) {
            require(startTimes[i] < endTimes[i], "WT - Start time should be less than it's corresponding end time.");
            windowOnTime[startTimes[i]][endTimes[i]] = true;
        }
        require(ticketIds.length == maxTickets.length, "WT - TicketIds and MaxTickets must have same length.");
        for (uint256 i; i < ticketIds.length; i++) {
            ticketIdMax[ticketEventId ][ticketIds[ i ] ] = maxTickets[ i ];
        }
        emit TicketEvent(ticketEventId, startTimes, endTimes);
    }

    function redeemTicket(uint32 startTime, uint32 endTime, uint256 ticketEventId, uint256[] ticketIds, uint256[] amounts) internal {
        //check window open for id
        //check max tickets constraint
        //transfer
        //event
        uint16 _maxTickets;
        require(windowOnTime[startTime][endTime], "VW - This is not a valid window.");

        require(block.timestamp >= startTime && block.timestamp <= endTime, "IW - Window is currently not open.");

        EventTickets storage _eventTickets = redeemEvent[eventId];
        _maxTickets = _eventTickets.maxTickets;

        require(block.timestamp > startTime && block.timestamp < endTime, "RT - Must redeem ticket during the window.");
        require(ticketIds.length == amounts.length, "WT - TicketIds and Amounts must have same length.");

        for(uint256 i; i < ticketIds.length; i++){
            require(ticketIdMax[ ticketEventId ][ ticketId[i] ] > 0, "IT - Invalid ticket for this event." );
            //require tokenId valid (maxAmount > 0 )
            //check amount less than maxAmount
            //safeTransferFrom

        }
            require(ticketsPerWindow[id][msgSender()] < _maxTickets, "MT - Max Tickets per window is being exceeded.");
        _safeTransferFrom(address(this), msgSender(), _ticketId, amounts[], ids[], "");
        emit RedeemEvent(id);
    }
}
