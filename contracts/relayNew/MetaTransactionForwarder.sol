// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";

/**
 * @title UniswapPaymaster
 * @dev A paymaster contract that uses Uniswap V3 to pay for gas fees in tokens other than ETH
 */
contract UniswapPaymaster is Ownable {
    // EIP712 domain name and version
    string public constant DOMAIN_NAME = "UniswapPaymaster";
    string public constant DOMAIN_VERSION = "1";
    
    // EIP712 type hashes
    bytes32 private constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );
   
    bytes32 private constant UNISWAP_TYPEHASH = keccak256(
        "Uniswap(address tokenIn,address tokenOut,uint24 fee,address recipient,uint256 amountIn,uint256 amountOutMinimum,uint160 sqrtPriceLimitX96,uint256 deadline)"
    );
   
    bytes32 private constant MESSAGE_TYPEHASH = keccak256(
        "Message(address signer,address target,Uniswap paymasterUniswap,bytes targetData,uint256 gasLimit,uint256 nonce,uint32 deadline)"
    );
   
    // Nonce mapping for replay protection
    mapping(address => uint256) public nonces;
   
    // Uniswap router for fee payments
    ISwapRouter public immutable swapRouter;
    
    // WETH address (fixed as per requirement)
    address public immutable WETH;
    
    // EntryPoint contract address
    IEntryPoint public immutable entryPoint;
    
    // Historical average ratios storage
    mapping(address => uint256) public historicalRatios;
    mapping(address => uint256) public ratioSampleCount;
    
    // Events
    event MetaTransactionExecuted(address indexed signer, address indexed target, bytes data, uint256 gasUsed);
    event RatioUpdated(address indexed token, uint256 ratio);
    
    // Struct to hold Uniswap parameters
    struct Uniswap {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
        uint256 deadline;
    }
   
    // Struct to hold the forwarded transaction details
    struct Message {
        address signer;
        address target;
        Uniswap paymasterUniswap;
        bytes targetData;
        uint256 gasLimit;
        uint256 nonce;
        uint32 deadline;
    }
    
    /**
     * @dev Constructor sets the Uniswap router and WETH addresses
     * @param _swapRouter The Uniswap V3 swap router address
     * @param _weth The WETH address
     * @param _entryPoint The EntryPoint contract address
     */
    constructor(address _swapRouter, address _weth, address _entryPoint) {
        swapRouter = ISwapRouter(_swapRouter);
        WETH = _weth;
        entryPoint = IEntryPoint(_entryPoint);
    }
    
    /**
     * @dev Generates the domain separator for EIP-712 signatures
     */
    function _domainSeparator() internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256(bytes(DOMAIN_NAME)),
                keccak256(bytes(DOMAIN_VERSION)),
                block.chainid,
                address(this)
            )
        );
    }
    
    /**
     * @dev Hashes the Uniswap struct per EIP-712
     */
    function _hashUniswap(Uniswap memory uniswap) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                UNISWAP_TYPEHASH,
                uniswap.tokenIn,
                uniswap.tokenOut,
                uniswap.fee,
                uniswap.recipient,
                uniswap.amountIn,
                uniswap.amountOutMinimum,
                uniswap.sqrtPriceLimitX96,
                uniswap.deadline
            )
        );
    }
    
    /**
     * @dev Hashes the Message struct per EIP-712
     */
    function _hashMessage(Message memory message) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                MESSAGE_TYPEHASH,
                message.signer,
                message.target,
                _hashUniswap(message.paymasterUniswap),
                keccak256(message.targetData),
                message.gasLimit,
                message.nonce,
                message.deadline
            )
        );
    }
    
    /**
     * @dev Verifies that the signature is valid for the given message
     */
    function _verify(Message memory message, bytes memory signature) internal view returns (bool) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparator(),
                _hashMessage(message)
            )
        );
        
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(signature);
        address recoveredSigner = ecrecover(digest, v, r, s);
        
        return (recoveredSigner != address(0) && recoveredSigner == message.signer);
    }
    
    /**
     * @dev Splits a signature into r, s, v components
     */
    function _splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "Invalid signature length");
        
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        
        if (v < 27) {
            v += 27;
        }
        
        return (r, s, v);
    }
    
    /**
     * @dev Executes a meta-transaction
     * @param message The message containing transaction details
     * @param signature The signature of the message
     */
    function executeMetaTransaction(Message memory message, bytes memory signature) external returns (bytes memory) {
        require(block.timestamp <= message.deadline, "Transaction expired");
        require(nonces[message.signer] == message.nonce, "Invalid nonce");
        require(_verify(message, signature), "Invalid signature");
        
        // Increment nonce
        nonces[message.signer]++;
        
        // Prepare Uniswap parameters
        Uniswap memory uniswap = message.paymasterUniswap;
        require(uniswap.tokenOut == WETH, "Token out must be WETH");
        
        // Transfer tokens from user to this contract
        TransferHelper.safeTransferFrom(
            uniswap.tokenIn,
            message.signer,
            address(this),
            uniswap.amountIn
        );
        
        // Approve tokens for Uniswap
        TransferHelper.safeApprove(
            uniswap.tokenIn,
            address(swapRouter),
            uniswap.amountIn
        );
        
        // Perform the swap to get WETH
        uint256 amountOut = swapRouter.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: uniswap.tokenIn,
                tokenOut: WETH,
                fee: uniswap.fee,
                recipient: address(this),
                deadline: uniswap.deadline,
                amountIn: uniswap.amountIn,
                amountOutMinimum: uniswap.amountOutMinimum,
                sqrtPriceLimitX96: uniswap.sqrtPriceLimitX96
            })
        );
        
        // Update ratio data
        uint256 newRatio = (uniswap.amountIn * 1e18) / amountOut; // Normalize to 1e18
        _updateHistoricalRatio(uniswap.tokenIn, newRatio);
        
        // Unwrap WETH to ETH
        // Simplified for brevity; in production, use a proper WETH interface
        (bool success, ) = WETH.call(abi.encodeWithSignature("withdraw(uint256)", amountOut));
        require(success, "WETH unwrap failed");
        
        // Forward the transaction
        uint256 startGas = gasleft();
        (bool success2, bytes memory result) = message.target.call{value: 0}(message.targetData);
        uint256 gasUsed = startGas - gasleft();
        
        require(success2, "Target call failed");
        require(gasUsed <= message.gasLimit, "Gas limit exceeded");
        
        emit MetaTransactionExecuted(message.signer, message.target, message.targetData, gasUsed);
        
        return result;
    }
    
    /**
     * @dev Updates the historical average ratio for a token
     */
    function _updateHistoricalRatio(address token, uint256 newRatio) internal {
        uint256 currentCount = ratioSampleCount[token];
        uint256 currentRatio = historicalRatios[token];
        
        if (currentCount == 0) {
            historicalRatios[token] = newRatio;
            ratioSampleCount[token] = 1;
        } else {
            // Moving average calculation
            historicalRatios[token] = ((currentRatio * currentCount) + newRatio) / (currentCount + 1);
            ratioSampleCount[token] = currentCount + 1;
        }
        
        emit RatioUpdated(token, historicalRatios[token]);
    }
    
    /**
     * @dev Gets the current spot ratio for a token to WETH
     */
    function getCurrentRatio(address token, uint24 fee) external view returns (uint256) {
        IUniswapV3Factory factory = IUniswapV3Factory(swapRouter.factory());
        IUniswapV3Pool pool = IUniswapV3Pool(factory.getPool(token, WETH, fee));
        
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        
        // Convert sqrtPriceX96
        uint256 price = uint256(sqrtPriceX96) * uint256(sqrtPriceX96) * 1e18 / (1 << 192);
        
        if (pool.token0() == token) {
            return 1e18 * 1e18 / price; // token/WETH
        } else {
            return price; // WETH/token -> token/WETH
        }
    }
    
    /**
     * @dev Gets the ratio for a token when swapping a specific amount
     */
    function getRatioForAmount(address token, uint24 fee, uint256 amount) external view returns (uint256) {
        // This is a simplified implementation for demonstration
        // In production, you would use a Uniswap quoter contract
        
        // For now, let's assume a simple price impact model based on amount
        uint256 spotRatio = this.getCurrentRatio(token, fee);
        
        // Apply a simple slippage model (this is highly simplified)
        uint256 slippagePercentage = (amount * 2) / 1000; // 0.2% per 1000 units of token
        if (slippagePercentage > 50) slippagePercentage = 50; // Cap at 50%
        
        return spotRatio * (100 + slippagePercentage) / 100;
    }
    
    /**
     * @dev Gets the historical average ratio for a token
     */
    function getHistoricalRatio(address token) external view returns (uint256) {
        return historicalRatios[token];
    }
    
    /**
     * @dev Get the next nonce for a signer
     */
    function getNonce(address signer) external view returns (uint256) {
        return nonces[signer];
    }
    
    /**
     * @dev Allows the contract to receive ETH
     */
    receive() external payable {}
    
    /**
     * @dev Allows the owner to withdraw ETH from the contract
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    /**
     * @dev Allows the owner to rescue ERC20 tokens from the contract
     */
    function rescueTokens(address token, uint256 amount) external onlyOwner {
        TransferHelper.safeTransfer(token, owner(), amount);
    }
}