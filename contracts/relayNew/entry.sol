// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import { ReentrancyGuardContract } from "../ReentrancyGuard.sol";

interface ITrustedForwarder {
    struct ForwardRequest {
        address signer;
        address target;
        bytes targetData;
        uint256 nonce;
        uint32 deadline;
    }

    function execute(
        ISwapRouter.ExactOutputSingleParams calldata params,
        ForwardRequest calldata req
    ) external returns (bool, bytes memory);
}

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
     * @param paymasterParams Uniswap exactOutputSingleParams for the paymaster. The minimum output amount
     *                        initially given is the overestimate of constant gas costs and paymaster upperbound
     *                        The target gas is then added to this. 
     * @param req The forwarding request 
     * @param signature signature of the message 
     */
    function relay(
        ISwapRouter.ExactOutputSingleParams memory paymasterParams,
        ITrustedForwarder.ForwardRequest calldata req,
        address recipient,
        bytes calldata signature
            ) external ReentrancyGuard {
        // Start gas measurement 
        uint256 startGas = gasleft();
        
        // Call the trusted forwarder to execute the transaction
        (bool success, bytes memory result) = trustedForwarder.call(
            abi.encodeWithSelector(
                ITrustedForwarder.execute.selector,
                paymasterParams,
                req, 
                recipient,
                signature
            )
        );
        
        // Calculate gas used for the forwarded call
        uint256 gasUsed = startGas - gasleft();
        
        // Add the additional gas estimate
        uint256 totalGasUsed = gasUsed; 
        paymasterParams.amountOut += gasUsed;
        
        ISwapRouter( paymasterAddress ).exactOutputSingle( paymasterParams );
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