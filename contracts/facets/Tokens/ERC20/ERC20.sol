// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../libraries/utils/Context.sol";
import "../../../libraries/utils/Ownable.sol"; 
import "./libraries/LibERC20.sol"; 
import "../../Ownership/LibOwnership.sol";  
import "../ERC1155/libraries/LibERC1155.sol";
import "../ERC1155/internals/iERC1155Transfer.sol";
 
import {iOwnership} from "../../Ownership/_Ownership.sol";

contract ERC20 is  iOwnership, iERC1155Transfer {
    function setName(string memory _name)  public {
        isEcosystemOwnerVerification(); 
        LibERC20._setName(_name);
    }
    function setSymbol(string memory _symbol) public{
        isEcosystemOwnerVerification();
        LibERC20._setSymbol(_symbol);
    }


    //ERC20
    function name() external view returns (string memory) {
        return LibERC20.getName();
    }

    function symbol() external view returns (string memory) {
      return LibERC20.getSymbol();
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        // Assuming the ERC1155 contract implements a function to get the total supply for a token ID
        // If not, this function will need to be removed or modified
        // return erc1155.totalSupply(tokenId);
        return 0; // Replace with appropriate total supply logic
    }

    function balanceOf(address account) external view returns (uint256) {
        return LibERC1155.getBalance(LibERC20.PRIMARY_CURRENCY_ID, account);
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        bool approvalStatus = LibERC1155.getOperatorApproval(owner, spender);
        return approvalStatus ? type(uint256).max : type(uint256).min; // Replace with appropriate allowance logic
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _safeTransferFrom(msgSender(), recipient, LibERC20.PRIMARY_CURRENCY_ID, amount, "");
        return true;
    }
   
    function approve(address spender, uint256 amount) external  returns (bool) {
        _setApprovalForAll(msgSender(), spender, amount != 0);
        return true; 
    }

    function approvePermit(address owner, address spender, uint256 amount) internal returns (bool){
        _setApprovalForAll(owner, spender, amount != 0);
    }
    function transferFrom(address sender, address recipient, uint256 amount) external  returns (bool) {
        _safeTransferFrom(sender, recipient, LibERC20.PRIMARY_CURRENCY_ID, amount, "");
        return false; // Replace with appropriate transferFrom logic
    }
}
