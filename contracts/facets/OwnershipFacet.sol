// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC173 } from "../interfaces/IERC173.sol";
import {iOwnership} from "../internals/iOwnership.sol";

contract OwnershipFacet is IERC173, iOwnership{
    function transferOwnership(address _newOwner) external override {
        _transferOwnership(_newOwner);
    }

    function owner() external override view returns (address owner_) {
        owner_ = _owner();
    }
}
