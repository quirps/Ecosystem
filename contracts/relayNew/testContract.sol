// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TargetContract {
    bool public functionCalled = false;
    
    function testFunction(uint256 _value) external returns (bool) {
        functionCalled = true;
        return true;
    }
     
    function getFunctionCallStatus() external view returns (bool) {
        return functionCalled;
    }
}