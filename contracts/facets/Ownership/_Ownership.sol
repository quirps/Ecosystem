// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibOwnership} from "./LibOwnership.sol";
import {iERC2771Recipient} from "../ERC2771Recipient/_ERC2771Recipient.sol";     

contract iOwnership is iERC2771Recipient {
    modifier onlyOwner(){
        msgSender() == _ecosystemOwner();
        _;
    }
    function _setEcosystemOwner( address _newOwner) internal {
        isEcosystemOwnerVerification();
        LibOwnership._setEcosystemOwner(_newOwner);
    }

    function _ecosystemOwner() internal view returns (address owner_) {
        owner_ = LibOwnership._ecosystemOwner();
    }

    function isEcosystemOwnerVerification() internal view {
        require( msgSender() == _ecosystemOwner(), "Must be the Ecosystem owner"); 
    }
}
 