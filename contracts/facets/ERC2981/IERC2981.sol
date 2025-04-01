// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Interface for the ERC2981 - NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Called with the sale price to determine royalty payment details.
     * @param tokenId The NFT identifier.
     * @param salePrice The sale price of the NFT. Must be in the units of the payment token.
     * @return receiver Address of who should receive royalties.
     * @return royaltyAmount Amount of royalties owed, calculated as a function of `salePrice` and royalty basis points. Must be in the units of the payment token.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}