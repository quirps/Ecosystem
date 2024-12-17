// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPaymaster {
    /// @notice Validates the meta-transaction and calculates gas payment.
    /// @param userAddress The address of the user submitting the meta-transaction.
    /// @param gasUsed The gas used by the meta-transaction.
    /// @return success Whether the payment is valid and the amount of gas to refund.
    function validateAndPayForTransaction(
        address userAddress,
        uint256 gasUsed
    ) external returns (bool success, uint256 refundAmount);

    /// @notice Checks if a user is eligible to pay for a transaction.
    function canPay(address userAddress) external view returns (bool);
}
