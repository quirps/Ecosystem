// contracts/Relay.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TrustedForwarder.sol";

contract Relay {
    TrustedForwarder public trustedForwarder;

    event MetaTransactionRelayed(
        address user,
        uint256 gasUsed,
        uint256 estimatedGas,
        uint256 initialGas,
        uint256 finalGas
    );

    constructor(address _trustedForwarder) {
        trustedForwarder = TrustedForwarder(_trustedForwarder);
    }

    function relayMetaTransaction(address target, bytes calldata data) external {
        uint256 initialGas = gasleft();


        //paymaster 
        
        // Forward the transaction to the target contract
         bool success = trustedForwarder.forward(target, data);

        uint256 executionGasUsed = initialGas - gasleft(); // Execution gas

        require(success, "MetaTransaction failed");

        // Measure final gas after transaction completion
        uint256 finalGas = gasleft();

        // Emit event for off-chain comparison
        emit MetaTransactionRelayed(
            tx.origin,
            executionGasUsed,
            0, // Placeholder for off-chain estimation
            initialGas,
            finalGas
        );
    }
}
