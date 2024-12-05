// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../facets/Tokens/ERC1155/interfaces/IERC1155Receiver.sol";
import "../IERC165.sol";

contract MyERC1155Receiver is IERC1155Receiver, IERC165 {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) { 
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return interfaceId == this.onERC1155Received.selector || 
            interfaceId == this.onERC1155BatchReceived.selector ||
            interfaceId == 0x01ffc9a7; // ERC165 interface ID
        }
}
