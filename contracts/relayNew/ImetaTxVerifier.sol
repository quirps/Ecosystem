// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

interface IMetaTransactionVerifier {
    // Struct for the meta transaction
    struct MetaTransaction {
        address signer;      // Address initiating the transaction
        address target;     // Prevents replay attacks
        address txInitiator;
        ISwapRouter.ExactOutputSingleParams paymasterData;        // Arbitrary transaction data
        bytes targetData;
        uint256 gasLimit;
        uint256 nonce;
        uint32 deadline;
    }
 

    // Event emitted when a meta transaction is executed
    event MetaTransactionExecuted(address indexed from);

    // Function to execute a meta transaction
    function executeMetaTransaction(
        MetaTransaction calldata metaTx,
        bytes calldata signature
    ) external returns (bool);

    // Function to get the hash of a meta transaction according to EIP-712
    function getMetaTransactionHash(MetaTransaction calldata metaTx) external view returns (bytes32);

    // Function to recover the signer from a signature and meta transaction
    function recoverSigner(
        MetaTransaction calldata metaTx,
        bytes calldata signature
    ) external view returns (address);

    // Function to get the nonce for a user
    function nonces(address user) external view returns (uint256);
}