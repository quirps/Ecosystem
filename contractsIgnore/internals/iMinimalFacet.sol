pragma solidity ^0.8.9;

import "../libraries/LibMinimal.sol";

contract iMinimal {
    function _setData(uint256 tokenId, address user, uint256 data) internal {
        LibMinimal.MinimalStorage storage ms = LibMinimal.minimalStorage();
        ms.dataMap[tokenId][user] = data;
    }

    function _getData(uint256 tokenId, address user) internal view returns (uint256 data_) {
        data_ = LibMinimal.getData(tokenId, user);
    }
}
