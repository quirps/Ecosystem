// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IDiamondDeploy.sol";  
contract DiamondDeploy is IDiamondDeploy{
    address public diamondCutFacet;
    bytes32 bytecodeHash;
    /// @notice This event is emitted when a new Diamond is deployed
    /// @param bytecode The bytecode of the deployed Diamond contract
    event NewDiamond(bytes bytecode);

    constructor(bytes memory _bytecode, address _diamondCutFacet) {
        diamondCutFacet = _diamondCutFacet;
        bytecodeHash = keccak256(_bytecode);
        emit NewDiamond(_bytecode);
    }

    function deploy(bytes memory _bytecode) external returns (address diamond_) {
        // Initialize a variable to hold the deployed address
        address deployedAddress; //fksdf

        require(keccak256(_bytecode) == bytecodeHash, "Bytecode must match that of the Diamond associated with this contract.");
        // ABI encode the constructor parameters
        bytes memory encodedParams = abi.encode(msg.sender, diamondCutFacet);

        // Concatenate the pseudoBytecode and encoded constructor parameters
        bytes memory finalBytecode = abi.encodePacked(_bytecode, encodedParams);

        // Use CREATE2 opcode to deploy the contract with static bytecode
        // Generate a unique salt based on msg.sender
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, diamondCutFacet));

        // The following assembly block deploys the contract using CREATE2 opcode
        assembly {
            deployedAddress := create2(
                0, // 0 wei sent with the contract
                add(finalBytecode, 32), // skip the first 32 bytes (length)
                mload(finalBytecode), // size of bytecode
                salt // salt
            )

            // Check if contract deployment was successful
            if iszero(extcodesize(deployedAddress)) {
                revert(0, 0)
            }
        }

        return deployedAddress;
    }
}

/**
 * We store hash of bytecode.
 * Client deploys bytecode.
 * Checks hash, deploys.
 */
