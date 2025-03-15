pragma solidity ^0.8.28;


contract ReentrancyGuardContract{
    bool transient isLocked;
    modifier ReentrancyGuard{
        isLocked = true;
        _;
        isLocked = false;
    }
}