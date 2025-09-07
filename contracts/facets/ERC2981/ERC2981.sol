pragma solidity ^0.8.28;

import { LibERC2981 } from "./LibERC2981.sol";   
import { iERC2981 } from "./_ERC2981.sol";
contract ERC2981 is iERC2981{
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
       (receiver, royaltyAmount) =  _royaltyInfo(tokenId, salePrice);
    }
}