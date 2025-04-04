pragma solidity ^0.8.0;

library LibERC1155 {
    bytes32 constant STORAGE_ERC1155 = "diamond.storage.erc1155";

    struct ERC1155Storage {
        // Mapping from token ID to account balances
        mapping(uint256 => mapping(address => uint256)) balance;
        // Mapping from account to operator approvals
        mapping(address => mapping(address => bool)) operatorApprovals;
        // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
        string uri;
        uint256 totalSupply;
    }

    function erc1155Storage() internal pure returns (ERC1155Storage storage es_) {
        bytes32 erc1155_key = STORAGE_ERC1155;
        assembly {
            es_.slot := erc1155_key
        }
    }

    function getBalance(uint256 tokenId, address user) internal view returns (uint256 balance_) {
        ERC1155Storage storage es = erc1155Storage();
        balance_ = es.balance[tokenId][user];
    }

    function getOperatorApproval(address user, address operator) internal view returns (bool approved_) {
        ERC1155Storage storage es = erc1155Storage();
        approved_ = es.operatorApprovals[user][operator];
    }
    function _asSingletonArray(uint256 element) internal pure  returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}
