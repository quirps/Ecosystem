pragma solidity ^0.8.0;

import "../../abstract/aERC1155Hooks.sol";

contract iERC1155Hooks is aERC1155Hooks {

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal view override {}

    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal view override {}
}
