import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

interface IUniswapPaymaster {
    function setEntryPoint(address _relayEntryPoint) external;
    function swapAndUnwrap(ISwapRouter.ExactOutputSingleParams memory params, address txInitiator) external;
    function stakeAndPool(address tokenAddress, uint256 amount, uint256 ethAmount, uint256 deadline) external payable;
     
    event Swapped(address indexed user, address tokenIn, uint256 amountIn, uint256 amountOut);
    event StakedAndPooled(address indexed user, address indexed token, uint256 amount, uint256 apy, uint256 tokenId, uint256 liquidityAdded);
    event Withdrawn(address indexed user, address indexed token, uint256 amount, uint256 reward);
    event Deposited(address indexed user, address indexed token, uint256 amount, uint256 additionalLiquidity);
    event RelayEntryPointSet(address relayEntryPoint);
    
    
    struct DepositDetials {
        address tokenAddress;
        uint256 amount;
        uint256 ethAmount;
        uint256 deadline;
    }
    
    struct TransferAmounts {
        uint256 tokenAmount;
        uint256 wethAmount;
    }
}