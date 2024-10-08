// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @dev _Available since v3.1._
 */
contract iERC1155Receiver   {

    function _onERC1155Received(
    ) internal pure returns (bytes4){
        return 0xf23a6e61;
    }
    function _onERC1155BatchReceived(
    ) internal pure returns (bytes4){
        return 0xbc197c81;
    }
}
