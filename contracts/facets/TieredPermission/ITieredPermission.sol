pragma solidity ^0.8.28;

interface ITieredPermission{
    function isAppCreator( address creator ) external view returns (bool isAppCreator_);
}