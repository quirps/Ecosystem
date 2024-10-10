// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LibOwnership.sol";
import "../../ERC2771Recipient.sol";

contract iOwnership is iERC2771Recipient {
    modifier onlyOwner(){
        msgSender() == _getOwner();
        _;
    }
    function _transferOwnership(address _newOwner) internal  {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setContractOwner(_newOwner);
    }

    function _getOwner() internal view returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }
}
