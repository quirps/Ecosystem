// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ReentrancyGuardContract} from "../ReentrancyGuard.sol";
import {IUniswapPaymaster} from "./IPaymaster.sol";
import "./ImetaTxVerifier.sol";

contract EntryPointNOPM is ReentrancyGuardContract {
    address public immutable trustedForwarder;

    event RelayExecuted(address indexed signer, address indexed target,  uint256 gasUsed, uint256 totalGasUsed);

    error TrustedForwarder(bytes error);

    constructor(address _trustedForwarder) {
        trustedForwarder = _trustedForwarder;
    }
    /**
     * @dev Main entry point for the relay
 
     * @param req The forwarding request 
     * @param signature signature of the message 
     */
    function relay(IMetaTransactionVerifier.MetaTransaction memory req, bytes calldata signature) external ReentrancyGuard {
        // Start gas measurement
        uint256 startGas = gasleft();

        try IMetaTransactionVerifier(trustedForwarder).executeMetaTransaction(req, signature) returns (bool ) {
            // Handle successful execution (if needed)
        } catch (bytes memory errorData) {
            revert TrustedForwarder(errorData); 
        }
        // // Call the trusted forwarder to execute the transaction
        // (bool success, bytes memory result) = trustedForwarder.call(
        //     abi.encodeWithSelector(IMetaTransactionVerifier.executeMetaTransaction.selector, req, signature)
        // );
        // if (!success) {
        //     revert TrustedForwarder(result);
        // }
        // Calculate gas used for the forwarded call
        uint256 gasUsed = startGas - gasleft();

        // Add the additional gas estimate
        uint256 totalGasUsed = gasUsed;
        req.paymasterData.amountOut += gasUsed;

        // Ensure the call was successful

        // Emit event with gas metrics
        emit RelayExecuted(req.signer, req.target, gasUsed, totalGasUsed);
    }
}
