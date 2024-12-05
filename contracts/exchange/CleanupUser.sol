pragma solidity ^0.8.9;



/**
 * @title 
 * @author 
 * @dev Sole purpose is to stake 1 wei of every time slot that has a transaction in order to  
 *      prevent dead tokens.
 */
contract CleanupUser{
    address cleanupAddress;
    uint256 constant CLEANUP_STAKE_AMOUNT = 1;
    mapping( address => mapping(uint32 => bool)) collected;

}   