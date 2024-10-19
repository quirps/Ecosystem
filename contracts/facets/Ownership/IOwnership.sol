// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOwnership {
    function setEcosystemOwner(address _newOwner) external;

    function ecosystemOwner() external   view returns (address owner_);
}
