pragma solidity ^0.8.9;

import "../internals/iMinimalFacet.sol";
contract Minimal is iMinimal{
    function setData(uint256 tokenId, address user, uint256 data) external{
        _setData(tokenId, user, data);
    }
    function getData(uint256 tokenId, address user) external returns(uint256 data_){
        data_ = _getData(tokenId, user);
    }
}