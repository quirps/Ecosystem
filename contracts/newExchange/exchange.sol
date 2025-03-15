// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

// Interface for the ecosystem contract to check membership levels
interface IEcosystem {
    function getMembershipLevel(address user) external view returns (uint16);
}

// Exchange Rewards Token Contract
contract ExchangeRewardsToken is ERC1155Supply, Ownable {
    constructor() ERC1155("https://exchange.example.com/rewards/{id}.json") Ownable() {}

    function mint(address account, uint256 id, uint256 amount) external onlyOwner {
        _mint(account, id, amount, "");
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) external onlyOwner {
        _mintBatch(to, ids, amounts, "");
    }
}

// Staking contract for rewards
contract ExchangeRewardsStaking is ERC1155Holder, Ownable, ReentrancyGuard {
    ExchangeRewardsToken public rewardsToken;
    
    // Staking parameters
    uint256 public constant MAX_STAKE_DURATION = 30 days;
    uint256 public constant BASE_RATE = 100; // Base rate multiplier
    
    // Staking data structures
    struct StakeInfo {
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        uint256 lastUpdateTime;
        uint256 rewardDebt;
    }
    
    // Mapping from token ID to user address to stake info
    mapping(uint256 => mapping(address => StakeInfo)) public stakes;
    
    // Accumulated reward per token, stored as token ID => reward per token
    mapping(uint256 => uint256) public accRewardPerToken;
    
    // Total staked amount per token ID
    mapping(uint256 => uint256) public totalStakedPerToken;
    
    // Last update time for each token's rewards
    mapping(uint256 => uint256) public lastUpdateTimePerToken;
    
    // Token rewards distribution rate (how much reward per second)
    mapping(uint256 => uint256) public rewardRatePerToken;
    
    event Staked(address indexed user, uint256 indexed tokenId, uint256 amount, uint256 endTime);
    event Unstaked(address indexed user, uint256 indexed tokenId, uint256 amount);
    event RewardClaimed(address indexed user, uint256 indexed tokenId, uint256 amount);
    
    constructor(address _rewardsTokenAddress) Ownable() {
        rewardsToken = ExchangeRewardsToken(_rewardsTokenAddress);
    }
    
    // Set reward rate for a specific token
    function setRewardRate(uint256 tokenId, uint256 rate) external onlyOwner {
        updateReward(tokenId);
        rewardRatePerToken[tokenId] = rate;
    }
    
    // Update accumulated rewards for a token
    function updateReward(uint256 tokenId) public {
        if (totalStakedPerToken[tokenId] == 0) {
            lastUpdateTimePerToken[tokenId] = block.timestamp;
            return;
        }
        
        uint256 timeElapsed = block.timestamp - lastUpdateTimePerToken[tokenId];
        if (timeElapsed > 0) {
            uint256 reward = timeElapsed * rewardRatePerToken[tokenId];
            accRewardPerToken[tokenId] += (reward * 1e18) / totalStakedPerToken[tokenId];
            lastUpdateTimePerToken[tokenId] = block.timestamp;
        }
    }
    
    // Update rewards for multiple tokens
    function updateRewards(uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            updateReward(tokenIds[i]);
        }
    }
    
    // Stake tokens for a specific duration
    function stake(uint256 tokenId, uint256 amount, uint256 duration) external nonReentrant {
        require(duration <= MAX_STAKE_DURATION, "Duration exceeds maximum");
        require(amount > 0, "Cannot stake 0");
        
        updateReward(tokenId);
        
        StakeInfo storage userStake = stakes[tokenId][msg.sender];
        
        // If user already has a stake, we need to claim rewards first
        if (userStake.amount > 0) {
            uint256 pending = pendingRewards(tokenId, msg.sender);
            if (pending > 0) {
                userStake.rewardDebt = userStake.amount * accRewardPerToken[tokenId] / 1e18;
                rewardsToken.mint(msg.sender, tokenId, pending);
                emit RewardClaimed(msg.sender, tokenId, pending);
            }
        }
        
        // Transfer tokens from user
        rewardsToken.safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        
        // Update stake info
        userStake.amount += amount;
        userStake.startTime = block.timestamp;
        userStake.endTime = block.timestamp + duration;
        userStake.lastUpdateTime = block.timestamp;
        userStake.rewardDebt = userStake.amount * accRewardPerToken[tokenId] / 1e18;
        
        // Update total staked
        totalStakedPerToken[tokenId] += amount;
        
        emit Staked(msg.sender, tokenId, amount, userStake.endTime);
    }
    
    // Unstake tokens
    function unstake(uint256 tokenId, uint256 amount) external nonReentrant {
        StakeInfo storage userStake = stakes[tokenId][msg.sender];
        require(amount > 0 && amount <= userStake.amount, "Invalid amount");
        require(block.timestamp >= userStake.endTime, "Stake period not ended");
        
        updateReward(tokenId);
        
        // Calculate rewards
        uint256 pending = pendingRewards(tokenId, msg.sender);
        
        // Update user stake
        userStake.amount -= amount;
        userStake.rewardDebt = userStake.amount * accRewardPerToken[tokenId] / 1e18;
        
        // Update total staked
        totalStakedPerToken[tokenId] -= amount;
        
        // Transfer tokens and rewards
        rewardsToken.safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
        
        if (pending > 0) {
            rewardsToken.mint(msg.sender, tokenId, pending);
            emit RewardClaimed(msg.sender, tokenId, pending);
        }
        
        emit Unstaked(msg.sender, tokenId, amount);
    }
    
    // Claim rewards without unstaking
    function claimRewards(uint256[] memory tokenIds) external nonReentrant {
        uint256 totalRewards = 0;
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            StakeInfo storage userStake = stakes[tokenId][msg.sender];
            
            if (userStake.amount == 0) continue;
            
            updateReward(tokenId);
            
            uint256 pending = pendingRewards(tokenId, msg.sender);
            if (pending > 0) {
                userStake.rewardDebt = userStake.amount * accRewardPerToken[tokenId] / 1e18;
                rewardsToken.mint(msg.sender, tokenId, pending);
                totalRewards += pending;
                emit RewardClaimed(msg.sender, tokenId, pending);
            }
        }
        
        require(totalRewards > 0, "No rewards to claim");
    }
    
    // Calculate pending rewards for a user for a specific token
    function pendingRewards(uint256 tokenId, address user) public view returns (uint256) {
        StakeInfo storage userStake = stakes[tokenId][user];
        if (userStake.amount == 0) {
            return 0;
        }
        
        uint256 accRPT = accRewardPerToken[tokenId];
        
        if (block.timestamp > lastUpdateTimePerToken[tokenId] && totalStakedPerToken[tokenId] != 0) {
            uint256 timeElapsed = block.timestamp - lastUpdateTimePerToken[tokenId];
            uint256 reward = timeElapsed * rewardRatePerToken[tokenId];
            accRPT += (reward * 1e18) / totalStakedPerToken[tokenId];
        }
        
        return (userStake.amount * accRPT / 1e18) - userStake.rewardDebt;
    }
    
    // Calculate pending rewards for a user for multiple tokens
    function pendingRewardsMultiple(uint256[] memory tokenIds, address user) external view returns (uint256[] memory) {
        uint256[] memory rewards = new uint256[](tokenIds.length);
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            rewards[i] = pendingRewards(tokenIds[i], user);
        }
        
        return rewards;
    }
    
    // Get stake boost based on duration (linear increase up to MAX_STAKE_DURATION)
    function getStakeBoost(uint256 duration) public pure returns (uint256) {
        if (duration >= MAX_STAKE_DURATION) {
            return BASE_RATE * 2; // Double rate at max duration
        }
        
        return BASE_RATE + ((BASE_RATE * duration) / MAX_STAKE_DURATION);
    }
    
    // Get user's stake info for multiple tokens
    function getUserStakes(address user, uint256[] memory tokenIds) external view returns (StakeInfo[] memory) {
        StakeInfo[] memory userStakes = new StakeInfo[](tokenIds.length);
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            userStakes[i] = stakes[tokenIds[i]][user];
        }
        
        return userStakes;
    }
}

