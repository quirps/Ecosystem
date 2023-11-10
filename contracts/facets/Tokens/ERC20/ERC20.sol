// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/utils/Context.sol";
import "../libraries/utils/Ownable.sol";
import "../libraries/LibERC20.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/LibERC1155.sol";
import "../internals/ERC1155/iERC1155Transfer.sol";


contract ERC20 is Context,  iERC1155Transfer {
    uint256 public immutable primaryCurrencyId; 

    constructor( uint256 _primaryCurrencyId){
        primaryCurrencyId = _primaryCurrencyId;
    }
    function setName(string memory _name) LibDiamond.onlyOwner external {
        LibERC20._setName(_name);
    }
    function setSymbol(string memory _symbol) onlyOwner external{
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
        return LibERC1155.getBalance(primaryCurrencyId, account);
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        bool approvalStatus = LibERC1155.getOperatorApproval(owner, spender);
        return approvalStatus ? type(uint256).max : type(uint256).min; // Replace with appropriate allowance logic
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _safeTransferFrom(msgSender(), recipient, primaryCurrencyId, amount, "");
        return true;
    }
   
    function approve(address spender, uint256 amount) external  returns (bool) {
        _setApprovalForAll(msgSender(), spender, amount != 0);
        return true; 
    }

    function transferFrom(address sender, address recipient, uint256 amount) external  returns (bool) {
        _safeTransferFrom(sender, recipient, primaryCurrencyId, amount, "");
        return false; // Replace with appropriate transferFrom logic
    }
}
