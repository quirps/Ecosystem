// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

contract TokenSwapStaking is ReentrancyGuard, Ownable {
    // Token addresses
    address public immutable tokenAddress;
    address public immutable WETH;
    
    // Uniswap router address
    ISwapRouter public immutable uniswapRouter;
    
    // Staking variables
    uint256 public totalStaked;
    uint256 public rewardPerTokenStored;
    uint256 public lastUpdateTime;
    uint256 public rewardRate;
    
    // User data
    mapping(address => uint256) public userStakedBalance;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public userRewardPerTokenPaid;
    
    // Events
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event TokenSwapped(uint256 tokenAmount, uint256 ethReceived);
    
    constructor(address _tokenAddress, address _router, address _weth) {
        tokenAddress = _tokenAddress;
        uniswapRouter = ISwapRouter(_router);
        WETH = _weth;
        
        // Approve router to spend tokens
        IERC20(_tokenAddress).approve(_router, type(uint256).max);
        IERC20(_weth).approve(_router, type(uint256).max);
    }
    
    // Modifier to update reward for a user
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }
    
    // Calculate reward per token
    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardPerTokenStored;
        }
        
        return rewardPerTokenStored + (((block.timestamp - lastUpdateTime) * rewardRate * 1e18) / totalStaked);
    }
    
    // Calculate earned rewards for an account
    function earned(address account) public view returns (uint256) {
        return ((userStakedBalance[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) + rewards[account];
    }
    
    // Stake ETH
    function stake() external payable nonReentrant updateReward(msg.sender) {
        require(msg.value > 0, "Cannot stake 0");
        
        totalStaked += msg.value;
        userStakedBalance[msg.sender] += msg.value;
        
        emit Staked(msg.sender, msg.value);
    }
    
    // Withdraw staked ETH
    function withdraw(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        require(userStakedBalance[msg.sender] >= amount, "Not enough staked");
        
        totalStaked -= amount;
        userStakedBalance[msg.sender] -= amount;
        
        // Transfer ETH back to the user
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "ETH transfer failed");
        
        emit Withdrawn(msg.sender, amount);
    }
    
    // Claim rewards
    function getReward() external nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            
            // Transfer token rewards to the user
            IERC20(tokenAddress).transfer(msg.sender, reward);
            
            emit RewardPaid(msg.sender, reward);
        }
    }
    
    // Set reward rate (only owner)
    function setRewardRate(uint256 _rewardRate) external onlyOwner updateReward(address(0)) {
        rewardRate = _rewardRate;
    }
    
    // Add rewards to the contract (only owner)
    function addReward(uint256 amount) external onlyOwner {
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
    }
    
    // Swap tokens for ETH via Uniswap
    function swapTokensForEth(uint256 tokenAmount) external nonReentrant onlyOwner {
        require(tokenAmount > 0, "Amount must be greater than 0");
        
        // Transfer tokens from the sender
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), tokenAmount);
        
        // Swap tokens for WETH
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = WETH;
        
        uint256 balanceBefore = IERC20(WETH).balanceOf(address(this));
        
        uniswapRouter.swapExactTokensForTokens(
            tokenAmount,
            0, // Accept any amount of WETH
            path,
            address(this),
            block.timestamp + 300 // 5 minute deadline
        );
        
        uint256 wethReceived = IERC20(WETH).balanceOf(address(this)) - balanceBefore;
        
        // Unwrap WETH to ETH
        unwrapWETH(wethReceived);
        
        emit TokenSwapped(tokenAmount, wethReceived);
    }
    
    // Unwrap WETH to ETH
    function unwrapWETH(uint256 wethAmount) internal {
        // Call the WETH contract's withdraw function to convert WETH to ETH
        (bool success, ) = WETH.call(abi.encodeWithSignature("withdraw(uint256)", wethAmount));
        require(success, "WETH unwrap failed");
    }
    
    // Fallback to receive ETH (needed for unwrapping WETH)
    receive() external payable {}
}