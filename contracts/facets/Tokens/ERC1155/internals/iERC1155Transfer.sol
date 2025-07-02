pragma solidity ^0.8.0;

import {iERC2771Recipient} from "../../../ERC2771Recipient/_ERC2771Recipient.sol";    
import "../libraries/LibERC1155.sol";
import "./iERC1155ContractTransfer.sol";
import "../interfaces/IERC1155Transfer.sol";

contract iERC1155Transfer is iERC1155ContractTransfer, iERC2771Recipient {
    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */

    function _safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) internal {
        require(to != address(0), "ERC1155: transfer to the zero address");
        LibERC1155.ERC1155Storage storage es = LibERC1155.erc1155Storage();
        address operator = msgSender(); 

        uint256 fromBalance = es.balance[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            es.balance[id][from] = fromBalance - amount;
        }
        es.balance[id][to] += amount;
        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        LibERC1155.ERC1155Storage storage es = LibERC1155.erc1155Storage();
        address operator = msgSender();

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = es.balance[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                es.balance[id][from] = fromBalance - amount;
            }
            es.balance[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal {
        require(owner != operator, "ERC1155: setting approval status for self");

        LibERC1155.ERC1155Storage storage es = LibERC1155.erc1155Storage();
        es.operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _balanceOf(address account, uint256 id) internal view returns (uint256 amount_){
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return LibERC1155.getBalance(id, account);        
         
    }
     
}

