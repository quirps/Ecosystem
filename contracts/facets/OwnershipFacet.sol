// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC173 } from "../interfaces/IERC173.sol";
import {iOwnershipFacet} from "../internals/iOwnershipFacet.sol";

contract OwnershipFacet is IERC173, iOwnershipFacet {
    function transferOwnership(address _newOwner) external override {
        _transferOwnership(_newOwner);
    }

    function owner() external override view returns (address owner_) {
        owner_ = _owner();
    }
}
