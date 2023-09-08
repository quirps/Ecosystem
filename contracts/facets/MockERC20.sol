// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockERC20 is Ownable {
    IERC1155 public erc1155;
    uint256 public constant tokenId = 0;

    constructor(address _erc1155Address) {
        erc1155 = IERC1155(_erc1155Address);
    }

    function name() public pure returns (string memory) {
        return "MockERC20Token";
    }

    function symbol() public pure returns (string memory) {
        return "M20T";
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        // Assuming the ERC1155 contract implements a function to get the total supply for a token ID
        // If not, this function will need to be removed or modified
        // return erc1155.totalSupply(tokenId);
        return 0; // Replace with appropriate total supply logic
    }

    function balanceOf(address account) public view returns (uint256) {
        return erc1155.balanceOf(account, tokenId);
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        // ERC1155 does not have an allowance concept by default. 
        // If your ERC1155 contract implements allowance, use it here.
        // Otherwise, you will need to implement an allowance mapping in this contract.
        return 0; // Replace with appropriate allowance logic
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        erc1155.safeTransferFrom(msg.sender, recipient, tokenId, amount, "");
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        // ERC1155 does not have an approve function by default.
        // If your ERC1155 contract implements it, use it here.
        // Otherwise, you will need to implement an approval system in this contract.
        return false; // Replace with appropriate approve logic
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        // ERC1155 does not have a transferFrom function by default. 
        // If your ERC1155 contract implements it, use it here.
        // Otherwise, you will need to implement transferFrom functionality in this contract.
        return false; // Replace with appropriate transferFrom logic
    }
}
