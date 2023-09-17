// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibDiamond } from "../libraries/LibDiamond.sol";

contract iOwnership {
    function _transferOwnership(address _newOwner) internal  {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setContractOwner(_newOwner);
    }

    function _owner() internal view returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }
}
