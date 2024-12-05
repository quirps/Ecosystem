pragma solidity ^0.8.9;

import { ERC1155 } from "../facets/Tokens/ERC1155/ERC1155.sol";
import "../facets/Tokens/ERC1155/ERC1155Receiver.sol";
import { IERC1155 } from "../facets/Tokens/ERC1155/interfaces/IERC1155.sol";
import { IERC1155MetadataURI } from "../facets/Tokens/ERC1155/interfaces/IERC1155MetadataURI.sol";
import { iERC1155Transfer } from "../facets/Tokens/ERC1155/internals/iERC1155Transfer.sol";
contract ERC1155Rewards is  ERC1155Receiver, ERC1155, iERC1155Transfer { 
    uint64 constant TIME_POOL_TOKEN_DECIMALS = 10**18;

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == this.onERC1155Received.selector || 
            interfaceId == this.onERC1155BatchReceived.selector ||
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ;
    }
}
    