// Main Ticket Exchange Contract
contract TicketExchange is ERC1155, Ownable, ReentrancyGuard {
    // Exchange fee structure
    uint256 public constant EXCHANGE_FEE = 10; // 1.0%
    uint256 public constant STAKERS_FEE = 3;   // 0.3%
    uint256 public constant FEE_DENOMINATOR = 1000;
    bool transient b;     
    // Sale structure as per requirements
    struct Sale { 
        uint32 startTime;
        uint32 endTime;
        uint16 membershipLevel;
        address paymentTokenAddress;
        uint256 limit;
        uint256 predecessorSaleId;
        uint256[] itemIds;
        uint256[] itemAmounts;
        uint256 paymentAmount;
        bool active;
    }
    
    // Ticket listing structure
    struct TicketListing {
        address seller;
        uint256 ticketId;
        uint256 amount;
        uint256 price;
        address paymentToken;
        bool active;
    }
    
    // Contracts
    IEcosystem public ecosystem;
    ExchangeRewardsToken public rewardsToken;
    ExchangeRewardsStaking public rewardsStaking;
    
    // State variables
    uint256 public nextSaleId = 1;
    uint256 public nextListingId = 1;
    mapping(uint256 => Sale) public sales;
    mapping(uint256 => TicketListing) public listings;
    mapping(uint256 => mapping(address => uint256)) public userPurchases; // Track purchases per sale
    mapping(address => bool) public paymentTokensWhitelist;
    
    // Exchange fee recipient
    address public feeRecipient;
    
    // Events
    event SaleCreated(uint256 indexed saleId, uint32 startTime, uint32 endTime);
    event SalePurchase(uint256 indexed saleId, address indexed buyer, uint256[] itemIds, uint256[] amounts);
    event TicketListed(uint256 indexed listingId, address indexed seller, uint256 ticketId, uint256 amount, uint256 price);
    event TicketPurchased(uint256 indexed listingId, address indexed buyer, address indexed seller, uint256 ticketId, uint256 amount);
    event TicketListingCancelled(uint256 indexed listingId);
    event RewardsDistributed(address indexed token, uint256 exchangeAmount, uint256 stakersAmount);
    
    constructor(
        address _ecosystemAddress, 
        address _rewardsTokenAddress, 
        address _rewardsStakingAddress,
        address _feeRecipient
    ) ERC1155("https://tickets.example.com/metadata/{id}.json") Ownable() {
        ecosystem = IEcosystem(_ecosystemAddress);
        rewardsToken = ExchangeRewardsToken(_rewardsTokenAddress);
        rewardsStaking = ExchangeRewardsStaking(_rewardsStakingAddress);
        feeRecipient = _feeRecipient;
    }
    
    // Set a new fee recipient
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "Invalid address");
        feeRecipient = _feeRecipient;
    }
    
    // Add or remove payment tokens from whitelist
    function setPaymentTokenWhitelist(address tokenAddress, bool allowed) external onlyOwner {
        paymentTokensWhitelist[tokenAddress] = allowed;
    }
    
    // Create a new sale
    function createSale(
        uint32 startTime,
        uint32 endTime, 
        uint16 membershipLevel,
        address paymentTokenAddress,
        uint256 limit,
        uint256 predecessorSaleId,
        uint256[] memory itemIds,
        uint256[] memory itemAmounts,
        uint256 paymentAmount
    ) external onlyOwner {
        require(itemIds.length == itemAmounts.length, "Arrays length mismatch");
        require(startTime < endTime, "Invalid time period");
        require(paymentTokensWhitelist[paymentTokenAddress], "Payment token not whitelisted");
        
        if (predecessorSaleId > 0) {
            require(sales[predecessorSaleId].active, "Predecessor sale doesn't exist");
        }
        
        Sale storage newSale = sales[nextSaleId];
        newSale.startTime = startTime;
        newSale.endTime = endTime;
        newSale.membershipLevel = membershipLevel;
        newSale.paymentTokenAddress = paymentTokenAddress;
        newSale.limit = limit;
        newSale.predecessorSaleId = predecessorSaleId;
        newSale.itemIds = itemIds;
        newSale.itemAmounts = itemAmounts;
        newSale.paymentAmount = paymentAmount;
        newSale.active = true;
        
        emit SaleCreated(nextSaleId, startTime, endTime);
        nextSaleId++;
    }
    
    // Allow users to purchase from a sale
    function purchaseFromSale(uint256 saleId) external nonReentrant {
        
        Sale storage sale = sales[saleId];
        require(sale.active, "Sale not active");
        require(block.timestamp >= sale.startTime && block.timestamp <= sale.endTime, "Sale not open");
        require(userPurchases[saleId][msg.sender] < sale.limit, "Purchase limit reached");
        
        // Check membership level
        uint16 userLevel = ecosystem.getMembershipLevel(msg.sender);
        require(userLevel >= sale.membershipLevel, "Insufficient membership level");
        
        // Check predecessor sale purchase if needed
        if (sale.predecessorSaleId > 0) {
            require(userPurchases[sale.predecessorSaleId][msg.sender] > 0, "Must purchase from predecessor sale first");
        }
        
        // Transfer payment tokens with fees
        IERC20 paymentToken = IERC20(sale.paymentTokenAddress);
        uint256 paymentAmount = sale.paymentAmount;
        
        uint256 exchangeFee = (paymentAmount * EXCHANGE_FEE) / FEE_DENOMINATOR;
        uint256 stakersFee = (paymentAmount * STAKERS_FEE) / FEE_DENOMINATOR;
        uint256 sellerAmount = paymentAmount - exchangeFee - stakersFee;
        
        require(paymentToken.transferFrom(msg.sender, address(this), paymentAmount), "Payment failed");
        
        // Transfer fees
        require(paymentToken.transfer(feeRecipient, exchangeFee), "Exchange fee transfer failed");
        
        // Update accumulated rewards for stakers of this token
        distributeStakingRewards(sale.paymentTokenAddress, stakersFee);
        
        // Mint reward tokens to buyer based on payment amount
        uint256 rewardTokenId = uint256(uint160(sale.paymentTokenAddress));
        rewardsToken.mint(msg.sender, rewardTokenId, paymentAmount / 100); // 1% of payment as rewards
        
        // Mint tickets to buyer
        _mintBatch(msg.sender, sale.itemIds, sale.itemAmounts, "");
        
        // Update user purchase record
        userPurchases[saleId][msg.sender]++;
        
        emit SalePurchase(saleId, msg.sender, sale.itemIds, sale.itemAmounts);
    }
    
    // List a ticket for sale
    function listTicket(uint256 ticketId, uint256 amount, uint256 price, address paymentToken) external nonReentrant {
        require(amount > 0, "Cannot list 0 tickets");
        require(price > 0, "Price must be > 0");
        require(paymentTokensWhitelist[paymentToken], "Payment token not whitelisted");
        require(balanceOf(msg.sender, ticketId) >= amount, "Insufficient ticket balance");
        
        // Transfer tickets to contract
        safeTransferFrom(msg.sender, address(this), ticketId, amount, "");
        
        // Create listing
        TicketListing storage listing = listings[nextListingId];
        listing.seller = msg.sender;
        listing.ticketId = ticketId;
        listing.amount = amount;
        listing.price = price;
        listing.paymentToken = paymentToken;
        listing.active = true;
        
        emit TicketListed(nextListingId, msg.sender, ticketId, amount, price);
        nextListingId++;
    }
    
    // Purchase a listed ticket
    function purchaseTicket(uint256 listingId, uint256 amount) external nonReentrant {
        TicketListing storage listing = listings[listingId];
        require(listing.active, "Listing not active");
        require(amount > 0 && amount <= listing.amount, "Invalid amount");
        
        uint256 totalPrice = (listing.price * amount) / listing.amount;
        IERC20 paymentToken = IERC20(listing.paymentToken);
        
        // Calculate fees
        uint256 exchangeFee = (totalPrice * EXCHANGE_FEE) / FEE_DENOMINATOR;
        uint256 stakersFee = (totalPrice * STAKERS_FEE) / FEE_DENOMINATOR;
        uint256 sellerAmount = totalPrice - exchangeFee - stakersFee;
        
        // Transfer payment
        require(paymentToken.transferFrom(msg.sender, address(this), totalPrice), "Payment failed");
        require(paymentToken.transfer(listing.seller, sellerAmount), "Seller payment failed");
        require(paymentToken.transfer(feeRecipient, exchangeFee), "Exchange fee transfer failed");
        
        // Distribute rewards to stakers
        distributeStakingRewards(listing.paymentToken, stakersFee);
        
        // Mint reward tokens to both buyer and seller
        uint256 rewardTokenId = uint256(uint160(listing.paymentToken));
        uint256 buyerRewards = totalPrice / 200; // 0.5% of payment as rewards
        uint256 sellerRewards = totalPrice / 200; // 0.5% of payment as rewards
        
        rewardsToken.mint(msg.sender, rewardTokenId, buyerRewards);
        rewardsToken.mint(listing.seller, rewardTokenId, sellerRewards);
        
        // Transfer tickets to buyer
        _safeTransferFrom(address(this), msg.sender, listing.ticketId, amount, "");
        
        // Update listing
        listing.amount -= amount;
        if (listing.amount == 0) {
            listing.active = false;
        }
        
        emit TicketPurchased(listingId, msg.sender, listing.seller, listing.ticketId, amount);
    }
    
    // Cancel a listing
    function cancelListing(uint256 listingId) external nonReentrant {
        TicketListing storage listing = listings[listingId];
        require(listing.active, "Listing not active");
        require(listing.seller == msg.sender, "Not the seller");
        
        // Return tickets to seller
        _safeTransferFrom(address(this), listing.seller, listing.ticketId, listing.amount, "");
        
        listing.active = false;
        
        emit TicketListingCancelled(listingId);
    }
    
    // Distribute staking rewards
    function distributeStakingRewards(address tokenAddress, uint256 amount) internal {
        uint256 rewardTokenId = uint256(uint160(tokenAddress));
        
        // Update rewards for this token
        rewardsStaking.updateReward(rewardTokenId);
        
        emit RewardsDistributed(tokenAddress, 0, amount);
    }
    
    // Mint new tickets (admin function)
    function mintTickets(address to, uint256[] memory ids, uint256[] memory amounts) external onlyOwner {
        _mintBatch(to, ids, amounts, "");
    }
    
    // Override transfer hook to trigger rewards for direct transfers
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        
        // If it's a direct transfer between users (not involving the contract)
        if (from != address(0) && from != address(this) && to != address(0) && to != address(this)) {
            // We could add direct transfer rewards here if desired
        }
    }
}

// Factory to deploy the entire ecosystem
contract TicketExchangeFactory {
    function deployExchangeSystem(address ecosystemAddress, address feeRecipient) external returns (
        address ticketExchange,
        address rewardsToken,
        address rewardsStaking
    ) {
        // Deploy rewards token
        ExchangeRewardsToken rewardsTokenContract = new ExchangeRewardsToken();
        
        // Deploy staking contract
        ExchangeRewardsStaking stakingContract = new ExchangeRewardsStaking(address(rewardsTokenContract));
        
        // Transfer ownership of rewards token to staking contract
        rewardsTokenContract.transferOwnership(address(stakingContract));
        
        // Deploy ticket exchange
        TicketExchange exchangeContract = new TicketExchange(
            ecosystemAddress,
            address(rewardsTokenContract),
            address(stakingContract),
            feeRecipient
        );
        
        return (
            address(exchangeContract),
            address(rewardsTokenContract),
            address(stakingContract)
        );
    }
}