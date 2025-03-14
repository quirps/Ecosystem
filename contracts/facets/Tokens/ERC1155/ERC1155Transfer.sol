// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./interfaces/IERC1155.sol";
import "./interfaces/IERC1155Receiver.sol";
import "./interfaces/IERC1155MetadataURI.sol";
import "./interfaces/IERC1155Transfer.sol";
import "./internals/iERC1155.sol";
import "../../../libraries//utils/Address.sol";
import "../../../libraries/utils/Context.sol";
import "./libraries/LibERC1155.sol";
import "./internals/iERC1155Transfer.sol";
/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Transfer is    iERC1155Transfer {
    using Address for address;
    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to, 
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public   {
        require(
            from == msgSender() || isApprovedForAll(from, msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public  {
        require(
            from == msgSender() || isApprovedForAll(from, msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public  {
        _setApprovalForAll(msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view  returns (bool) {
        LibERC1155.ERC1155Storage storage es = LibERC1155.erc1155Storage();

        return es.operatorApprovals[account][operator];
    }
    
}
