pragma solidity ^0.8.0;


library LibERC1155{
    bytes32 constant STORAGE_ERC1155 = "diamond.storage.erc1155";

    struct StorageERC1155{
         // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256))  _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool))  _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string  _uri;
    }
    function storageERC1155 ( ) internal pure returns ( StorageERC1155 storage es_){
        bytes32 erc1155_key = STORAGE_ERC1155;
        assembly{
            es_.slot := erc1155_key
        }
    }
}