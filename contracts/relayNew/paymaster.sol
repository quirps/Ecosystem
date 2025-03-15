// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IUniswapV3Router {
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
    
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title PaymasterContract
 * @dev Contract that handles gas payment for meta-transactions and integrates with Uniswap V3
 */
contract PaymasterContract {
    address public immutable owner;
    address public immutable relayEntrypoint;
    address public immutable uniswapRouter;
    address public immutable weth;
    
    // Staking related variables
    mapping(address => mapping(address => uint256)) private userStakes; // token => user => amount
    mapping(address => uint256) private totalStakedToken; // token => total staked amount
    mapping(address => uint32) private rewardRates; // token => reward rate (annual percentage * 1000)
    mapping(address => uint256) private lastUpdateTime; // token => timestamp
    mapping(address => mapping(address => uint256)) private rewards; // token => user => accumulated rewards
    mapping(address => uint256) private rewardPerTokenStored; // token => rewardPerToken
    
    event GasPaid(address indexed from, address indexed to, uint256 gasUsed, uint256 gasFee);
    event SwapExecuted(address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);
    event Staked(address indexed user, address indexed token, uint256 amount);
    event Unstaked(address indexed user, address indexed token, uint256 amount);
    event RewardClaimed(address indexed user, address indexed token, uint256 amount);
    
    struct SwapParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
        uint256 deadline;
    }
    
    /**
     * @param _relayEntrypoint Address of the relay entrypoint
     * @param _uniswapRouter Address of the Uniswap V3 router
     * @param _weth Address of the WETH contract
     */
    constructor(address _relayEntrypoint, address _uniswapRouter, address _weth) {
        owner = msg.sender;
        relayEntrypoint = _relayEntrypoint;
        uniswapRouter = _uniswapRouter;
        weth = _weth;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyEntrypoint() {
        require(msg.sender == relayEntrypoint, "Only entrypoint can call this function");
        _;
    }
    
    /**
     * @dev Updates reward state for a specific token
     * @param token Address of the token
     */
    modifier updateReward(address token, address account) {
        rewardPerTokenStored[token] = rewardPerToken(token);
        lastUpdateTime[token] = block.timestamp;
        
        if (account != address(0)) {
            rewards[token][account] = earned(account, token);
        }
        _;
    }
    
    /**
     * @dev Called by the relay entrypoint to pay for gas
     */
    function payForGas(
        address from,
        address to,
        bytes calldata data,
        uint256 gasLimit,
        uint256 gasPrice,
        uint256 gasUsed
    ) external onlyEntrypoint {
        uint256 gasFee = gasUsed * gasPrice;
        
        emit GasPaid(from, to, gasUsed, gasFee);
        
        // Actual gas payment logic would go here
        // This could involve collecting fees from the user or subsidizing gas
    }
    
    /**
     * @dev Executes a swap through Uniswap V3 and unwraps WETH
     * @param params Swap parameters
     * @return amountOut The amount of tokens received after the swap
     */
    function swapAndUnwrapWETH(
        SwapParams calldata params
    ) external returns (uint256 amountOut) {
        require(params.tokenOut == weth, "Output token must be WETH");
        
        // Transfer the input tokens from user to this contract
        IERC20(params.tokenIn).transferFrom(msg.sender, address(this), params.amountIn);
        
        // Approve Uniswap router to spend tokens
        IERC20(params.tokenIn).approve(uniswapRouter, params.amountIn);
        
        // Create Uniswap swap parameters
        IUniswapV3Router.ExactInputSingleParams memory uniswapParams = 
            IUniswapV3Router.ExactInputSingleParams({
                tokenIn: params.tokenIn,
                tokenOut: params.tokenOut,
                fee: params.fee,
                recipient: address(this), // First receive WETH here
                amountIn: params.amountIn,
                amountOutMinimum: params.amountOutMinimum,
                sqrtPriceLimitX96: params.sqrtPriceLimitX96,
                deadline: params.deadline
            });
        
        // Execute the swap
        amountOut = IUniswapV3Router(uniswapRouter).exactInputSingle(uniswapParams);
        
        // Unwrap WETH to ETH
        IWETH(weth).withdraw(amountOut);
        
        // Send ETH to the recipient
        (bool success, ) = params.recipient.call{value: amountOut}("");
        require(success, "ETH transfer failed");
        
        emit SwapExecuted(params.tokenIn, params.tokenOut, params.amountIn, amountOut);
        
        return amountOut;
    }
    
    /**
     * @dev Returns the reward rate for a specific token-WETH pair
     * @param token Address of the token
     * @return Annual reward rate in basis points (e.g., 20000 = 20%)
     */
    function wethStakeRewards(address token) external view returns (uint32) {
        return rewardRates[token];
    }
    
    /**
     * @dev Sets the reward rate for a token-WETH pair
     * @param token Address of the token
     * @param rate Annual reward rate in basis points (e.g., 20000 = 20%)
     */
    function setRewardRate(address token, uint32 rate) external onlyOwner updateReward(token, address(0)) {
        rewardRates[token] = rate;
    }
    
    /**
     * @dev Calculates the reward per staked token
     * @param token Address of the token
     * @return Reward per token value
     */
    function rewardPerToken(address token) public view returns (uint256) {
        if (totalStakedToken[token] == 0) {
            return rewardPerTokenStored[token];
        }
        
        uint256 timeElapsed = block.timestamp - lastUpdateTime[token];
        uint256 rewardRate = rewardRates[token];
        
        return rewardPerTokenStored[token] + (
            (timeElapsed * rewardRate * 1e18) / (365 days * 100000 * totalStakedToken[token])
        );
    }
    
    /**
     * @dev Calculates the earned rewards for a user
     * @param user Address of the user
     * @param token Address of the token
     * @return Amount of earned rewards
     */
    function earned(address user, address token) public view returns (uint256) {
        uint256 userBalance = userStakes[token][user];
        uint256 currentRewardPerToken = rewardPerToken(token);
        uint256 storedReward = rewards[token][user];
        
        return userBalance * (currentRewardPerToken - rewardPerTokenStored[token]) / 1e18 + storedReward;
    }
    
    /**
     * @dev Allows users to stake tokens in a token-WETH liquidity pool
     * @param token Address of the token to stake
     * @param amount Amount of tokens to stake
     */
    function stake(address token, uint256 amount) external updateReward(token, msg.sender) {
        require(amount > 0, "Cannot stake 0");
        
        // Transfer tokens from user to this contract
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        
        // Update staking records
        userStakes[token][msg.sender] += amount;
        totalStakedToken[token] += amount;
        
        emit Staked(msg.sender, token, amount);
        
        // Note: In a real implementation, this would interact with Uniswap to add liquidity
        // to the token-WETH pair. This is simplified for clarity.
    }
    
    /**
     * @dev Allows users to unstake tokens from a token-WETH liquidity pool
     * @param token Address of the token to unstake
     * @param amount Amount of tokens to unstake
     */
    function unstake(address token, uint256 amount) external updateReward(token, msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        require(userStakes[token][msg.sender] >= amount, "Not enough staked");
        
        // Update staking records
        userStakes[token][msg.sender] -= amount;
        totalStakedToken[token] -= amount;
        
        // Transfer tokens back to user
        IERC20(token).transfer(msg.sender, amount);
        
        emit Unstaked(msg.sender, token, amount);
        
        // Note: In a real implementation, this would interact with Uniswap to remove liquidity
        // from the token-WETH pair. This is simplified for clarity.
    }
    
    /**
     * @dev Allows users to claim their earned rewards
     * @param token Address of the token for which to claim rewards
     */
    function claimReward(address token) external updateReward(token, msg.sender) {
        uint256 reward = rewards[token][msg.sender];
        if (reward > 0) {
            rewards[token][msg.sender] = 0;
            
            // Transfer WETH rewards to user
            IWETH(weth).transfer(msg.sender, reward);
            
            emit RewardClaimed(msg.sender, token, reward);
        }
    }
    
    /**
     * @dev Allows users to check their current stake
     * @param user Address of the user
     * @param token Address of the token
     * @return Amount of staked tokens
     */
    function getStake(address user, address token) external view returns (uint256) {
        return userStakes[token][user];
    }
    
    /**
     * @dev Allows the contract to receive ETH
     */
    receive() external payable {}
}