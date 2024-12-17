// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; 

interface IPaymaster {
    function validateAndPayForTransaction(
        address userAddress,
        address target,
        bytes calldata data,
        uint256 gasLimit,
        uint256 nonce
    ) external returns (bool success, uint256 maxGasRefund);

    function issueRefund(uint256 gasUsed) external payable;
}

contract TrustedForwarder {
    using ECDSA for bytes32;

    // EIP-712 domain separator
    bytes32 public immutable DOMAIN_SEPARATOR;

    // EIP-712 type hash for the meta-transaction
    bytes32 public constant META_TX_TYPEHASH = keccak256(
        "MetaTransaction(address userAddress,address target,bytes data,uint256 gasLimit,uint256 nonce)"
    );

    address public relay;
    address public paymaster;

    mapping(address => uint256) public nonces; // Nonces for replay protection

    constructor(address _relay, address _paymaster, string memory appName, string memory version) {
        relay = _relay;
        paymaster = _paymaster;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(appName)),       // Application name
                keccak256(bytes(version)),       // Version
                block.chainid,                   // Current chain ID
                address(this)                    // Address of this contract
            )
        );
    }

    /***
     * Minimal forwarder for testing purposes
     */
    function forward( address target, bytes memory data) external returns( bool) {
         // Execute the meta-transaction on the target contract
        (bool callSuccess, ) = target.call(data);
        return callSuccess;
    }

    /// @notice Forward the meta-transaction to the target contract
    /// @param userAddress The signer of the meta-transaction
    /// @param target The target contract to execute
    /// @param data The calldata to be sent to the target contract
    /// @param gasLimit The gas limit for the transaction
    /// @param signature The user's signature authorizing the transaction
    function forwardTransaction(
        address userAddress,
        address target,
        bytes calldata data,
        uint256 gasLimit,
        bytes calldata signature
    ) external {
        require(msg.sender == relay, "Only relay can call");

        uint256 nonce = nonces[userAddress];

        // Construct the meta-transaction hash
        bytes32 structHash = keccak256(
            abi.encode(
                META_TX_TYPEHASH,
                userAddress,
                target,
                keccak256(data), // Hash of the calldata
                gasLimit,
                nonce
            )
        );

        // Compute the final EIP-712 hash
        bytes32 txHash = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
        );

        // Verify the signature
        require(
            verifySignature(userAddress, txHash, signature),
            "Invalid signature"
        );

        // Increment the nonce to prevent replay
        nonces[userAddress]++;

        // Call the Paymaster for gas validation
        (bool success, uint256 maxGasRefund) = IPaymaster(paymaster)
            .validateAndPayForTransaction(userAddress, target, data, gasLimit, nonce);
        require(success, "Paymaster validation failed");

        // Execute the meta-transaction on the target contract
        (bool callSuccess, ) = target.call{gas: gasLimit}(data);
        require(callSuccess, "Target call failed");

        // Issue gas refund after execution
        uint256 gasUsed = gasLimit - gasleft();
        require(gasUsed <= maxGasRefund, "Exceeded gas refund limit");

        IPaymaster(paymaster).issueRefund(gasUsed);
    }

    /// @notice Verify the signature of a meta-transaction
    /// @param userAddress The address of the user (expected signer)
    /// @param hash The hashed message
    /// @param signature The user's signature
    /// @return True if the signature is valid
    function verifySignature(
        address userAddress,
        bytes32 hash,
        bytes calldata signature
    ) public pure returns (bool) {
        // Recover the signer from the signature
        address signer = hash.recover(signature);

        // Ensure the recovered address matches the user address
        return signer == userAddress;
    }
}
