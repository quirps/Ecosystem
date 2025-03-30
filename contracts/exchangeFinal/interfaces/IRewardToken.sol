// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @title IRewardToken Interface
 * @dev Extends IERC1155 with functions specific to the reward token contract.
 */
interface IRewardToken is IERC1155 {
    /**
     * @notice Mints `amount` tokens of token type `id` to `to`.
     * @dev Restricted to authorized minters (ExchangeRewards contract).
     * @param to The address that will receive the minted tokens.
     * @param id The token type to mint.
     * @param amount The amount of tokens to mint.
     * @param data Additional data with no specified format.
     */
    function mint(address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @notice Burns `amount` tokens of token type `id` from `from`.
     * @dev Restricted to authorized burners (ExchangeRewards contract).
     * @param from The address that will lose the burned tokens.
     * @param id The token type to burn.
     * @param amount The amount of tokens to burn.
     */
    function burnFrom(address from, uint256 id, uint256 amount) external;

    /**
     * @notice Returns the total supply of a specific token ID.
     * @param id The token ID.
     * @return The total supply.
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @notice Checks if a token ID corresponds to an enhancement NFT.
     * @param id The token ID.
     * @return bool True if it's an enhancement NFT, false otherwise.
     */
    function isEnhancementNFT(uint256 id) external pure returns (bool);

    /**
     * @notice Locks or unlocks an enhancement NFT, preventing/allowing transfer.
     * @dev Restricted caller (ExchangeRewards contract).
     * @param nftId The enhancement NFT token ID.
     * @param locked True to lock, false to unlock.
     */
    function setNFTLocked(uint256 nftId, bool locked) external;

    /**
      * @notice Emitted when an NFT's locked status changes.
      */
    event NFTLockedStatusChanged(uint256 indexed nftId, bool locked);

    /**
     * @notice Emitted when enhancement NFTs are minted by the owner.
     */
     event OwnerMintedEnhancementNFT(address indexed to, uint256 indexed id, uint256 amount);

}