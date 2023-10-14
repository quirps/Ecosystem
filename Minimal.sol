pragma solidity ^0.8.6;


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

contract iMinimal {
    function _setData(uint256 tokenId, address user, uint256 data) internal {
        LibMinimal.MinimalStorage storage ms = LibMinimal.minimalStorage();
        ms.dataMap[tokenId][user] = data;
    }

    function _getData(uint256 tokenId, address user) internal view returns (uint256 data_) {
        data_ = LibMinimal.getData(tokenId, user);
    }
}

contract Minimal is iMinimal{
    function setData(uint256 tokenId, address user, uint256 data) external{
        _setData(tokenId, user, data);
    }
    function getData(uint256 tokenId, address user) external returns(uint256 data_){
        data_ = _getData(tokenId, user);
    }
}