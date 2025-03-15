// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @notice Enables staking on the ecosystem as well as uniswap. 
 * @title 
 * @author 
 * @notice 
 */
contract UniswapDoubleStake is ReentrancyGuard {
    INonfungiblePositionManager public immutable positionManager;
    address public immutable token0;
    address public immutable token1;
    uint24 public immutable fee;
    
    mapping(address => uint256) public userStakedLiquidity;
    
    constructor(
        address _positionManager,
        address _token0,
        address _token1,
        uint24 _fee
    ) {
        positionManager = INonfungiblePositionManager(_positionManager);
        token0 = _token0;
        token1 = _token1;
        fee = _fee;
    }
    
    function depositAndStake(
        uint256 amount0,
        uint256 amount1,
        int24 tickLower,
        int24 tickUpper
    ) external nonReentrant {
        require(amount0 > 0 && amount1 > 0, "Amounts must be greater than zero");

        IERC20(token0).transferFrom(msg.sender, address(this), amount0);
        IERC20(token1).transferFrom(msg.sender, address(this), amount1);
        
        IERC20(token0).approve(address(positionManager), amount0);
        IERC20(token1).approve(address(positionManager), amount1);
        
        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: fee,
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount0Desired: amount0,
            amount1Desired: amount1,
            amount0Min: 0,
            amount1Min: 0,
            recipient: address(this),
            deadline: block.timestamp + 1200
        });

        (uint256 tokenId, uint128 liquidity,,) = positionManager.mint(params);
        userStakedLiquidity[msg.sender] = tokenId;
    }
    
    function withdrawLiquidity(uint256 tokenId) external nonReentrant {
        require(userStakedLiquidity[msg.sender] == tokenId, "Not owner of this position");
        
        positionManager.safeTransferFrom(address(this), msg.sender, tokenId);
        delete userStakedLiquidity[msg.sender];
    }
}
