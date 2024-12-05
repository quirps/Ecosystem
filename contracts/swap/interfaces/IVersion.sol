pragma solidity ^0.8.9;


interface IVersion{
    function getVersion()external;
    function isEcosystem() external pure returns (bool);
}