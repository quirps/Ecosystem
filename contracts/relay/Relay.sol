// contracts/Relay.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TrustedForwarder.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Relay is ReentrancyGuard{
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


    function relayMetaTransaction(address target, bytes calldata paymasterData, bytes calldata data) nonReentrant() external {
        uint256 initialGas = gasleft();

        // Forward the transaction to the target contract
         bool success = trustedForwarder.forward(target, paymasterData, data);

        uint256 executionGasUsed = initialGas - gasleft(); // Execution gas

        require(success, "MetaTransaction failed");

        // Measure final gas after transaction completion
        uint256 finalGas = gasleft();


        //Now get refund. 

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
