// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract MetaTransactionVerifier {
    // Struct for our meta transaction
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


    // Mapping to track nonces for each user
    mapping(address => uint256) public nonces;

    // Domain separator for EIP-712
    bytes32 private immutable DOMAIN_SEPARATOR;
    
    // Type hash constants
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );
    
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        "MetaTransaction(address signer,address target,address txInitiator,ExactOutputSingleParams paymasterData,bytes targetData,uint256 gasLimit,uint256 nonce,uint32 deadline)ExactOutputSingleParams(address tokenIn,address tokenOut,uint24 fee,address recipient,uint256 deadline,uint256 amountOut,uint256 amountInMaximum,uint160 sqrtPriceLimitX96)"
    );
    bytes32 private constant PAYMASTER_TYPEHASH =     
        keccak256("ExactOutputSingleParams(address tokenIn,address tokenOut,uint24 fee,address recipient,uint256 deadline,uint256 amountOut,uint256 amountInMaximum,uint160 sqrtPriceLimitX96)");
    event MetaTransactionExecuted(address indexed from);
    error TargetError( bytes error);
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

        require(block.timestamp <= metaTx.deadline, "Transaction expired");
        nonces[metaTx.signer]++;
        

        //modify call data
        bytes memory modifiedCallData = abi.encodePacked(metaTx.targetData, abi.encode(metaTx.signer));
        // Execute transaction logic here
        // This is where you would handle the actual transaction data
        (bool success,bytes memory returnData) = metaTx.target.call(modifiedCallData);
      
        
        emit MetaTransactionExecuted(metaTx.signer); 
        
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
                metaTx.txInitiator,
                hashPaymaster(metaTx.paymasterData),  
                keccak256(metaTx.targetData),
                metaTx.gasLimit,
                metaTx.nonce,  
                metaTx.deadline
            )
        );
    }

    function hashPaymaster(ISwapRouter.ExactOutputSingleParams calldata paymaster) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    PAYMASTER_TYPEHASH,
                    paymaster.tokenIn,
                    paymaster.tokenOut,
                    paymaster.fee,
                    paymaster.recipient,
                    paymaster.deadline,
                    paymaster.amountOut,
                    paymaster.amountInMaximum,
                    paymaster.sqrtPriceLimitX96
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

    function getNonce(
        address user
    ) public view returns (uint256 nonce_){
        nonce_ = nonces[ user ];
    }
}