// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol"; // To hold tickets for listings/sales
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


import { IOwnership } from "../facets/Ownership/IOwnership.sol";
import { ITicketExchange } from "./interfaces/ITicketExchange.sol";
import "./interfaces/IExchangeRewards.sol"; 
import "./interfaces/IRewardToken.sol";
import "../facets/Ownership/IOwnership.sol";

/**
 * @title TicketExchange Contract
 * @dev Marketplace for primary sales and secondary listings of ERC1155 tickets.
 * Integrates with ExchangeRewards for fees, discounts, and reward token minting.
 */
contract TicketExchange is ITicketExchange, Ownable, ReentrancyGuard, ERC1155Holder {
    using SafeERC20 for IERC20;

    IExchangeRewards public rewardsContract;
    IRewardToken public rewardToken; // The ERC1155 for rewards/NFTs
    IERC1155 public ticketToken; // The ERC1155 representing the actual tickets

    // Use internal structs from interface for consistency
    mapping(uint256 => SaleInfo) public sales;
    uint256 public nextSaleId;

    mapping(uint256 => ListingInfo) public listings;
    uint256 public nextListingId;

    mapping(address => bool) public paymentTokensWhitelist; // Allowed payment tokens
    mapping(uint256 => mapping(address => uint256)) public userSalePurchases; // saleId => user => units purchased
    mapping(address => mapping(address => uint256)) public userEcosystemPurchases; // ecosystemAddr(paymentToken) => user => total value purchased

    uint16 public platformFeeBasisPoints; // e.g., 500 = 5%

    // --- Errors ---
    error PaymentTokenNotAllowed();
    error MismatchedArrays();
    error InvalidTimeRange();
    error PaymentAmountZero();
    error SaleNotActive();
    error TimeNotInRange();
    error PurchaseLimitReached();
    error MembershipLevelNotMet(); // If implemented
    error InsufficientAllowance(); // For ERC20 transferFrom
    error InsufficientBalance(); // For ERC20 transferFrom
    error ListingNotActive();
    error AmountMustBePositive();
    error NotEnoughListed();
    error NotListingOwner();
    error TransferFailed(); // Generic fallback


    // --- Constructor & Admin ---
    constructor(
        address _rewardsContractAddress,
        address _rewardTokenAddress,
        address _ticketTokenAddress,
        address initialOwner
    ) Ownable() {
        rewardsContract = IExchangeRewards(_rewardsContractAddress);
        rewardToken = IRewardToken(_rewardTokenAddress);
        ticketToken = IERC1155(_ticketTokenAddress);
        platformFeeBasisPoints = 500; // Default 5% fee
        emit RewardsContractSet(_rewardsContractAddress);
        emit TicketTokenSet(_ticketTokenAddress);
        emit PlatformFeeSet(platformFeeBasisPoints);
    }

    /** @inheritdoc ITicketExchange*/   
    function setRewardsContract(address _rewardsContractAddress) external override onlyOwner {
        require(_rewardsContractAddress != address(0), "Zero address");
        rewardsContract = IExchangeRewards(_rewardsContractAddress);
        emit RewardsContractSet(_rewardsContractAddress);
    }

    /** @inheritdoc ITicketExchange*/
    function setTicketToken(address _ticketTokenAddress) external override onlyOwner {
        require(_ticketTokenAddress != address(0), "Zero address");
        ticketToken = IERC1155(_ticketTokenAddress);
        emit TicketTokenSet(_ticketTokenAddress);
    }

    /** @inheritdoc ITicketExchange*/
    function setPlatformFee(uint16 _feeBasisPoints) external override onlyOwner {
        require(_feeBasisPoints <= 10000, "Fee cannot exceed 100%");
        platformFeeBasisPoints = _feeBasisPoints;
        emit PlatformFeeSet(_feeBasisPoints);
    }

    /** @inheritdoc ITicketExchange*/
    function setPaymentTokenWhitelist(address tokenAddress, bool allowed) external override onlyOwner {
        paymentTokensWhitelist[tokenAddress] = allowed;
        emit PaymentTokenWhitelisted(tokenAddress, allowed);
    }

    /** @inheritdoc ITicketExchange*/
    function adminMintTickets(address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external override onlyOwner {
        // Assumes ticketToken has appropriate minting permissions for this contract owner/address
        // This is a placeholder; ticket supply might be managed externally.
        // ticketToken.mintBatch(to, ids, amounts, data); // Example if ticketToken supports mintBatch
    }


    // --- Sale Logic ---

    /** @inheritdoc ITicketExchange*/
    function createSale(
        uint32 startTime,
        uint32 endTime,
        uint16 membershipLevel,
        address paymentTokenAddress,
        uint256 limitPerUser,
        uint256 predecessorSaleId,
        uint256[] calldata itemIds,
        uint256[] calldata itemAmounts,
        uint256 paymentAmount
    ) external override {
        if (!paymentTokensWhitelist[paymentTokenAddress]) revert PaymentTokenNotAllowed();
        if (itemIds.length != itemAmounts.length) revert MismatchedArrays();
        if (!(endTime > startTime && startTime >= block.timestamp)) revert InvalidTimeRange(); // Allow starting now
        if (paymentAmount == 0) revert PaymentAmountZero();

        // Check ecosystem owner status defensively 
        bool isOwnerSale = false;
        try IOwnership(paymentTokenAddress).owner() returns (address owner) {
            if (owner == msg.sender && owner != address(0)) { // Ensure owner is non-zero
                isOwnerSale = true;
            }
        } catch { /* Ignore errors, means not owner or interface not supported */ }

        uint256 saleId = nextSaleId++;
        SaleInfo storage newSale = sales[saleId];
        newSale.saleId = saleId;
        newSale.creator = msg.sender;
        newSale.startTime = startTime;
        newSale.endTime = endTime;
        newSale.membershipLevel = membershipLevel;
        newSale.paymentTokenAddress = paymentTokenAddress;
        newSale.limitPerUser = limitPerUser;
        newSale.predecessorSaleId = predecessorSaleId;
        // Note: Storing arrays directly in storage. Consider alternatives for very large arrays.
        newSale.itemIds = itemIds;
        newSale.itemAmounts = itemAmounts;
        newSale.paymentAmount = paymentAmount;
        newSale.totalSold = 0;
        newSale.active = true;
        newSale.isEcosystemSale = isOwnerSale;
        if (isOwnerSale) {
            newSale.ecosystemIdentifier = paymentTokenAddress;
        }

        // Ensure this contract holds/has approval for the tickets being sold
        // This check depends on how ticket supply is managed. Assume they need to be here.
        // for(uint i=0; i<itemIds.length; ++i) {
        //     require(ticketToken.balanceOf(address(this), itemIds[i]) >= itemAmounts[i] * SOME_TOTAL_SALE_LIMIT, "Insufficient ticket supply for sale");
        // }

        emit SaleCreated(saleId, msg.sender, paymentTokenAddress, isOwnerSale, startTime, endTime);
    }

    /** @inheritdoc ITicketExchange*/
    function purchaseFromSale(uint256 saleId) external override nonReentrant {
        // Note: This buys exactly one "unit" as defined in the sale.
        SaleInfo storage sale = sales[saleId];
        address buyer = msg.sender;

        if (!sale.active) revert SaleNotActive();
        if (!(block.timestamp >= sale.startTime && block.timestamp <= sale.endTime)) revert TimeNotInRange();
        if (sale.limitPerUser > 0 && userSalePurchases[saleId][buyer] >= sale.limitPerUser) revert PurchaseLimitReached();
        // TODO: Add membership level check: require(checkMembership(buyer, sale.membershipLevel), "Membership level not met");

        address paymentTokenAddr = sale.paymentTokenAddress;
        IERC20 paymentToken = IERC20(paymentTokenAddr);
        uint256 cost = sale.paymentAmount;

        // 1. Apply Discount
        uint256 discountAmount = rewardsContract.useDiscount(buyer, paymentTokenAddr);
        uint256 finalCost = cost > discountAmount ? cost - discountAmount : 0;

        // 2. Collect Payment (Transfer full fee + seller amount from buyer)
        paymentToken.safeTransferFrom(buyer, address(this), finalCost);

        // 3. Calculate & Distribute Fee to Rewards Contract
        uint256 feeAmount = cost * platformFeeBasisPoints / 10000; // Fee on original cost
        if (feeAmount > 0) {
            // Transfer the fee portion to the rewards contract
            paymentToken.safeTransfer(address(rewardsContract), feeAmount);
            // Notify rewards contract about the fee (even if amount sent is just fee)
            // Pass the original fee amount intended for reward distribution logic
             rewardsContract.recordFee(paymentTokenAddr, feeAmount);
        }

        // 4. Calculate Reward Tokens to Mint
        uint256 rewardRate = rewardsContract.getRewardMintRate(paymentTokenAddr); // Rate is tokens per payment token unit (both wei)
        uint256 rewardAmount = cost * rewardRate / 1e18; // Calculate reward tokens (in wei) based on original cost

        // Apply Early Supporter Bonus
        if (sale.isEcosystemSale && sale.predecessorSaleId == 0) {
            rewardAmount = rewardAmount * 110 / 100; // +10% boost
        }

        // 5. Mint Reward Tokens (TicketExchange needs minter role on RewardToken)
        if (rewardAmount > 0) {
            // Ensure IRewardToken interface exists and is linked
            rewardToken.mint(buyer, uint256(uint160(paymentTokenAddr)), rewardAmount, "");
        }

        // 6. Transfer Tickets (from this contract to buyer)
        // Ensure tickets were deposited/approved to this contract beforehand.
        ticketToken.safeBatchTransferFrom(address(this), buyer, sale.itemIds, sale.itemAmounts, "");

        // 7. Update State
        userSalePurchases[saleId][buyer]++;
        sale.totalSold++;

        // Track Ecosystem Purchase Value (based on original cost)
        if (sale.isEcosystemSale) {
            userEcosystemPurchases[sale.ecosystemIdentifier][buyer] += cost;
            emit EcosystemOwnerSalePurchase(sale.ecosystemIdentifier, buyer, cost);
        }

        emit SalePurchase(saleId, buyer, paymentTokenAddr, cost, discountAmount, rewardAmount, sale.itemIds, sale.itemAmounts);
    }


    // --- Listing Logic ---

    /** @inheritdoc ITicketExchange*/
    function listTicket(
        uint256 ticketId,
        uint256 amount,
        uint256 pricePerTicket,
        address paymentToken
    ) external override nonReentrant {
         if (!paymentTokensWhitelist[paymentToken]) revert PaymentTokenNotAllowed();
         if (amount == 0 || pricePerTicket == 0) revert AmountMustBePositive();
         // Check user owns the tickets
         if (ticketToken.balanceOf(msg.sender, ticketId) < amount) revert InsufficientBalance();

         // Transfer tickets to escrow (this contract)
         ticketToken.safeTransferFrom(msg.sender, address(this), ticketId, amount, "");

         uint256 listingId = nextListingId++;
         ListingInfo storage newListing = listings[listingId];
             newListing.listingId = listingId;
             newListing.seller = msg.sender;
             newListing.ticketId = ticketId;
             newListing.amountAvailable = amount;
             newListing.pricePerTicket = pricePerTicket;
             newListing.paymentToken = paymentToken;
             newListing.active = true;

         emit TicketListed(listingId, msg.sender, ticketId, amount, pricePerTicket, paymentToken);
    }

    /** @inheritdoc ITicketExchange*/
     function purchaseTicket(uint256 listingId, uint256 amountToBuy) external override nonReentrant {
         ListingInfo storage listing = listings[listingId];
         address buyer = msg.sender;
         address seller = listing.seller;

         if (!listing.active) revert ListingNotActive();
         if (amountToBuy == 0) revert AmountMustBePositive();
         if (listing.amountAvailable < amountToBuy) revert NotEnoughListed();

         address paymentTokenAddr = listing.paymentToken;
         IERC20 paymentToken = IERC20(paymentTokenAddr);
         uint256 cost = listing.pricePerTicket * amountToBuy;

         // 1. Apply Discount
         uint256 discountAmount = rewardsContract.useDiscount(buyer, paymentTokenAddr);
         uint256 finalCost = cost > discountAmount ? cost - discountAmount : 0;

         // 2. Collect Payment from buyer (to this contract)
         paymentToken.safeTransferFrom(buyer, address(this), finalCost);

         // 3. Calculate & Distribute Fee
         uint256 feeAmount = cost * platformFeeBasisPoints / 10000;
         uint256 amountToSeller = cost - feeAmount; // Amount seller receives before rewards logic

         // Send fee to Rewards Contract
         if (feeAmount > 0) {
             paymentToken.safeTransfer(address(rewardsContract), feeAmount);
             rewardsContract.recordFee(paymentTokenAddr, feeAmount); // Notify rewards contract
         }

         // 4. Pay Seller
         if (amountToSeller > 0) {
             paymentToken.safeTransfer(seller, amountToSeller);
         }

         // 5. Calculate & Mint Reward Tokens for Buyer
         uint256 rewardRate = rewardsContract.getRewardMintRate(paymentTokenAddr);
         uint256 rewardAmount = cost * rewardRate / 1e18; // Base reward on original cost
         if (rewardAmount > 0) {
             rewardToken.mint(buyer, uint256(uint160(paymentTokenAddr)), rewardAmount, "");
         }

         // 6. Transfer Tickets (from this contract to buyer)
         listing.amountAvailable -= amountToBuy;
         ticketToken.safeTransferFrom(address(this), buyer, listing.ticketId, amountToBuy, "");

         // 7. Update Listing State
         if (listing.amountAvailable == 0) {
             listing.active = false;
         }

         emit TicketPurchased(listingId, buyer, seller, paymentTokenAddr, amountToBuy, cost, discountAmount, rewardAmount, listing.ticketId);
     }

    /** @inheritdoc ITicketExchange*/
    function cancelListing(uint256 listingId) external override nonReentrant {
         ListingInfo storage listing = listings[listingId];
         if (listing.seller != msg.sender) revert NotListingOwner();
         if (!listing.active) revert ListingNotActive();

         listing.active = false;
         uint256 amountToReturn = listing.amountAvailable;
         listing.amountAvailable = 0; // Clear amount

         // Return escrowed tickets
         if (amountToReturn > 0) {
             ticketToken.safeTransferFrom(address(this), msg.sender, listing.ticketId, amountToReturn, "");
         }

         emit TicketListingCancelled(listingId);
    }

    // --- View Functions ---
    /** @inheritdoc ITicketExchange*/
    function getSale(uint256 saleId) external view override returns (SaleInfo memory) {
         return sales[saleId]; // Returns the struct directly
     }

    /** @inheritdoc ITicketExchange*/
     function getListing(uint256 listingId) external view override returns (ListingInfo memory) {
         return listings[listingId]; // Returns the struct directly
     }

    /** @inheritdoc ITicketExchange*/
     function getUserSalePurchases(uint256 saleId, address user) external view override returns (uint256 unitsPurchased) {
        return userSalePurchases[saleId][user];
     }

    /** @inheritdoc ITicketExchange*/
     function getUserEcosystemPurchases(address ecosystemAddress, address user) external view override returns (uint256 totalValuePurchased) {
        return userEcosystemPurchases[ecosystemAddress][user];
     }

    /** @inheritdoc ITicketExchange*/
     function isPaymentTokenAllowed(address token) external view override returns (bool) {
        return paymentTokensWhitelist[token];
     }

     /** @inheritdoc ITicketExchange*/
     function getRewardsContract() external view override returns (address) {
         return address(rewardsContract);
     }

    /** @inheritdoc ITicketExchange*/
     function getTicketToken() external view override returns (address) {
         return address(ticketToken);
     }

     /** @inheritdoc ITicketExchange*/
     function getPlatformFee() external view override returns (uint16) {
         return platformFeeBasisPoints;
     }
  
     function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Holder) returns (bool) {
        return interfaceId == type(ITicketExchange).interfaceId
            || super.supportsInterface(interfaceId);
    }
     
}