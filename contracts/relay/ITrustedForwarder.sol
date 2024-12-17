// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITrustedForwarder {
    /// @notice Forwards the meta-transaction to the target contract.
    /// @param userAddress The address of the user submitting the meta-transaction.
    /// @param target The target contract to call.
    /// @param data The calldata for the target contract.
    /// @param gasLimit The gas limit for the forwarded call.
    function forwardTransaction(
        address userAddress,
        address target,
        bytes calldata data,
        uint256 gasLimit
    ) external;

    /// @notice Verifies the signature of a meta-transaction.
    function verifySignature(
        address userAddress,
        bytes32 hash,
        bytes calldata signature
    ) external view returns (bool);
}
