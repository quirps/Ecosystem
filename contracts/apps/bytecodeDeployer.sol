// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IBytecodeDeployer.sol"; // Import the interface
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol"; // Or your own CREATE2 library

// --- THIS IS AN EXAMPLE ---
// You would deploy a version of this contract for *each* mini-app type (e.g., PollDeployer, GiveawayDeployer)
// Each version would have its specific `ALLOWED_BYTECODE_HASH` and `APP_CREATION_CODE` hardcoded.

// contract SpecificMiniApp { // The actual mini-app contract code would be separate
//     constructor(address _creator, uint _param) { /* ... */ }
// }
 
contract ExampleBytecodeDeployer is IBytecodeDeployer {

    // !!! IMPORTANT: Hardcode these values for each specific deployer contract !!!
    // This is the keccak256 hash of the *creation code* (deployment bytecode) of the mini-app you allow.
    bytes32 private immutable ALLOWED_BYTECODE_HASH;

    constructor(bytes memory _appCreationCode) {
        require(_appCreationCode.length > 0, "Deployer: Code cannot be empty");
        ALLOWED_BYTECODE_HASH = keccak256(_appCreationCode); 
    }

    /**
     * @inheritdoc IBytecodeDeployer
     */
    function deploy(bytes32 salt, bytes memory bytecode, bytes memory constructorArgs)
        external
        returns (address instanceAddress)
    {
        require(keccak256(bytecode) == ALLOWED_BYTECODE_HASH, "Bytecode doesn't match allowed bytecode hash.");
        // The core logic: Construct the full bytecode with arguments 
        bytes memory bytecodeToDeploy = abi.encodePacked(bytecode, constructorArgs);

        // *** Verification Step (Implicit via Constructor and Immutability) ***
        // Since ALLOWED_BYTECODE_HASH is derived from APP_CREATION_CODE at deployment
        // and both are immutable, we are guaranteed to be deploying the correct code.
        // No need for an explicit hash check *within* this function if set up correctly.

        // Deploy using CREATE2
        instanceAddress = Create2.deploy(0, salt, bytecodeToDeploy); // amount = 0 Ether

        require(instanceAddress != address(0), "Deployer: CREATE2 failed");

        // Optional: Initialize the deployed contract if needed (requires interface)
        // ISpecificMiniApp(instanceAddress).initialize(...);

        return instanceAddress;
    }

     /**
      * @inheritdoc IBytecodeDeployer
      */
    function getAllowedBytecodeHash() external view override returns (bytes32 bytecodeHash) {
        return ALLOWED_BYTECODE_HASH;
    }

    /**
     * @inheritdoc IBytecodeDeployer
     */
    function predictAddress(bytes32 salt,bytes memory bytecode, bytes memory constructorArgs)
        external
        view
        returns (address predictedAddress)
    {
        bytes memory bytecodeToDeploy = abi.encodePacked(bytecode, constructorArgs);
        predictedAddress = Create2.computeAddress(salt, keccak256(bytecodeToDeploy), address(this));
        return predictedAddress;
    }
}