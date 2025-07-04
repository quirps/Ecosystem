// interfaces/IAppInstanceFactory.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19; // Use a consistent pragma

interface IAppInstanceFactory {
    /**
     * @notice Emitted when an instance is deployed after bytecode verification.
     * @param expectedBytecodeHash The hash the factory was configured to expect.
     * @param receivedBytecodeHash The hash of the bytecode that was actually deployed (should match expected).
     * @param salt The salt used for CREATE2 deployment.
     * @param instanceAddress The address of the newly deployed contract instance.
     * @param deployer The address that called deployInstance (e.g., the AppRegistry).
     */
    event InstanceDeployedWithVerification(
        bytes32 indexed expectedBytecodeHash,
        bytes32 indexed receivedBytecodeHash,
        bytes32 indexed salt,
        address instanceAddress,
        address deployer
    );

    /**
     * @notice Deploys a new contract instance using CREATE2 after verifying the provided bytecode's hash.
     * @param bytecodeToDeploy The actual bytecode to deploy for this instance.
     * @param salt A unique salt used for CREATE2 deployment. Should be deterministic.
     * @return instanceAddress The address of the newly deployed instance.
     */
    function deployInstance(address ecosystemAddress, bytes calldata bytecodeToDeploy, bytes32 salt)
        external
        payable
        returns (address instanceAddress);

    /** 
     * @notice Predicts the deployment address after verifying the provided bytecode's hash.
     * @dev Requires the caller to provide the bytecode for hash verification.
     * @param bytecodeHash The bytecode intended for deployment.
     * @param salt A unique salt used for CREATE2 deployment.
     * @return predictedAddress The address where the contract will be deployed if deployInstance is called with the same arguments.
     */
    function predictAddress(bytes32 bytecodeHash, bytes32 salt)
        external
        view
        returns (address predictedAddress);

    /**
     * @notice Retrieves the bytecode hash this factory instance is configured to verify against.
     * @return The keccak256 hash of the expected bytecode.
     */
    function getExpectedBytecodeHash() external view returns (bytes32);

    /**
     * @notice Returns the owner of the factory contract (from Ownable).
     * @return The address of the owner.
     */
    function owner() external view returns (address);
}