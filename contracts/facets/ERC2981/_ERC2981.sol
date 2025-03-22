pragma solidity ^0.8.28;

import { LibERC2981 } from "./LibERC2981.sol";   
import { iOwnership } from "../Ownership/_Ownership.sol"; 
contract iERC2981 is iOwnership{
    event RoyaltyFeeAccessed( address sender, uint256 tokenId, uint256 salePrice, uint256 royaltyAmount);
      // EIP-2981 royalty info
    function _royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) internal  returns (address receiver, uint256 royaltyAmount) {
        LibERC2981.ERC2981Storage storage es = LibERC2981.erc2981torage();
        uint256 _royalteFee = es.royaltyFee[ tokenId ];  
   
        receiver = _ecosystemOwner();
        royaltyAmount = ( salePrice * _royalteFee ) / 100000; // Basis points calculation
        
        emit RoyaltyFeeAccessed(msgSender(), tokenId, salePrice, royaltyAmount); 

    }
}