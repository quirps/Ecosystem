pragma solidity ^0.8.28;


interface IEventLogic {
    function participate(
        uint256 eventId,
        address user,
        uint256 /* ticketId */, // Parameters passed but might not be needed here
        uint256 /* amount */,
        bytes calldata /* data */
    ) external; 
}