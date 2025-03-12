// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IUniswapV3SwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
        uint256 deadline;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external returns (uint256 amountOut);
}

interface IUniswapV3PositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }
    
    function mint(MintParams calldata params) external returns (
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );
    
    function positions(uint256 tokenId) external view returns (
        uint96 nonce,
        address operator,
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        uint256 feeGrowthInside0LastX128,
        uint256 feeGrowthInside1LastX128,
        uint128 tokensOwed0,
        uint128 tokensOwed1
    );
    
    function decreaseLiquidity(
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0Min,
        uint256 amount1Min,
        uint256 deadline
    ) external returns (uint256 amount0, uint256 amount1);
    
    function collect(
        uint256 tokenId,
        address recipient,
        uint128 amount0Max,
        uint128 amount1Max
    ) external returns (uint256 amount0, uint256 amount1);
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256) external;
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
}

interface IStake {
    function stake(address outputToken) external returns (uint256 apy);
}

contract EthRelayPaymaster is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    address public uniswapRouter;
    address public wethAddress;
    address public nftPositionManagerAddress;
    
    // Standard fee tiers in Uniswap V3
    uint24 public constant POOL_FEE = 3000; // 0.3%
    
    // Default tick range for adding liquidity (can be made configurable)
    int24 public lowerTick = -887220;
    int24 public upperTick = 887220;
    
    // Staking variables
    mapping(address => mapping(address => uint256)) public stakedAmount; // user => token => amount
    mapping(address => mapping(address => uint256)) public stakingStartTime; // user => token => timestamp
    mapping(address => mapping(address => uint256)) public apyRate; // user => token => APY rate
    mapping(address => mapping(address => uint256)) public lpTokenIds; // user => token => NFT position ID
    
    event Swapped(address indexed user, address tokenIn, uint256 amountIn, uint256 amountOut);
    event StakedAndPooled(address indexed user, address indexed token, uint256 amount, uint256 apy, uint256 tokenId, uint256 liquidityAdded);
    event Withdrawn(address indexed user, address indexed token, uint256 amount, uint256 reward);
    event Deposited(address indexed user, address indexed token, uint256 amount, uint256 additionalLiquidity);
    
    constructor(address _uniswapRouter, address _weth, address _nftPositionManager) {
        uniswapRouter = _uniswapRouter;
        wethAddress = _weth;
        nftPositionManagerAddress = _nftPositionManager;
    }
    
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
    
    function swapAndUnwrap(Uniswap memory params) external nonReentrant {
        require(params.tokenOut == wethAddress, "TokenOut must be WETH");
        require(params.recipient != address(0), "Invalid recipient");
        
        // Transfer tokens from sender to this contract
        IERC20(params.tokenIn).safeTransferFrom(msg.sender, address(this), params.amountIn);
        
        // Approve router to spend tokens
        IERC20(params.tokenIn).safeApprove(uniswapRouter, params.amountIn);
        
        // Execute swap
        IUniswapV3SwapRouter.ExactInputSingleParams memory swapParams = 
            IUniswapV3SwapRouter.ExactInputSingleParams({
                tokenIn: params.tokenIn,
                tokenOut: params.tokenOut,
                fee: params.fee,
                recipient: address(this), // Contract receives WETH first
                amountIn: params.amountIn,
                amountOutMinimum: params.amountOutMinimum,
                sqrtPriceLimitX96: params.sqrtPriceLimitX96,
                deadline: params.deadline
            });
        
        uint256 amountOut = IUniswapV3SwapRouter(uniswapRouter).exactInputSingle(swapParams);
        
        // Unwrap WETH
        IWETH(wethAddress).withdraw(amountOut);
        
        // Send ETH to recipient
        (bool success, ) = params.recipient.call{value: amountOut}("");
        require(success, "ETH transfer failed");
        
        emit Swapped(params.recipient, params.tokenIn, params.amountIn, amountOut);
    }
    
    // Combined staking and pooling functionality
    function stakeAndPool(address tokenAddress, uint256 amount, uint256 ethAmount, uint256 deadline) external payable nonReentrant {
        require(amount > 0, "Cannot stake 0 tokens");
        require(ethAmount > 0 || msg.value > 0, "ETH amount must be positive");
        
        uint256 wethToUse = ethAmount;
        if (msg.value > 0) {
            wethToUse = msg.value;
            // Convert ETH to WETH
            IWETH(wethAddress).deposit{value: msg.value}();
        } else {
            // Transfer WETH from user if they didn't send ETH
            IERC20(wethAddress).safeTransferFrom(msg.sender, address(this), ethAmount);
        }
        
        // Transfer tokens from user
        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);
        
        // Get APY rate from IStake interface
        uint256 stakeApy = IStake(tokenAddress).stake(wethAddress);
        
        // Sort tokens (Uniswap V3 requires token0 < token1)
        (address token0, address token1, uint256 amount0, uint256 amount1) = _sortTokens(
            tokenAddress, wethAddress, amount, wethToUse
        );
        
        // Approve NFT position manager to use tokens
        IERC20(token0).safeApprove(nftPositionManagerAddress, amount0);
        IERC20(token1).safeApprove(nftPositionManagerAddress, amount1);
        
        // Add liquidity to Uniswap V3 pool
        IUniswapV3PositionManager.MintParams memory params = IUniswapV3PositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: POOL_FEE,
            tickLower: lowerTick,
            tickUpper: upperTick,
            amount0Desired: amount0,
            amount1Desired: amount1,
            amount0Min: 0, // Allow for slippage
            amount1Min: 0, // Allow for slippage
            recipient: address(this), // Contract holds the NFT
            deadline: deadline
        });
        
        (uint256 tokenId, uint128 liquidity, , ) = IUniswapV3PositionManager(nftPositionManagerAddress).mint(params);
        
        // Record staking and LP position information
        stakedAmount[msg.sender][tokenAddress] += amount;
        stakingStartTime[msg.sender][tokenAddress] = block.timestamp;
        apyRate[msg.sender][tokenAddress] = stakeApy;
        lpTokenIds[msg.sender][tokenAddress] = tokenId;
        
        emit StakedAndPooled(msg.sender, tokenAddress, amount, stakeApy, tokenId, uint256(liquidity));
    }
    
    function withdrawStake(address tokenAddress, uint256 amount, uint256 deadline) external nonReentrant {
        require(amount > 0, "Cannot withdraw 0 tokens");
        require(stakedAmount[msg.sender][tokenAddress] >= amount, "Insufficient staked amount");
        
        uint256 tokenId = lpTokenIds[msg.sender][tokenAddress];
        require(tokenId != 0, "No LP position found");
        
        // Get position info
        (, , address token0, address token1, , , , uint128 liquidity, , , , ) = 
            IUniswapV3PositionManager(nftPositionManagerAddress).positions(tokenId);
        
        // Calculate proportion to withdraw
        uint256 totalStaked = stakedAmount[msg.sender][tokenAddress];
        uint128 liquidityToRemove = uint128((uint256(liquidity) * amount) / totalStaked);
        
        // Calculate reward
        uint256 reward = calculateReward(msg.sender, tokenAddress);
        
        // Remove liquidity
        (uint256 amount0, uint256 amount1) = IUniswapV3PositionManager(nftPositionManagerAddress).decreaseLiquidity(
            tokenId,
            liquidityToRemove,
            0, // Allow for slippage
            0, // Allow for slippage
            deadline
        );
        
        // Collect tokens
        IUniswapV3PositionManager(nftPositionManagerAddress).collect(
            tokenId,
            address(this),
            type(uint128).max, // Collect all token0
            type(uint128).max  // Collect all token1
        );
        
        // Update staking information
        stakedAmount[msg.sender][tokenAddress] -= amount;
        stakingStartTime[msg.sender][tokenAddress] = block.timestamp; // Reset staking time for remaining amount
        
        // Transfer original token back to user
        uint256 tokenAmount;
        uint256 wethAmount;
        
        if (token0 == tokenAddress) {
            tokenAmount = amount0;
            wethAmount = amount1;
        } else {
            tokenAmount = amount1;
            wethAmount = amount0;
        }
        
        // Transfer tokens back to user
        IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
        
        // Unwrap WETH and send ETH plus reward
        IWETH(wethAddress).withdraw(wethAmount + reward);
        (bool success, ) = msg.sender.call{value: wethAmount + reward}("");
        require(success, "ETH transfer failed");
        
        emit Withdrawn(msg.sender, tokenAddress, amount, reward);
    }
    
    function depositAdditional(
        address tokenAddress, 
        uint256 amount, 
        uint256 ethAmount, 
        uint256 deadline
    ) external payable nonReentrant {
        require(amount > 0, "Cannot deposit 0 tokens");
        require(ethAmount > 0 || msg.value > 0, "ETH amount must be positive");
        require(stakedAmount[msg.sender][tokenAddress] > 0, "No existing stake found");
        
        uint256 wethToUse = ethAmount;
        if (msg.value > 0) {
            wethToUse = msg.value;
            // Convert ETH to WETH
            IWETH(wethAddress).deposit{value: msg.value}();
        } else {
            // Transfer WETH from user if they didn't send ETH
            IERC20(wethAddress).safeTransferFrom(msg.sender, address(this), ethAmount);
        }
        
        // Transfer additional tokens from user
        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);
        
        uint256 tokenId = lpTokenIds[msg.sender][tokenAddress];
        require(tokenId != 0, "No LP position found");
        
        // Sort tokens
        (address token0, address token1, uint256 amount0, uint256 amount1) = _sortTokens(
            tokenAddress, wethAddress, amount, wethToUse
        );
        
        // Approve NFT position manager to use tokens
        IERC20(token0).safeApprove(nftPositionManagerAddress, amount0);
        IERC20(token1).safeApprove(nftPositionManagerAddress, amount1);
        
        // Calculate current rewards before adding to stake
        uint256 reward = calculateReward(msg.sender, tokenAddress);
        uint256 currentApyRate = apyRate[msg.sender][tokenAddress];
        
        // TODO: Implement adding liquidity to existing position
        // For simplicity in this example, we'll just assume creating a new position
        // In a production implementation, you would use the increaseLiquidity function
        
        IUniswapV3PositionManager.MintParams memory params = IUniswapV3PositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: POOL_FEE,
            tickLower: lowerTick,
            tickUpper: upperTick,
            amount0Desired: amount0,
            amount1Desired: amount1,
            amount0Min: 0, // Allow for slippage
            amount1Min: 0, // Allow for slippage
            recipient: address(this), // Contract holds the NFT
            deadline: deadline
        });
        
        (uint256 newTokenId, uint128 liquidityAdded, , ) = IUniswapV3PositionManager(nftPositionManagerAddress).mint(params);
        
        // Update staking information
        stakedAmount[msg.sender][tokenAddress] += amount;
        stakingStartTime[msg.sender][tokenAddress] = block.timestamp; // Reset staking time
        
        // Keep the same APY rate
        apyRate[msg.sender][tokenAddress] = currentApyRate;
        
        // Update token ID (this is a simplification - in production, you'd track multiple positions)
        lpTokenIds[msg.sender][tokenAddress] = newTokenId;
        
        emit Deposited(msg.sender, tokenAddress, amount, uint256(liquidityAdded));
    }
    
    function calculateReward(address user, address tokenAddress) public view returns (uint256) {
        if (stakedAmount[user][tokenAddress] == 0) {
            return 0;
        }
        
        uint256 stakeDuration = block.timestamp - stakingStartTime[user][tokenAddress];
        uint256 userApyRate = apyRate[user][tokenAddress];
        
        // Calculate reward: (amount * APY * duration) / (100000 * 365 days)
        // APY is represented as: 100000 = 100% APY, 20000 = 20% APY
        uint256 reward = (stakedAmount[user][tokenAddress] * userApyRate * stakeDuration) / (100000 * 365 days);
        
        return reward;
    }
    
    function getCurrentEarnings(address user, address tokenAddress) external view returns (uint256) {
        return calculateReward(user, tokenAddress);
    }
    
    function _sortTokens(
        address tokenA, 
        address tokenB, 
        uint256 amountA, 
        uint256 amountB
    ) internal pure returns (
        address token0, 
        address token1, 
        uint256 amount0, 
        uint256 amount1
    ) {
        if (tokenA < tokenB) {
            token0 = tokenA;
            token1 = tokenB;
            amount0 = amountA;
            amount1 = amountB;
        } else {
            token0 = tokenB;
            token1 = tokenA;
            amount0 = amountB;
            amount1 = amountA;
        }
    }
    
    // Allow contract to receive ETH for rewards and deposits
    receive() external payable {}
    
    // Allow owner to update Uniswap router address if needed
    function setUniswapRouter(address _uniswapRouter) external onlyOwner {
        uniswapRouter = _uniswapRouter;
    }
    
    // Allow owner to update WETH address if needed
    function setWethAddress(address _weth) external onlyOwner {
        wethAddress = _weth;
    }
    
    // Allow owner to update NFT position manager address if needed
    function setPositionManager(address _nftPositionManager) external onlyOwner {
        nftPositionManagerAddress = _nftPositionManager;
    }
    
    // Allow owner to update tick range for adding liquidity
    function setTickRange(int24 _lowerTick, int24 _upperTick) external onlyOwner {
        lowerTick = _lowerTick;
        upperTick = _upperTick;
    }
}