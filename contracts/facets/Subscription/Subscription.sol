pragma solidity ^0.8.28;
/**
Dogma - Subscriptions are tickets that have a fixed duration of validation and must be consumed to start this duration. 
They are recurring so will have a method to automatically debit another purchase. 

Purchases happen on the marketplace, meaning this will need to be done externally, at least the purchasing part. 
Unsure, need to resolve this.

 */
contract Subcription{
    event GiftedSubscription(address from, address to, uint256 ticketId, uint256 amount);
    function subscribe( address _subscriber, uint256 _ticketId, uint256 _amount) external {
        if ( msgSender() != _subscriber ){
            emit GiftedSubscription(msgSender(), _subscriber, )
        }
    }
}