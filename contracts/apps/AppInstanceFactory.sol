// contracts/core/AppInstanceFactory.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
contract AppInstanceFactory is Ownable {

    // --- State ---

    bytes32 public immutable expectedBytecodeHash; // Store only the expected hash

    // --- Events ---

    event InstanceDeployedWithVerification(
        bytes32 indexed expectedBytecodeHash, // Hash that was verified
        bytes32 indexed receivedBytecodeHash, // Hash of the code actually deployed (should match above)
        bytes32 indexed salt,
        address instanceAddress,
        address deployer // Address that called deployInstance (e.g., AppRegistry)
    );

    // --- Constructor ---

    /**
     * @notice Deploys a factory configured to verify a specific bytecode hash.
     * @param _expectedBytecodeHash The keccak256 hash of the bytecode this factory expects to deploy.
     */
    constructor(bytes32 _expectedBytecodeHash) Ownable(msg.sender) {
        require(_expectedBytecodeHash != bytes32(0), "Factory: Hash cannot be zero");
        expectedBytecodeHash = _expectedBytecodeHash;
    }

    // --- Deployment ---

    /**
     * @notice Deploys a new contract instance using CREATE2 after verifying the provided bytecode's hash.
     * @param bytecodeToDeploy The actual bytecode to deploy for this instance.
     * @param _salt A unique salt used for CREATE2 deployment. Should be deterministic.
     * @return instanceAddress The address of the newly deployed instance.
     */
    function deployInstance(address ecosystemAddress, bytes calldata bytecodeToDeploy, bytes32 _salt)
        external 
        payable 
        returns (address instanceAddress)
    {        
        // Initialize a variable to hold the deployed address
        address deployedAddress; 

        require(keccak256(bytecodeToDeploy) == expectedBytecodeHash, "Bytecode must match that of the Diamond associated with this contract.");
        // ABI encode the constructor parameters
        bytes memory encodedParams = abi.encode(ecosystemAddress); 

        // Concatenate the pseudoBytecode and encoded constructor parameters
        bytes memory finalBytecode = abi.encodePacked(bytecodeToDeploy, encodedParams);

        // Use CREATE2 opcode to deploy the contract with static bytecode
        // Generate a unique salt based on msg.sender
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, _salt, encodedParams)); 

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

    // --- Prediction ---

    /**
     * @notice Predicts the deployment address after verifying the provided bytecode's hash.
     * @param bytecodeHash The bytecode intended for deployment.
     * @param salt A unique salt used for CREATE2 deployment.
     * @return predictedAddress The address where the contract will be deployed.
     */
    function predictAddress(bytes32 bytecodeHash, bytes32 salt)
        public 
        view
        returns (address predictedAddress)
    {
        
        require( bytecodeHash == expectedBytecodeHash, "Factory: Bytecode mismatch for prediction");

        // Use OpenZeppelin's helper for CREATE2 address prediction
        predictedAddress = Create2.computeAddress(salt, expectedBytecodeHash, address(this));        // Alternatively, using the assembly method from OZ Address.sol:
        // bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, receivedBytecodeHash));
        // predictedAddress = address(uint160(uint256(hash)));
    } 

    /**
     * @notice Utility function to get the stored expected bytecode hash.
     */
    function getExpectedBytecodeHash() external view returns (bytes32) {
        return expectedBytecodeHash;
    }
}