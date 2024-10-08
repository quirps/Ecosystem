// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "./internals/iERC1155Receiver.sol";
import "./interfaces/IERC1155Receiver.sol";
/**
 * @dev _Available since v3.1._
 */
contract ERC1155Receiver is  IERC1155Receiver,iERC1155Receiver  {

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4){
        return _onERC1155Received();
    }
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4){
        return _onERC1155BatchReceived();
    }
}
