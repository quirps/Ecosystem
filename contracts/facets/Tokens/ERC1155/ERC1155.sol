// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./interfaces/IERC1155.sol";
import "./interfaces/IERC1155Receiver.sol";
import "./interfaces/IERC1155MetadataURI.sol";
import "./internals/iERC1155.sol";
import "../../../libraries/utils/Address.sol";
import "../../../libraries/utils/Context.sol"; 
import "./libraries/LibERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Ecosystem is  iERC1155, IERC1155, IERC1155MetadataURI {
    using Address for address;
    using Strings for uint256;
    
    uint256 constant PREMIUM_VOTER_PASS_TOKEN_ID = uint256(5);
    uint256 constant PREMIUM_VOTER_PASS_MINT_AMOUNT = uint256(1);

    event URIChanged( string uri );
     
    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        LibERC1155.ERC1155Storage storage es = LibERC1155.erc1155Storage();

        // Convert tokenId to string
        string memory tokenIdStr = tokenId.toString();

        // Concatenate base URI, tokenId, and .json suffix
        return string(abi.encodePacked(es.uri, tokenIdStr, ".json"));
    }

     function setUri(string memory _uri) public  {
        LibERC1155.ERC1155Storage storage es = LibERC1155.erc1155Storage();
        es.uri = _uri;
        emit URIChanged( _uri );
    }


    function mint(address to, uint256 id, uint256 amount, bytes memory data) external override {
        _mint(to, id, amount, data);
    }

/*

 */
    function mintPremiumVoterPass() external {
        _mint(msgSender(), uint256(5), uint256(1), "");
    }
    function mintBatch(
            address to,
            uint256[] memory ids,
            uint256[] memory amounts,
            bytes memory data
        ) external override {
        _mintBatch( to, ids, amounts, data);
        }

    function burn(address from, uint256 id, uint256 amount) external override {
        _burn( from, id, amount); 
    }
    function burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) external override {
        _burnBatch(from, ids, amounts);
    }
   
}
