pragma solidity ^0.8.6;

import "../interfaces/IERC1155Transfer.sol";


contract TestERC1155Operator{
    address immutable diamond;
    constructor(address _diamond){
        diamond = _diamond;
    }
    function safeTransferFrom(address to, address from, uint256 id, uint256 amount,
    bytes memory data) external {
        IERC1155Transfer(diamond).safeTransferFrom(to, from, id, amount, data);
    }

    function safeBatchTransferFrom(address to, address from, uint256[] memory id, uint256[] memory amount,
    bytes memory data) external {
        IERC1155Transfer(diamond).safeBatchTransferFrom(to, from, id, amount, data);
    }
    

}