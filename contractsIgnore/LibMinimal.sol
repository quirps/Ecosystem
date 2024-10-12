pragma solidity ^0.8.9;

library LibMinimal {
    bytes32 constant STORAGE_MINIMAL = "diamond.storage.minimal";

    struct MinimalStorage {
        mapping(uint256 => mapping(address => uint256)) dataMap;
    }

    function minimalStorage() internal pure returns (MinimalStorage storage ms_) {
        bytes32 minimal_key = STORAGE_MINIMAL;
        assembly {
            ms_.slot := minimal_key
        }
    }

    function getData(uint256 tokenId, address user) internal view returns (uint256 data_) {
        MinimalStorage storage ms = minimalStorage();
        data_ = ms.dataMap[tokenId][user];
    }
}
