pragma solidity ^0.8.9;

import "../internals/ERC1155/iERC1155Transfer.sol";
import "../libraries/utils/Context.sol";

/**
Event is considered all windows combined. Max tickets are all windows combined.
 */
contract TicketRedeemFacet is Context, iERC1155Transfer {
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
    struct EventTicketInfo {
        uint256 ticketId;
        uint256 maxTickets;
    }
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) userMaxAmount;
    mapping(uint256 => EventTickets) redeemEvent;
    mapping(uint256 => mapping(uint256 => uint256)) userTicketIdMax;
    mapping(uint256 => mapping(uint256 => uint256)) eventTicketIdMax;
    mapping(uint32 => mapping(uint32 => bool)) windowOnTime;

    event TicketEvent(uint256 ticketId, uint32[] startTimes, uint32[] endTimes, uint256[] ticketIds, uint256[] userMaxAmounts);
    event RedeemEvent(uint256 eventId, uint256[] ticketIds, uint256[] amounts);

    function setTicketEvent(uint256[] memory ticketIds, uint256[] memory maxTickets, uint32[] memory startTimes, uint32[] memory endTimes) internal {
        uint256 ticketEventId = uint256(keccak256(abi.encode(startTimes, endTimes, ticketIds, maxTickets)));
        redeemEvent[ticketEventId] = EventTickets(ticketIds, maxTickets, startTimes, endTimes);
        require(startTimes.length == endTimes.length, "WL - Start times and End Times lengths must match.");
        for (uint256 i; i < startTimes.length; i++) {
            require(startTimes[i] < endTimes[i], "WT - Start time should be less than it's corresponding end time.");
            windowOnTime[startTimes[i]][endTimes[i]] = true;
        }
        require(ticketIds.length == maxTickets.length, "WT - TicketIds and MaxTickets must have same length.");
        for (uint256 i; i < ticketIds.length; i++) {
            userTicketIdMax[ticketEventId][ticketIds[i]] = maxTickets[i];
        }
        emit TicketEvent(ticketEventId, startTimes, endTimes, ticketIds, maxTickets);
    }

    function redeemTicket(uint32 startTime, uint32 endTime, uint256 ticketEventId, uint256[] memory ticketIds, uint256[] memory amounts) internal {
        //check window open for id
        //check max tickets constraint
        //transfer
        //event
        require(windowOnTime[startTime][endTime], "VW - This is not a valid window.");

        require(block.timestamp >= startTime && block.timestamp <= endTime, "IW - Window is currently not open.");

        //require(eventTicketIdMax[ticketEventId][ticketId],"MT - No more tickets can be submitted for this ticket type.");
        require(ticketIds.length == amounts.length, "WT - TicketIds and Amounts must have same length.");

        for (uint256 i; i < ticketIds.length; i++) {
            uint256 _userMaxAmount = userTicketIdMax[ticketEventId][ticketIds[i]];
            uint256 currentUserAmount = userMaxAmount[ticketEventId][msgSender()][ticketIds[i]];
            require(currentUserAmount + amounts[i] < _userMaxAmount, "OM - Over the maximum tickets for this type in the current window");
        }
        _safeBatchTransferFrom(address(this), msgSender(), ticketIds, amounts, "");
        emit RedeemEvent(ticketEventId, ticketIds, amounts);
    }

    //riemburse users a given amount of a specific ticketId
    //only owner/moderator
    function reimburse(uint256[] memory eventId, address[] memory user, uint256[] memory ticketId, uint256[] memory amount) external {
        require(
            (user.length == ticketId.length) && (ticketId.length == amount.length) && (amount.length == eventId.length),
            "ST - Input lengths must be equivalent to each other."
        );
        for (uint256 i; i < user.length; i++) {
            //check reimburse doesn't exceed redeem
            require(
                userMaxAmount[eventId[i]][user[i]][ticketId[i]] <= userTicketIdMax[eventId[i]][ticketId[i]],
                "RD - Can only reimburse the amount of tickets currently redeemed."
            );
            _safeTransferFrom(msgSender(), user[i], ticketId[i], amount[i], "");
        }
    }
    function cancelEvent() external {

    }
}
