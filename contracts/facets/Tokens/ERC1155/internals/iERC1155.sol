pragma solidity ^0.8.0;

import "../libraries/LibERC1155.sol";
import "./iERC1155ContractTransfer.sol";
import "../interfaces/IERC1155Transfer.sol";
import "../interfaces/IERC1155Receiver.sol";
import "../../../../libraries/utils/Address.sol";

import {iOwnership} from "../../../Ownership/_Ownership.sol";


contract iERC1155 is iERC1155ContractTransfer, iOwnership {
    using Address for address;

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal {
        LibERC1155.ERC1155Storage storage es = LibERC1155.erc1155Storage();
        es.uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal {
        require(to != address(0), "ERC1155: mint to the zero address");

        LibERC1155.ERC1155Storage storage es = LibERC1155.erc1155Storage();
        address operator = msgSender();
        uint256[] memory ids = LibERC1155._asSingletonArray(id);
        uint256[] memory amounts = LibERC1155._asSingletonArray(amount);

        es.balance[id][to] += amount;
        es.totalSupply += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        uint256 _totalSupply;
        LibERC1155.ERC1155Storage storage es = LibERC1155.erc1155Storage();

        address operator = msgSender();

        for (uint256 i = 0; i < ids.length; i++) {
            es.balance[ids[i]][to] += amounts[i];
            _totalSupply += amounts[i];
        }
        es.totalSupply = _totalSupply;
        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address from, uint256 id, uint256 amount) internal {
        require(from != address(0), "ERC1155: burn from the zero address");

        LibERC1155.ERC1155Storage storage es = LibERC1155.erc1155Storage();

        address operator = msgSender();
        uint256[] memory ids = LibERC1155._asSingletonArray(id);
        uint256[] memory amounts = LibERC1155._asSingletonArray(amount);

        uint256 fromBalance = es.balance[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        require(es.totalSupply >= amount, "Exceeds total supply.");
        unchecked {
            es.balance[id][from] = fromBalance - amount;
            es.totalSupply -= amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) internal {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        LibERC1155.ERC1155Storage storage es = LibERC1155.erc1155Storage();
        address operator = msgSender();

        uint256 _totalAmount;
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            _totalAmount += amount;

            uint256 fromBalance = es.balance[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            require(es.totalSupply >= _totalAmount, "Exceeds total supply.");
            unchecked {
                es.balance[id][from] = fromBalance - amount;
            }
        }
        es.totalSupply -= _totalAmount;

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    
}
