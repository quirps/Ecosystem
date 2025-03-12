// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ITrustedForwarder {
    function execute(
        address from,
        address to,
        bytes calldata data,
        uint256 gasLimit
    ) external payable returns (bool success, bytes memory result);
}

interface IPaymaster {
    function payForGas(
        address from,
        address to,
        bytes calldata data,
        uint256 gasLimit,
        uint256 gasPrice,
        uint256 gasUsed
    ) external payable;
}

/**
 * @title RelayEntrypoint
 * @dev Contract for handling meta-transactions by relaying them to a trusted forwarder after gas cost calculation
 */
contract RelayEntrypoint {
    address public immutable trustedForwarder;
    address public immutable paymaster;
    
    event MetaTxRelayed(
        address indexed from, 
        address indexed to, 
        uint256 gasUsed, 
        bool success
    );

    /**
     * @param _trustedForwarder Address of the trusted forwarder that will execute the transaction
     * @param _paymaster Address of the paymaster that will handle gas payment
     */
    constructor(address _trustedForwarder, address _paymaster) {
        require(_trustedForwarder != address(0), "Invalid forwarder address");
        require(_paymaster != address(0), "Invalid paymaster address");
        
        trustedForwarder = _trustedForwarder;
        paymaster = _paymaster;
    }
    
    /**
     * @dev Relays a meta-transaction through the trusted forwarder
     * @param from Original sender of the transaction
     * @param to Destination contract address
     * @param data Function data to be executed
     * @param gasLimit Maximum gas to be used for the transaction
     * @return success Whether the execution was successful
     * @return result The return data from the execution
     */
    function relayTransaction(
        address from,
        address to,
        bytes calldata data,
        uint256 gasLimit
    ) external returns (bool success, bytes memory result) {
        // Calculate actual gas cost
        uint256 startGas = gasleft();
        
        // Execute the transaction through the trusted forwarder
        (success, result) = ITrustedForwarder(trustedForwarder).execute(
            from,
            to,
            data,
            gasLimit
        );
        
        // Calculate gas used
        uint256 gasUsed = startGas - gasleft();
        
        // Call the paymaster to handle the gas payment
        IPaymaster(paymaster).payForGas{value: 0}(
            from,
            to,
            data,
            gasLimit,
            tx.gasprice,
            gasUsed
        );
        
        emit MetaTxRelayed(from, to, gasUsed, success);
        
        return (success, result);
    }
    
    /**
     * @dev Estimates the gas required for executing a transaction
     * @param to Destination contract address
     * @param data Function data to be executed
     * @return gasEstimate Estimated gas amount
     */
    function estimateGas(
        address to,
        bytes calldata data
    ) external view returns (uint256 gasEstimate) {
        uint256 gasBuffer = 50000; // Buffer for additional operations
        
        // Try to estimate gas for the call
        try this.staticEstimateGas(to, data) returns (uint256 estimate) {
            return estimate + gasBuffer;
        } catch {
            return 500000; // Default gas limit if estimation fails
        }
    }
    
    /**
     * @dev Helper function for gas estimation
     */
    function staticEstimateGas(
        address to,
        bytes calldata data
    ) external view returns (uint256) {
        (bool success, ) = to.staticcall(data);
        require(success, "Gas estimation failed");
        
        // This is a simplification - actual gas estimation would be more complex
        return to.code.length * 100 + data.length * 16;
    }
    
    /**
     * @dev Allows the contract to receive ETH
     */
    receive() external payable {}
}