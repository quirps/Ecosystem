// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRelay {
    /// @notice Accepts a meta-transaction request and forwards it.
    /// @param userAddress The address of the user submitting the meta-transaction.
    /// @param target The target contract to call.
    /// @param data The calldata for the target contract.
    /// @param gasLimit The gas limit for the forwarded call.
    /// @param signature The user's signature authorizing the meta-transaction.
    function forwardMetaTransaction(
        address userAddress,
        address target,
        bytes calldata data,
        uint256 gasLimit,
        bytes calldata signature
    ) external;

    /// @notice Estimates gas for a specific meta-transaction.
    function estimateGas(
        address userAddress,
        address target,
        bytes calldata data
    ) external view returns (uint256);
}
