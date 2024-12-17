// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITarget {
    /// @notice Executes the core logic of the meta-transaction.
    /// @param userAddress The address of the user submitting the meta-transaction.
    /// @param data The calldata for the target function.
    function executeMetaTransaction(
        address userAddress,
        bytes calldata data
    ) external;

    /// @notice Determines the paymaster responsible for gas payment.
    function getPaymaster() external view returns (address);
}
