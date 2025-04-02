// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IBytecodeDeployer Interface
 * @dev Interface for contracts responsible for deploying specific mini-app bytecode via CREATE2.
 * Each implementation should verify the bytecode it deploys against a known hash.
 */
interface IBytecodeDeployer {
    /**
     * @notice Deploys the mini-app contract using CREATE2.
     * @dev The implementation MUST verify the deployment bytecode hash internally before deploying.
     * It MUST use the provided salt for CREATE2 deployment predictability.
     * @param salt A unique value combined with other parameters to determine the CREATE2 address.
     * @param constructorArgs ABI-encoded constructor arguments for the mini-app contract.
     * @return instanceAddress The address of the newly deployed mini-app contract instance.
     */
    function deploy(bytes32 salt, bytes memory bytecode, bytes memory constructorArgs) external returns (address instanceAddress);

    /**
     * @notice Returns the expected bytecode hash that this deployer is authorized to deploy.
     * @return bytecodeHash The keccak256 hash of the allowed mini-app creation code.
     */
    function getAllowedBytecodeHash() external view returns (bytes32 bytecodeHash);

     /**
      * @notice Calculates the deterministic address where the contract will be deployed via CREATE2.
      * @param salt The salt used for deployment.
      * @param constructorArgs ABI-encoded constructor arguments.
      * @return predictedAddress The pre-calculated deployment address.
      */
    function predictAddress(bytes32 salt, bytes memory bytecode, bytes memory constructorArgs) external view returns (address predictedAddress);
}