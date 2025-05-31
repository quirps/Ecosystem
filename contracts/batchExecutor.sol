pragma solidity ^0.8.19;


// BatchExecutor.sol
contract BatchExecutor {
    function batchExecute(address[] calldata targets, bytes[] calldata data) external payable {
        require(targets.length == data.length, "Mismatched arrays");
        for (uint i = 0; i < targets.length; i++) {
            (bool success,) = targets[i].call(data[i]);
            require(success, "Call failed");
        }
    }
}
