// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuardContract } from "../ReentrancyGuard.sol";
import { IUniswapPaymaster } from "./IPaymaster.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";


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

contract UniswapPaymaster is IUniswapPaymaster, Ownable, ReentrancyGuardContract {
    using SafeERC20 for IERC20;
    
    address public uniswapRouter;
    address public wethAddress;
    address public nftPositionManagerAddress;
    address public relayEntryPoint;

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
    

    constructor(address _uniswapRouter, address _weth, address _nftPositionManager, address _owner) Ownable(_owner) {
        uniswapRouter = _uniswapRouter;
        wethAddress = _weth;
        nftPositionManagerAddress = _nftPositionManager;
    }


    //Prevents any unsuspecting individuals to use this without relay
    function setEntryPoint( address _relayEntryPoint) external onlyOwner {
        relayEntryPoint = _relayEntryPoint;
        emit RelayEntryPointSet ( _relayEntryPoint );
    }

    function swapAndUnwrap(ISwapRouter.ExactOutputSingleParams memory params, address txInitiator) external ReentrancyGuard {
        require(params.tokenOut == wethAddress, "TokenOut must be WETH");
        require(params.recipient != address(0), "Invalid recipient");
        
        // Transfer tokens from sender to this contract
        IERC20(params.tokenIn).safeTransferFrom(msg.sender, address(this), params.amountInMaximum);
        
        // Approve router to spend tokens 
        IERC20(params.tokenIn).approve(uniswapRouter, params.amountInMaximum); 
        
        // Execute swap
        ISwapRouter.ExactOutputSingleParams memory swapParams = 
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: params.tokenIn,
                tokenOut: params.tokenOut,
                fee: params.fee,
                recipient: address(this), // Contract receives WETH first
                amountOut: params.amountOut,
                amountInMaximum: params.amountInMaximum,
                sqrtPriceLimitX96: params.sqrtPriceLimitX96,
                deadline: params.deadline
            });
        
        uint256 amountIn = ISwapRouter(uniswapRouter).exactOutputSingle(swapParams);
        
        // Return unused tokens to the user
        if (amountIn < params.amountInMaximum) {
            IERC20(params.tokenIn).safeTransfer(msg.sender, params.amountInMaximum - amountIn);
        }
        
        // Unwrap WETH
        IWETH(wethAddress).withdraw(params.amountOut);
        
        // Send ETH to recipient
        (bool success, ) = params.recipient.call{value: params.amountOut}("");
        require(success, "ETH transfer failed");
        
        emit Swapped(params.recipient, params.tokenIn, amountIn, params.amountOut);
    }
    
    // Combined staking and pooling functionality
    function stakeAndPool(address tokenAddress, uint256 amount, uint256 ethAmount, uint256 deadline) external payable ReentrancyGuard {
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
        IERC20(token0).approve(nftPositionManagerAddress, amount0); 
        IERC20(token1).approve(nftPositionManagerAddress, amount1);
        
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
    

struct WithdrawInputs {
    address tokenAddress;
    uint256 amount;
    uint256 deadline;
}
function withdrawStake(address tokenAddress, uint256 amount, uint256 deadline) external ReentrancyGuard {
    require(amount > 0, "Cannot withdraw 0 tokens");
    require(stakedAmount[msg.sender][tokenAddress] >= amount, "Insufficient staked amount");
    
    uint256 tokenId = lpTokenIds[msg.sender][tokenAddress];
    require(tokenId != 0, "No LP position found");
    
    PositionInfo memory pos = unpackPositionManager( tokenId );
    
    uint128 liquidityToRemove = uint128((uint256( pos.liquidity) * amount) / stakedAmount[msg.sender][tokenAddress]);
    uint256 reward = calculateReward(msg.sender, tokenAddress);
    
    // Remove and collect liquidity in a single operation
    (uint256 amount0, uint256 amount1) = IUniswapV3PositionManager(nftPositionManagerAddress).decreaseLiquidity(
        tokenId, liquidityToRemove, 0, 0, deadline
    );
    
    IUniswapV3PositionManager(nftPositionManagerAddress).collect(
        tokenId, address(this), type(uint128).max, type(uint128).max
    );
    
    // Update staking information
    stakedAmount[msg.sender][tokenAddress] -= amount;
    stakingStartTime[msg.sender][tokenAddress] = block.timestamp;
    
    // Determine token and weth amounts based on token ordering
    (uint256 tokenAmount, uint256 wethAmount) = pos.token0 == tokenAddress ? 
        (amount0, amount1) : (amount1, amount0);
    
    // Transfer tokens and ETH
    IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
    IWETH(wethAddress).withdraw(wethAmount + reward);
    
    (bool success, ) = msg.sender.call{value: wethAmount + reward}("");
    require(success, "ETH transfer failed");
    
    emit Withdrawn(msg.sender, tokenAddress, amount, reward);
}
struct PositionInfo {
    address token0;
    address token1;
    uint128 liquidity;
}
function unpackPositionManager(uint256 tokenId) private returns (PositionInfo memory pos) {
    // Prepare the call data for positions(uint256)
    bytes memory data = abi.encodeWithSignature("positions(uint256)", tokenId);
    
    // Perform a low-level call to the position manager
    (bool success, bytes memory returnData) = nftPositionManagerAddress.call(data);
    require(success, "positions call failed");
    
    // The positions function returns:
    // (uint96, address, address, address, uint24, int24, int24, uint128, uint256, uint256, uint128, uint128)
    // We only need token0, token1, and liquidity.
    (
        ,              // skip nonce (uint96)
        ,              // skip operator (address)
        pos.token0,    // token0 (address)
        pos.token1,    // token1 (address)
        ,              // skip fee (uint24)
        ,              // skip tickLower (int24)
        ,              // skip tickUpper (int24)
        pos.liquidity, // liquidity (uint128)
        ,              // skip feeGrowthInside0LastX128 (uint256)
        ,              // skip feeGrowthInside1LastX128 (uint256)
        ,              // skip tokensOwed0 (uint128)
        ) = abi.decode(
            returnData,
            (uint96, address, address, address, uint24, int24, int24, uint128, uint256, uint256, uint128, uint128)
        );
        
}


function removeLiquidityAndCollect(
    uint256 tokenId,
    address token0,
    address tokenAddress,
    uint128 liquidityToRemove,
    uint256 deadline
) internal returns (TransferAmounts memory transferAmounts) {
    (uint256 amount0, uint256 amount1) = IUniswapV3PositionManager(nftPositionManagerAddress).decreaseLiquidity(
        tokenId,
        liquidityToRemove,
        0,
        0,
        deadline
    );

    IUniswapV3PositionManager(nftPositionManagerAddress).collect(
        tokenId,
        address(this),
        type(uint128).max,
        type(uint128).max
    );

    if (token0 == tokenAddress) {
        transferAmounts.tokenAmount = amount0;
        transferAmounts.wethAmount = amount1;
    } else {
        transferAmounts.tokenAmount = amount1;
        transferAmounts.wethAmount = amount0;
    }
}

    function depositAdditional(
       DepositDetials memory _depositDetails 
    ) external payable ReentrancyGuard {
        require(_depositDetails.amount > 0, "Cannot deposit 0 tokens");
        require(_depositDetails.ethAmount > 0 || msg.value > 0, "ETH amount must be positive");
        require(stakedAmount[msg.sender][_depositDetails.tokenAddress] > 0, "No existing stake found");
        
        uint256 wethToUse = _depositDetails.ethAmount;
        if (msg.value > 0) {
            wethToUse = msg.value;
            // Convert ETH to WETH
            IWETH(wethAddress).deposit{value: msg.value}();
        } else {
            // Transfer WETH from user if they didn't send ETH
            IERC20(wethAddress).safeTransferFrom(msg.sender, address(this), _depositDetails.ethAmount);
        }
        
        // Transfer additional tokens from user
        IERC20(_depositDetails.tokenAddress).safeTransferFrom(msg.sender, address(this), _depositDetails.amount);
        
        uint256 tokenId = lpTokenIds[msg.sender][_depositDetails.tokenAddress];
        require(tokenId != 0, "No LP position found");
        
        // Sort tokens
        (address token0, address token1, uint256 amount0, uint256 amount1) = _sortTokens(
            _depositDetails.tokenAddress, wethAddress, _depositDetails.amount, wethToUse
        );
        
        // Approve NFT position manager to use tokens
        IERC20(token0).approve(nftPositionManagerAddress, amount0);
        IERC20(token1).approve(nftPositionManagerAddress, amount1); 
        
        // Calculate current rewards before adding to stake
        uint256 reward = calculateReward(msg.sender, _depositDetails.tokenAddress);
        uint256 currentApyRate = apyRate[msg.sender][_depositDetails.tokenAddress];
        
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
            deadline: _depositDetails.deadline
        });
        
        (uint256 newTokenId, uint128 liquidityAdded, , ) = IUniswapV3PositionManager(nftPositionManagerAddress).mint(params);
        
        // Update staking information
        stakedAmount[msg.sender][_depositDetails.tokenAddress] += _depositDetails.amount;
        stakingStartTime[msg.sender][_depositDetails.tokenAddress] = block.timestamp; // Reset staking time
        
        // Keep the same APY rate
        apyRate[msg.sender][_depositDetails.tokenAddress] = currentApyRate;
        
        // Update token ID (this is a simplification - in production, you'd track multiple positions)
        lpTokenIds[msg.sender][_depositDetails.tokenAddress] = newTokenId;
        
        emit Deposited(msg.sender, _depositDetails.tokenAddress, _depositDetails.amount, uint256(liquidityAdded));
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