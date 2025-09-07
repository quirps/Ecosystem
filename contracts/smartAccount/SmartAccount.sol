// contracts/SmartAccount.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract SmartAccount {
    using ECDSA for bytes32;

    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function execute(address to, uint256 value, bytes calldata data) external {
        require(msg.sender == owner, "Only owner can execute");
        (bool success, ) = to.call{value: value}(data);
        require(success, "Call failed");
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    receive() external payable {}
}
