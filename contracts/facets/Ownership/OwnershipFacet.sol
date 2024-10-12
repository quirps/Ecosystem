// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {iOwnership} from "./_Ownership.sol"; 

contract OwnershipFacet is iOwnership {
    function setEcosystemOwner(address _newOwner) external {
        _setEcosystemOwner(_newOwner);  
    }

    function ecosystemOwner() external   view returns (address owner_) {
        owner_ = _ecosystemOwner(); 
    }
}
