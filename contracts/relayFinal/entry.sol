// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { ReentrancyGuardContract } from "../ReentrancyGuard.sol";
import {IUniswapPaymaster} from "./IPaymaster.sol";
import "./ImetaTxVerifier.sol";



contract EntryPoint is ReentrancyGuardContract {
    address public immutable trustedForwarder;
    address public immutable paymasterAddress;

    event RelayExecuted(
        address indexed signer,
        address indexed target,
        bool success,
        uint256 gasUsed,
        uint256 totalGasUsed
    );
    
    constructor(address _trustedForwarder, address _paymasterAddress) {
        trustedForwarder = _trustedForwarder;
        paymasterAddress = _paymasterAddress;
    }
    
    /**
     * @dev Main entry point for the relay
 
     * @param req The forwarding request 
     * @param signature signature of the message 
     */
    function relay(
        IMetaTransactionVerifier.MetaTransaction memory req,
        bytes calldata signature
            ) external ReentrancyGuard {
        // Start gas measurement 
        uint256 startGas = gasleft();
        
        // Call the trusted forwarder to execute the transaction
        (bool success, bytes memory result) = trustedForwarder.call(
            abi.encodeWithSelector(
                IMetaTransactionVerifier.executeMetaTransaction.selector,
                req, 
                signature 
            )
        );
        
        // Calculate gas used for the forwarded call
        uint256 gasUsed = startGas - gasleft();
        
        // Add the additional gas estimate
        uint256 totalGasUsed = gasUsed;  
        req.paymasterData.amountOut += gasUsed;    
        
        IUniswapPaymaster( paymasterAddress ).swapAndUnwrap( req.paymasterData, req.txInitiator );  
        // Ensure the call was successful
        require(success, "EntryPoint: Forwarded call failed");
        
        // Emit event with gas metrics
        emit RelayExecuted(
            req.signer,
            req.target,
            success,
            gasUsed,
            totalGasUsed
        );
    }
}