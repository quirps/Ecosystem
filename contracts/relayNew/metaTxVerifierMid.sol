// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MetaTransactionVerifierMid {
    // Struct for our meta transaction
    struct MetaTransaction {
        address signer;      // Address initiating the transaction
        address target;
        bytes paymasterData;
        bytes targetData;
        uint256 nonce;     // Prevents replay attacks
        bytes data;        // Arbitrary transaction data
    }

    // Mapping to track nonces for each user
    mapping(address => uint256) public nonces;

    // Domain separator for EIP-712
    bytes32 private immutable DOMAIN_SEPARATOR;
    
    // Type hash constants
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );
    
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        "MetaTransaction(address signer,address target,bytes paymasterData,bytes targetData,uint256 nonce,bytes data)"
    );

    event MetaTransactionExecuted(address indexed signer, bytes data);

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256("MetaTransactionVerifier"),  // name
                keccak256("1"),                        // version
                block.chainid,                         // chainId
                address(this)                          // verifyingContract
            )
        );
    }

    /**
     * @dev Execute a meta transaction
     * @param metaTx The meta transaction struct
     * @param signature The signature to verify
     */
    function executeMetaTransaction(
        MetaTransaction calldata metaTx,
        bytes calldata signature
    ) external returns (bool) {
        // Verify the signer is valid
        address signer = recoverSigner(metaTx, signature);
        
        // Ensure the signer matches the from address in the meta transaction
        require(signer == metaTx.signer, "Signer and from address mismatch");
        
        // Verify and increment nonce to prevent replay attacks
        require(nonces[metaTx.signer] == metaTx.nonce, "Invalid nonce");
        nonces[metaTx.signer]++;
        
        // Execute transaction logic here
        // This is where you would handle the actual transaction data
        
        emit MetaTransactionExecuted(metaTx.signer, metaTx.data);
        
        return true;
    }

    /**
     * @dev Get the hash of a meta transaction according to EIP-712
     * @param metaTx The meta transaction struct
     * @return The typed data hash
     */
    function getMetaTransactionHash(MetaTransaction calldata metaTx) public view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                hashMetaTransaction(metaTx)
            )
        );
    }

    /**
     * @dev Hash the meta transaction struct
     * @param metaTx The meta transaction struct
     * @return The hash of the struct
     */
    function hashMetaTransaction(MetaTransaction calldata metaTx) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                META_TRANSACTION_TYPEHASH,
                metaTx.signer,
                metaTx.target,
                keccak256(metaTx.paymasterData),
                keccak256(metaTx.targetData),
                metaTx.nonce,
                keccak256(metaTx.data)
            )
        );
    }

    /**
     * @dev Recover the signer from a signature and meta transaction
     * @param metaTx The meta transaction struct
     * @param signature The signature bytes
     * @return The address of the signer
     */
    function recoverSigner(
        MetaTransaction calldata metaTx,
        bytes calldata signature
    ) public view returns (address) {
        require(signature.length == 65, "Invalid signature length");
        
        bytes32 hash = getMetaTransactionHash(metaTx);
        
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        // Extract r, s, v from the signature
        assembly {
            r := calldataload(signature.offset)
            s := calldataload(add(signature.offset, 32))
            v := byte(0, calldataload(add(signature.offset, 64)))
        }
        
        // v adjustment for Ethereum signed message
        if (v < 27) {
            v += 27;
        }
        
        return ecrecover(hash, v, r, s);
    }
}