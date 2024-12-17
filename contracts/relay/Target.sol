// contracts/SimpleTarget.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Target {
    uint256 public storedData;

    event DataStored(uint256 data);

    function storeData(uint256 _data) external {
        storedData = _data;
        emit DataStored(_data);
    }
}
