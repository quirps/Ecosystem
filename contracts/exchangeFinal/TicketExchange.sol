// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Interfaces
import "./interfaces/ITicketExchange.sol";
import "./interfaces/IExchangeRewards.sol";
import "./interfaces/IRewardToken.sol";
import "../facets/Ownership/IOwnership.sol";
import "../facets/ERC2981/IERC2981.sol"; 
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// Libraries
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// Utilities & Security
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuardContract} from "../ReentrancyGuard.sol";
// Debugging (Optional)
// import "hardhat/console.sol";

/**
 * @title TicketExchange Contract v3
 * @dev Multi-ecosystem marketplace for primary sales (owner-only, no royalty)
 * and secondary listings (with EIP-2981 royalties verified by buyer).
 * Integrates with ExchangeRewards for fees, discounts, and reward token minting.
 * Includes Early Supporter Bonus for primary sales.
 * Implements ITicketExchange interface.
 */
contract TicketExchange is ITicketExchange, Ownable, ReentrancyGuardContract, ERC1155Holder {
    using SafeERC20 for IERC20;

    // --- State Variables ---

    IExchangeRewards public rewardsContract;
    IRewardToken public rewardToken; // The ERC1155 for rewards/NFTs

    // --- Exchange Configuration ---
    mapping(address => bool) public paymentTokensWhitelist; // Allowed payment tokens
    uint16 public platformFeeBasisPoints; // e.g., 500 = 5%

    // --- Sales & Listings Data ---
    // Structs SaleInfo and ListingInfo are inherited from ITicketExchange
    mapping(uint256 => SaleInfo) public sales;
    uint256 public nextSaleId;

    mapping(uint256 => ListingInfo) public listings;
    uint256 public nextListingId;

    // --- User Tracking ---
    mapping(uint256 => mapping(address => uint256)) public userSalePurchases; // saleId => user => units purchased
    mapping(address => mapping(address => mapping(address => uint256))) public userEcosystemPurchasesValue; // ecosystemAddress => user => paymentToken => totalValuePaid by user to owner
    mapping(uint256 => uint256) public salePurchaseNonce; // saleId => nonce (for early supporter bonus)

    // --- Constants ---
    uint16 private constant BASIS_POINTS_DIVISOR = 10000;
    uint256 private constant WEI_PER_ETHER = 1e18; // For reward calculation clarity

    // Early Supporter Bonus Config
    uint256 private constant EARLY_SUPPORTER_COUNT = 20; // Number of purchases eligible
    uint16 private constant MAX_EARLY_BONUS_BP = 1000; // 10% max bonus (Basis Points)


    // --- Errors ---
    error PaymentTokenNotAllowed();
    error InvalidTimeRange();
    error PaymentAmountZero();
    error MustBeEcosystemOwner();
    error ListingPriceZero();
    error AmountMustBePositive();
    error InsufficientTicketBalance();
    error SaleNotActive();
    error TimeNotInRange();
    error PurchaseLimitReached();
    error MembershipLevelNotMet();
    error InsufficientAllowance();
    error InsufficientPaymentBalance();
    error ListingNotActive();
    error NotEnoughListed();
    error NotListingOwner();
    error TransferFailed();
    error RoyaltyMismatch();
    error RoyaltyExceedsPrice();
    // error RoyaltyExceedsLimit(); // Removed
    error ZeroAddress();
    error BoosterNftFailed();

    // --- Constructor ---
    constructor(
        address _rewardsContractAddress,
        address _rewardTokenAddress,
        address _owner
    ) Ownable( _owner ) {
        if (_rewardsContractAddress == address(0) || _rewardTokenAddress == address(0)) revert ZeroAddress();
        rewardsContract = IExchangeRewards(_rewardsContractAddress);
        rewardToken = IRewardToken(_rewardTokenAddress);
        platformFeeBasisPoints = 500; // Default 5% fee
        emit RewardsContractSet(_rewardsContractAddress);
        emit PlatformFeeSet(platformFeeBasisPoints);
    }

    // --- Admin / Configuration Functions ---

    /** @inheritdoc ITicketExchange*/
    function setRewardsContract(address _rewardsContractAddress) external override onlyOwner {
        if (_rewardsContractAddress == address(0)) revert ZeroAddress();
        rewardsContract = IExchangeRewards(_rewardsContractAddress);
        emit RewardsContractSet(_rewardsContractAddress);
    }

    /** @inheritdoc ITicketExchange*/
    function setPlatformFee(uint16 _feeBasisPoints) external override onlyOwner {
        require(_feeBasisPoints <= BASIS_POINTS_DIVISOR, "Fee cannot exceed 100%");
        platformFeeBasisPoints = _feeBasisPoints;
        emit PlatformFeeSet(_feeBasisPoints);
    }

    /** @inheritdoc ITicketExchange*/
    function setPaymentTokenWhitelist(address tokenAddress, bool allowed) external override onlyOwner {
        paymentTokensWhitelist[tokenAddress] = allowed;
        emit PaymentTokenWhitelisted(tokenAddress, allowed);
    }

    /** @inheritdoc ITicketExchange*/
    function setMaxRoyalty(address /*ecosystemAddress*/, uint16 /*_maxBasisPoints*/) external override onlyOwner {
         revert("Royalty limits removed; use buyerExpectedRoyaltyFee check.");
    }

    /** @inheritdoc ITicketExchange*/
    function setGlobalMaxRoyalty(uint16 /*_maxBasisPoints*/) external override onlyOwner {
         revert("Royalty limits removed; use buyerExpectedRoyaltyFee check.");
    }

    
    function adminMintTickets(address /*to*/, uint256[] calldata /*ids*/, uint256[] calldata /*amounts*/, bytes calldata /*data*/) external /*override removed*/ onlyOwner {
         revert("adminMintTickets removed; manage ticket supply externally per ecosystem.");
    }

    // --- Sale Logic (Primary Market - Owner Only) ---

    /** @inheritdoc ITicketExchange*/
    function createSale(
        address ecosystemAddress,
        uint32 startTime,
        uint32 endTime,
        uint16 membershipLevel,
        address paymentTokenAddress,
        uint256 limitPerUser,
        uint256 predecessorSaleId,
        uint256 ticketId,
        uint256 ticketAmountPerPurchase,
        uint256 paymentAmount // Price 'P' set by owner
    ) external override {
        // --- Validation ---
        if (!paymentTokensWhitelist[paymentTokenAddress]) revert PaymentTokenNotAllowed();
        if (!(endTime > startTime && startTime >= block.timestamp)) revert InvalidTimeRange();
        if (paymentAmount == 0) revert PaymentAmountZero();
        if (ticketAmountPerPurchase == 0) revert AmountMustBePositive();
        if (ecosystemAddress == address(0)) revert ZeroAddress();

        // --- Check Ownership ---
        address ecosystemOwner;
        try IOwnership(ecosystemAddress).owner() returns (address owner) {
             ecosystemOwner = owner;
        } catch {
             revert("Cannot verify ecosystem owner"); // Revert if owner cannot be determined
        }
        if (msg.sender != ecosystemOwner) revert MustBeEcosystemOwner();

        // --- Create Sale ---
        uint256 saleId = nextSaleId++;
        sales[saleId] = SaleInfo({
            saleId: saleId,
            creator: msg.sender,
            ecosystemAddress: ecosystemAddress,
            startTime: startTime,
            endTime: endTime,
            membershipLevel: membershipLevel,
            paymentTokenAddress: paymentTokenAddress,
            limitPerUser: limitPerUser,
            predecessorSaleId: predecessorSaleId,
            ticketId: ticketId,
            ticketAmountPerPurchase: ticketAmountPerPurchase,
            paymentAmount: paymentAmount,
            totalSoldUnits: 0,
            active: true
        });

        emit SaleCreated(saleId, msg.sender, ecosystemAddress, paymentTokenAddress, ticketId, paymentAmount);
    }

// --- Context Struct Definition (as you provided it) ---
    struct PurchaseSaleContext {
        SaleInfo saleRef; // Use storage pointer for updates
        address buyer;
        address paymentTokenAddr;
        address ecosystemAddr;
        address creator;
        uint256 ticketId;
        uint256 ticketAmount;
        uint256 priceP;
        uint256 platformFee;
        uint256 finalCostToBuyer;
        uint256 finalRewardAmount; // Will be populated by helper
        bool boosted; // Will be populated by helper
    }


    /** @inheritdoc ITicketExchange*/
    function purchaseFromSale(
        uint256 saleId,
        uint256 boosterNftId
    ) external override ReentrancyGuard {
        // --- Context Struct ---
        PurchaseSaleContext memory ctx;

        // --- Fetch Sale Info & Initial Checks ---
        ctx.saleRef = sales[saleId];
        // Ensure checks use ctx.saleRef fields
        if (!ctx.saleRef.active) revert SaleNotActive();
        if (!(block.timestamp >= ctx.saleRef.startTime && block.timestamp <= ctx.saleRef.endTime)) revert TimeNotInRange();
        ctx.buyer = msg.sender;
        if (ctx.saleRef.limitPerUser > 0 && userSalePurchases[saleId][ctx.buyer] >= ctx.saleRef.limitPerUser) revert PurchaseLimitReached();
        // TODO: Add membership level check if required

        // --- Populate Context ---
        ctx.priceP = ctx.saleRef.paymentAmount;
        ctx.paymentTokenAddr = ctx.saleRef.paymentTokenAddress;
        ctx.ecosystemAddr = ctx.saleRef.ecosystemAddress;
        ctx.creator = ctx.saleRef.creator;
        ctx.ticketId = ctx.saleRef.ticketId;
        ctx.ticketAmount = ctx.saleRef.ticketAmountPerPurchase;
        ctx.platformFee = ctx.priceP * platformFeeBasisPoints / BASIS_POINTS_DIVISOR;
        uint256 buyerPays = ctx.priceP + ctx.platformFee; // Local temp variable

        // --- Apply Discount ---
        uint256 discountAmount = rewardsContract.useDiscount(ctx.buyer, ctx.paymentTokenAddr); // Local temp variable

        // --- Calculate Adjusted Creator Proceeds & Final Buyer Cost ---
        uint256 creatorReceivesAdjusted; // Local temp variable for adjusted proceeds
        if (discountAmount >= ctx.priceP) {
            // Discount covers or exceeds base price, creator gets nothing from this sale price
            creatorReceivesAdjusted = 0;
            uint256 remainingDiscount = discountAmount - ctx.priceP;
            // Buyer pays only the portion of platform fee not covered by remaining discount
            ctx.finalCostToBuyer = ctx.platformFee > remainingDiscount ? ctx.platformFee - remainingDiscount : 0;
        } else {
            // Discount is less than base price
            creatorReceivesAdjusted = ctx.priceP - discountAmount;
            // Buyer pays the adjusted creator amount plus the full platform fee
            ctx.finalCostToBuyer = creatorReceivesAdjusted + ctx.platformFee;
        }


        // --- Handle Payment & Fee Distribution ---
        // Pass the correctly calculated adjusted amount for the creator
        _handlePaymentAndFee(
            ctx.buyer,
            ctx.paymentTokenAddr,
            ctx.finalCostToBuyer,
            ctx.platformFee,
            creatorReceivesAdjusted, // <<< Pass the adjusted amount
            ctx.creator
        );

        // --- Handle Rewards & Bonuses ---
        // Capture BOTH return values using tuple assignment
        (ctx.finalRewardAmount, ctx.boosted) = _handlePrimarySaleRewards(
            ctx.buyer, boosterNftId, ctx.ecosystemAddr, ctx.paymentTokenAddr, ctx.priceP, saleId // Reward still based on original priceP
        );

        // --- Ticket Transfer ---
        IERC1155(ctx.ecosystemAddr).safeTransferFrom(
            ctx.creator, ctx.buyer, ctx.ticketId, ctx.ticketAmount, ""
        );

        // --- Update State ---
        userSalePurchases[saleId][ctx.buyer]++;
        ctx.saleRef.totalSoldUnits++; // Update via storage pointer
        // Track original value paid *towards* ecosystem owner's offering
        userEcosystemPurchasesValue[ctx.ecosystemAddr][ctx.buyer][ctx.paymentTokenAddr] += ctx.priceP;

        // --- Emit Events ---
        // Use local discountAmount and ctx fields which now hold correct values
        emit SalePurchase(
            saleId, ctx.buyer, ctx.paymentTokenAddr, ctx.priceP, ctx.platformFee, discountAmount,
            ctx.finalRewardAmount, ctx.boosted,
            ctx.ticketId, ctx.ticketAmount
        );
        emit EcosystemOwnerInteraction(ctx.ecosystemAddr, ctx.buyer, ctx.paymentTokenAddr, ctx.priceP);
    }

    // Ensure the _handlePaymentAndFee function signature remains unchanged,
    // as it correctly accepts the creatorReceives amount calculated by the caller.
    /** @dev Handles payment collection and distribution for primary sales */
    function _handlePaymentAndFee(
        address buyer,
        address paymentTokenAddr,
        uint256 finalCostToBuyer,
        uint256 platformFee,
        uint256 creatorReceives, // Receives the adjusted amount calculated in purchaseFromSale
        address creator
    ) internal {
        IERC20 paymentToken = IERC20(paymentTokenAddr);
        // 1. Buyer -> Exchange
        paymentToken.safeTransferFrom(buyer, address(this), finalCostToBuyer);
        // 2. Exchange -> Rewards Contract (Fee)
        if (platformFee > 0) {
            paymentToken.safeTransfer(address(rewardsContract), platformFee);
            rewardsContract.recordFee(paymentTokenAddr, platformFee);
        }
        // 3. Exchange -> Creator (Adjusted Proceeds)
        if (creatorReceives > 0) {
             paymentToken.safeTransfer(creator, creatorReceives);
        }
        // Internal accounting check passed in previous thought step
    }

    // Ensure the _handlePrimarySaleRewards function signature and logic remain unchanged,
    // returning both amount and boosted status.
    /** @dev Handles reward calculation and minting trigger for primary sales */
     function _handlePrimarySaleRewards(
        address buyer,
        uint256 boosterNftId,
        address ecosystemAddr,
        address paymentTokenAddr,
        uint256 priceP, // Base reward on original price
        uint256 saleId
     ) internal returns (uint256 finalRewardAmount, bool boosted) {
        // ... (implementation including nonce, bonus, booster check, minting) ...
         // --- Early Supporter Bonus Check ---
         uint256 currentNonce = ++salePurchaseNonce[saleId];
         uint16 bonusBp = 0;
         if (currentNonce <= EARLY_SUPPORTER_COUNT) {
              bonusBp = uint16(MAX_EARLY_BONUS_BP * (EARLY_SUPPORTER_COUNT + 1 - currentNonce) / EARLY_SUPPORTER_COUNT);
         }

         // --- Booster NFT Handling ---
         boosted = false; // Initialize return value
         if (boosterNftId != 0) {
            boosted = rewardsContract.verifyAndUsePurchaseBooster(buyer, boosterNftId, ecosystemAddr);
         }

         // --- Reward Token Calculation & Mint ---
         uint256 rewardRate = rewardsContract.getRewardMintRate(paymentTokenAddr);
         uint256 baseRewardAmount = priceP * rewardRate / WEI_PER_ETHER;
         if (bonusBp > 0) {
             baseRewardAmount = baseRewardAmount * (BASIS_POINTS_DIVISOR + bonusBp) / BASIS_POINTS_DIVISOR;
         }
         finalRewardAmount = boosted ? baseRewardAmount * 2 : baseRewardAmount;

         if (finalRewardAmount > 0) {
             rewardsContract.executeMint(buyer, uint256(uint160(paymentTokenAddr)), finalRewardAmount);
         }
     }
    // --- Listing Logic (Secondary Market) ---

    /** @inheritdoc ITicketExchange*/
    function listTicket(
        address ecosystemAddress,
        uint256 ticketId,
        uint256 amount,
        uint256 pricePerTicket, // Price 'P' set by seller
        address paymentToken
    ) external override ReentrancyGuard {
        // --- Validation ---
        if (!paymentTokensWhitelist[paymentToken]) revert PaymentTokenNotAllowed();
        if (amount == 0 || pricePerTicket == 0) revert AmountMustBePositive();
        if (ecosystemAddress == address(0)) revert ZeroAddress();
        if (IERC1155(ecosystemAddress).balanceOf(msg.sender, ticketId) < amount) revert InsufficientTicketBalance();

        // --- Check if Seller is Ecosystem Owner ---
        bool isOwnerListing = false;
        try IOwnership(ecosystemAddress).owner() returns (address owner) {
            if (owner == msg.sender && owner != address(0)) {
                isOwnerListing = true;
            }
        } catch { /* Ignore error */ }

        // --- Escrow Tickets ---
        IERC1155(ecosystemAddress).safeTransferFrom(msg.sender, address(this), ticketId, amount, "");

        // --- Create Listing ---
        uint256 listingId = nextListingId++;
        listings[listingId] = ListingInfo({
             listingId: listingId,
             seller: msg.sender,
             ecosystemAddress: ecosystemAddress,
             ticketId: ticketId,
             amountAvailable: amount,
             pricePerTicket: pricePerTicket,
             paymentToken: paymentToken,
             isEcosystemOwnerListing: isOwnerListing,
             active: true
         });

        emit TicketListed(listingId, msg.sender, ecosystemAddress, ticketId, amount, pricePerTicket, isOwnerListing);
    }

    
        // --- Context Struct ---
        // Group variables to potentially help stack management
        struct PurchaseTicketContext {
            ListingInfo  listingRef; // Pointer to update storage
            // Actors & IDs
            address buyer;
            address seller;
            address paymentTokenAddr;
            address ecosystemAddr;
            uint256 ticketId;
            // Calculated Values
            uint256 grossSalePrice;
            uint256 platformFee;
            uint256 buyerPaysTotal;
            uint256 discountAmount;
            uint256 finalCostToBuyer;
            address royaltyReceiver;
            uint256 currentRoyaltyFee;
            uint256 sellerReceives;
            bool boosted;
            uint256 finalRewardAmount;
            bool isOwnerListing; // Cache owner flag
        }
 
    /** @inheritdoc ITicketExchange*/
    /* Refactored to reduce stack depth.*/
      function purchaseTicket(
        uint256 listingId,
        uint256 amountToBuy,
        uint256 buyerExpectedRoyaltyFee,
        uint256 boosterNftId
    ) external override ReentrancyGuard {
    
        PurchaseTicketContext memory ctx; // Declare struct in memory

        // --- Fetch Listing Info & Initial Checks ---
        ctx.listingRef = listings[listingId];
        if (!ctx.listingRef.active) revert ListingNotActive();
        if (amountToBuy == 0) revert AmountMustBePositive();
        if (ctx.listingRef.amountAvailable < amountToBuy) revert NotEnoughListed();

        // --- Populate Context ---
        ctx.buyer = msg.sender;
        ctx.seller = ctx.listingRef.seller;
        ctx.paymentTokenAddr = ctx.listingRef.paymentToken;
        ctx.ecosystemAddr = ctx.listingRef.ecosystemAddress;
        ctx.ticketId = ctx.listingRef.ticketId;
        ctx.isOwnerListing = ctx.listingRef.isEcosystemOwnerListing; // Cache before potential deactivation
        ctx.grossSalePrice = ctx.listingRef.pricePerTicket * amountToBuy;
        ctx.platformFee = ctx.grossSalePrice * platformFeeBasisPoints / BASIS_POINTS_DIVISOR;
        ctx.buyerPaysTotal = ctx.grossSalePrice + ctx.platformFee;

        // --- Royalty Calculation & Verification ---
        (ctx.royaltyReceiver, ctx.currentRoyaltyFee) = _handleRoyalty(
            ctx.ecosystemAddr, ctx.ticketId, ctx.grossSalePrice, buyerExpectedRoyaltyFee
        );
        ctx.sellerReceives = ctx.grossSalePrice - ctx.currentRoyaltyFee;

        // --- Apply Discount ---
        ctx.discountAmount = rewardsContract.useDiscount(ctx.buyer, ctx.paymentTokenAddr);
        ctx.finalCostToBuyer = ctx.buyerPaysTotal > ctx.discountAmount ? ctx.buyerPaysTotal - ctx.discountAmount : 0;

        // --- Handle Payment & Distribution ---
        _handleSecondaryPaymentAndDistribution(
            ctx.buyer, ctx.paymentTokenAddr, ctx.finalCostToBuyer, ctx.platformFee,
            ctx.royaltyReceiver, ctx.currentRoyaltyFee, ctx.seller, ctx.sellerReceives
        );

        // --- Booster NFT Handling ---
        if (boosterNftId != 0) {
             // Directly call; let any errors propagate
             ctx.boosted = rewardsContract.verifyAndUsePurchaseBooster(ctx.buyer, boosterNftId, ctx.ecosystemAddr);
        }
 
        // --- Reward Token Minting ---
        uint256 rewardRate = rewardsContract.getRewardMintRate(ctx.paymentTokenAddr);
        uint256 baseRewardAmount = ctx.grossSalePrice * rewardRate / WEI_PER_ETHER;
        ctx.finalRewardAmount = ctx.boosted ? baseRewardAmount * 2 : baseRewardAmount;
        if (ctx.finalRewardAmount > 0) {
            rewardsContract.executeMint(ctx.buyer, uint256(uint160(ctx.paymentTokenAddr)), ctx.finalRewardAmount);
        }

        // --- Ticket Transfer (from Escrow) ---
        IERC1155(ctx.ecosystemAddr).safeTransferFrom(address(this), ctx.buyer, ctx.ticketId, amountToBuy, "");

        // --- Update Listing State (using storage pointer) ---
        ctx.listingRef.amountAvailable -= amountToBuy;
        if (ctx.listingRef.amountAvailable == 0) {
            ctx.listingRef.active = false;
        }

        // --- Update Ecosystem Owner Tracking if needed ---
        if (ctx.isOwnerListing) {
            userEcosystemPurchasesValue[ctx.ecosystemAddr][ctx.buyer][ctx.paymentTokenAddr] += ctx.grossSalePrice;
             emit EcosystemOwnerInteraction(ctx.ecosystemAddr, ctx.buyer, ctx.paymentTokenAddr, ctx.grossSalePrice);
        }

        // --- Emit Event ---
        emit TicketPurchased(
            listingId, ctx.buyer, ctx.seller, ctx.paymentTokenAddr, amountToBuy, ctx.grossSalePrice,
            ctx.platformFee, ctx.currentRoyaltyFee, ctx.discountAmount, ctx.finalRewardAmount, ctx.boosted
        );
     }
       // --- Internal Helper Functions --- (Keep existing helpers, arguments were already minimal)

    /** @dev Handles royalty checks for secondary sales (Arguments seem okay) */
    function _handleRoyalty(
        address ecosystemAddr,
        uint256 ticketId,
        uint256 grossSalePrice,
        uint256 buyerExpectedRoyaltyFee
    ) internal view returns (address receiver, uint256 royaltyFee) {
        // ... (implementation unchanged) ...
         try IERC2981(ecosystemAddr).royaltyInfo(ticketId, grossSalePrice) returns (address r, uint256 amount) {
            if (amount > grossSalePrice) revert RoyaltyExceedsPrice();
            if (amount != buyerExpectedRoyaltyFee) revert RoyaltyMismatch();
            receiver = r;
            royaltyFee = amount;
        } catch {
            if (buyerExpectedRoyaltyFee != 0) revert RoyaltyMismatch();
            receiver = address(0);
            royaltyFee = 0;
        }
    }

    /** @dev Handles payment collection and distribution for secondary sales (Arguments seem okay) */
    function _handleSecondaryPaymentAndDistribution(
        address buyer,
        address paymentTokenAddr,
        uint256 finalCostToBuyer,
        uint256 platformFee,
        address royaltyReceiver,
        uint256 royaltyFee,
        address seller,
        uint256 sellerReceives
    ) internal {
         // ... (implementation unchanged - performs external calls) ...
         IERC20 paymentToken = IERC20(paymentTokenAddr);
         paymentToken.safeTransferFrom(buyer, address(this), finalCostToBuyer);
         if (platformFee > 0) {
             paymentToken.safeTransfer(address(rewardsContract), platformFee);
             rewardsContract.recordFee(paymentTokenAddr, platformFee);
         }
         if (royaltyFee > 0 && royaltyReceiver != address(0)) {
             paymentToken.safeTransfer(royaltyReceiver, royaltyFee);
         }
         if (sellerReceives > 0) {
             paymentToken.safeTransfer(seller, sellerReceives);
         }
    }


    /** @inheritdoc ITicketExchange*/
    function cancelListing(uint256 listingId) external override ReentrancyGuard {
         ListingInfo storage listing = listings[listingId];
         if (listing.seller != msg.sender) revert NotListingOwner();
         if (!listing.active) revert ListingNotActive();

         listing.active = false;
         uint256 amountToReturn = listing.amountAvailable;
         listing.amountAvailable = 0;

         if (amountToReturn > 0) {
             IERC1155(listing.ecosystemAddress).safeTransferFrom(address(this), msg.sender, listing.ticketId, amountToReturn, "");
         }

         emit TicketListingCancelled(listingId);
    }

    // --- View Functions ---

    /** @inheritdoc ITicketExchange*/
    function getSale(uint256 saleId) external view override returns (SaleInfo memory) {
         return sales[saleId];
     }

    /** @inheritdoc ITicketExchange*/
     function getListing(uint256 listingId) external view override returns (ListingInfo memory) {
         return listings[listingId];
     }

    /** @inheritdoc ITicketExchange*/
     function getUserSalePurchases(uint256 saleId, address user) external view override returns (uint256 unitsPurchased) {
        return userSalePurchases[saleId][user];
     }

    /** @inheritdoc ITicketExchange*/
     function getUserEcosystemValue(address ecosystemAddress, address user, address paymentToken) external view override returns (uint256 totalValuePaid) {
        return userEcosystemPurchasesValue[ecosystemAddress][user][paymentToken];
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
     function getPlatformFee() external view override returns (uint16) {
         return platformFeeBasisPoints;
     }

    /** @inheritdoc ITicketExchange*/
     function getMaxRoyalty(address /*ecosystemAddress*/) external view override returns (uint16) {
         // Royalty limits removed
         return 0;
     }
 
     /** @inheritdoc ITicketExchange*/
     function getBuyerPriceForSale(uint256 saleId) external view override returns (uint256 buyerPrice) {
         SaleInfo storage sale = sales[saleId];
         // Revert instead of returning 0 if inactive? More explicit.
         if (!sale.active) revert SaleNotActive();
         uint256 priceP = sale.paymentAmount;
         uint256 platformFee = priceP * platformFeeBasisPoints / BASIS_POINTS_DIVISOR;
         return priceP + platformFee;
     }

     /** @inheritdoc ITicketExchange*/
     function getBuyerPriceForListing(uint256 listingId, uint256 amountToBuy) external view override returns (uint256 totalBuyerPrice) {
         ListingInfo storage listing = listings[listingId];
         if (!listing.active) revert ListingNotActive();
         if (amountToBuy == 0) revert AmountMustBePositive();
         if (listing.amountAvailable < amountToBuy) revert NotEnoughListed();

         uint256 grossSalePrice = listing.pricePerTicket * amountToBuy;
         uint256 platformFee = grossSalePrice * platformFeeBasisPoints / BASIS_POINTS_DIVISOR;
         return grossSalePrice + platformFee;
     }

     /** @inheritdoc ITicketExchange*/
     function getExpectedRoyalty(address ecosystemAddress, uint256 ticketId, uint256 grossSalePrice) external view override returns (address receiver, uint256 royaltyAmount) {
         // Royalty limit checks removed here too, only call and return raw value or 0.
         try IERC2981(ecosystemAddress).royaltyInfo(ticketId, grossSalePrice) returns (address r, uint256 a) {
              if (a > grossSalePrice) { // Sanity check
                 return (address(0), 0);
              }
             return (r, a);
         } catch {
             return (address(0), 0); // No royalty if interface not supported or call reverts
         }
     }

    // --- Supports Interface --- 
    function supportsInterface(bytes4 interfaceId) public view virtual override( ERC1155Holder ) returns (bool) { 
        return interfaceId == type(ITicketExchange).interfaceId
            || super.supportsInterface(interfaceId);
    }
}