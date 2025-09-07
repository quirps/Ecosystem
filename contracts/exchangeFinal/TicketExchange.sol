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
import { IEcosystemRegistry } from "../registry/IRegistry.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
// Libraries
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// Utilities & Security
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {Ownable} from "./utils/Ownable.sol";
import {ReentrancyGuardContract} from "../ReentrancyGuard.sol";
// Debugging (Optional)
import "hardhat/console.sol";
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
   // --- NEW: Trust & Registry State ---
    IEcosystemRegistry public ecosystemRegistry;
    mapping(address => uint32) public trustedTokens; // tokenAddress => expiryTimestamp
   // --- NEW: Time-Delayed Currency Proposals ---
    struct Proposal {
        bool exists;
        uint256 approvalTimestamp; // The earliest time the proposal can be approved
    }
       mapping(address => Proposal) public currencyProposals;
    uint256 public constant CURRENCY_PROPOSAL_DELAY = 7 days; // Time delay for new currencies
    // --- Exchange Configuration ---
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
    
    // --- Constructor ---
    constructor(address _rewardsContractAddress, address _rewardTokenAddress, address _owner) Ownable() {
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
    /**
     * @notice Sets the address of the EcosystemRegistry. Can only be set once.
     */
    function setEcosystemRegistry(address _ecosystemRegistry) external onlyOwner {
        require(address(ecosystemRegistry) == address(0), "Registry already set");
        require(_ecosystemRegistry != address(0), "Zero address");
        ecosystemRegistry = IEcosystemRegistry(_ecosystemRegistry);
    }
    /** @inheritdoc ITicketExchange*/
    function setMaxRoyalty(address /*ecosystemAddress*/, uint16 /*_maxBasisPoints*/) external override onlyOwner {
        revert("Royalty limits removed; use buyerExpectedRoyaltyFee check.");
    }
    /** @inheritdoc ITicketExchange*/
    function setGlobalMaxRoyalty(uint16 /*_maxBasisPoints*/) external override onlyOwner {
        revert("Royalty limits removed; use buyerExpectedRoyaltyFee check.");
    }
    function adminMintTickets(
        address /*to*/,
        uint256[] calldata /*ids*/,
        uint256[] calldata /*amounts*/,
        bytes calldata /*data*/
    ) external /*override removed*/ onlyOwner {
        revert("adminMintTickets removed; manage ticket supply externally per ecosystem.");
    }
        /**
     * @notice Hook for the EcosystemRegistry to update the trust status of a token.
     * @dev When an ecosystem is created, the registry calls this with a max timestamp.
     * When an ecosystem migrates, it calls this with a short expiry date.
     * @param tokenAddress The address of the ERC20 or ERC1155 token.
     * @param expiryTimestamp The Unix timestamp when trust in this token expires.
     */
    function updateTrustStatus(address tokenAddress, uint32 expiryTimestamp) external  {
        require(msg.sender == address(ecosystemRegistry), "Only registry can update trust");
        trustedTokens[tokenAddress] = expiryTimestamp;
    }
        /**
     * @notice Proposes a new currency to be added to the marketplace.
     * @dev Starts a time delay, after which the currency can be approved.
     * @param tokenAddress The address of the new ERC20 currency to propose.
     */
    function proposeCurrency(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "Zero address");
        require(!currencyProposals[tokenAddress].exists, "Proposal already exists");
        currencyProposals[tokenAddress] = Proposal({
            exists: true,
            approvalTimestamp: block.timestamp + CURRENCY_PROPOSAL_DELAY
        });
        // Emit an event here
    }
    /**
     * @notice Approves a currency proposal after the time delay has passed.
     * @dev Makes the currency permanently trusted on the exchange.
     * @param tokenAddress The address of the currency to approve.
     */
    function approveCurrency(address tokenAddress) external onlyOwner {
        Proposal storage proposal = currencyProposals[tokenAddress];
        require(proposal.exists, "Proposal does not exist");
        require(block.timestamp >= proposal.approvalTimestamp, "Time delay not passed");
        // Mark as permanently trusted and remove the proposal
        trustedTokens[tokenAddress] = type(uint32).max;
        delete currencyProposals[tokenAddress];
        // Emit an event here
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
        uint256 totalTicketsForSale, // NEW PARAMETER
        uint256 paymentAmount, // Price per single ticket
        DistributionShare[] calldata distribution
    ) external returns (uint256 currentSaleId_){
        if (ecosystemAddress == address(0) || paymentTokenAddress == address(0)) revert ZeroAddress();
        if (startTime >= endTime) revert InvalidTimeRange();
        if (paymentAmount == 0) revert PaymentAmountZero();
        if (totalTicketsForSale == 0) revert AmountMustBePositive(); // Sale must have tickets

        // Check if payment token is trusted
        if (trustedTokens[paymentTokenAddress] == 0 || trustedTokens[paymentTokenAddress] < block.timestamp) {
            revert PaymentTokenNotAllowed();
        }

        // Validate distribution shares
        uint256 totalBasisPoints = 0;
        for (uint i = 0; i < distribution.length; i++) {
            if (distribution[i].recipient == address(0)) revert ZeroAddress();
            totalBasisPoints += distribution[i].basisPoints;
        }
        if (totalBasisPoints > BASIS_POINTS_DIVISOR) revert("Distribution exceeds 100%");

        currentSaleId_ = nextSaleId++;
        sales[currentSaleId_] = SaleInfo({
            saleId: currentSaleId_,
            creator: msg.sender,
            ecosystemAddress: ecosystemAddress,
            startTime: startTime,
            endTime: endTime,
            membershipLevel: membershipLevel,
            paymentTokenAddress: paymentTokenAddress,
            limitPerUser: limitPerUser,
            predecessorSaleId: predecessorSaleId,
            ticketId: ticketId,
            ticketAmount: totalTicketsForSale, // Store the total tickets for the sale
            // ticketAmountPerPurchase: 1, // REMOVED: Implicitly 1 now
            paymentAmount: paymentAmount,
            totalSoldUnits: 0,
            active: true,
            distribution: distribution
        });

        emit SaleCreated(
            currentSaleId_,
            msg.sender,
            ecosystemAddress,
            paymentTokenAddress,
            ticketId,
            paymentAmount
        );
       
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
    }
   /** @inheritdoc ITicketExchange*/
  function purchaseFromSale(
        uint256 saleId,
        uint256 amountToBuy,
        address txInitiator
    ) external override ReentrancyGuard {
        console.logUint(111);

        // Declare a storage pointer to the sale info
        ITicketExchange.SaleInfo storage currentSale = sales[saleId]; // Correct way to get a storage reference

        if (!currentSale.active) revert SaleNotActive();
        if (!(block.timestamp >= currentSale.startTime && block.timestamp <= currentSale.endTime)) revert TimeNotInRange();
        
        // Use a memory struct for other context variables
        PurchaseSaleContext memory ctx;
        ctx.buyer = msg.sender;
        
        if (amountToBuy == 0) revert AmountMustBePositive();
        
        // --- DEBUGGING LOGS FOR NotEnoughTicketsInSale ---
        console.log("Debugging NotEnoughTicketsInSale check:");
        console.logUint(saleId);
        console.logUint(currentSale.totalSoldUnits); // Current units sold in this sale
        console.logUint(amountToBuy); // Amount user is trying to buy
        console.logUint(currentSale.ticketAmount); // Total tickets available for this sale
        console.logUint(currentSale.totalSoldUnits + amountToBuy); // Sum of current sold + amount to buy
        // --- END DEBUGGING LOGS ---

        if (currentSale.totalSoldUnits + amountToBuy > currentSale.ticketAmount) revert NotEnoughTicketsInSale();
        
        if (currentSale.limitPerUser > 0 && userSalePurchases[saleId][ctx.buyer] + amountToBuy > currentSale.limitPerUser) revert MaxTicketsPerBuyerExceeded();

        ctx.paymentTokenAddr = currentSale.paymentTokenAddress;
        ctx.ecosystemAddr = currentSale.ecosystemAddress;
        ctx.creator = currentSale.creator;
        ctx.ticketId = currentSale.ticketId;
        
        uint256 grossSalePrice = currentSale.paymentAmount * amountToBuy;

        console.log("TX.purchaseFromSale: Before platformFee calculation");
        console.logUint(grossSalePrice);
        console.logUint(platformFeeBasisPoints);
        console.logUint(BASIS_POINTS_DIVISOR);

        ctx.platformFee = (grossSalePrice * platformFeeBasisPoints) / BASIS_POINTS_DIVISOR;
        // uint256 buyerPays = grossSalePrice + ctx.platformFee; // Not directly used after this line

        uint256 discountAmount = 0;
        
        uint256 creatorReceivesAdjusted;
        if (discountAmount >= grossSalePrice) {
            creatorReceivesAdjusted = 0;
            uint256 remainingDiscount = discountAmount - grossSalePrice;
            ctx.finalCostToBuyer = ctx.platformFee > remainingDiscount ? ctx.platformFee - remainingDiscount : 0;
        } else {
            creatorReceivesAdjusted = grossSalePrice - discountAmount;
            ctx.finalCostToBuyer = creatorReceivesAdjusted + ctx.platformFee;
        }

        console.log("TX.purchaseFromSale: Values before calling _handlePaymentAndFee");
        console.logUint(ctx.platformFee);
        console.logAddress(txInitiator);
        console.logUint(ctx.finalCostToBuyer);

        _handlePaymentAndFee(
            saleId,
            ctx.buyer,
            ctx.paymentTokenAddr,
            ctx.finalCostToBuyer,
            ctx.platformFee,
            creatorReceivesAdjusted,
            ctx.creator,
            txInitiator
        );

        IERC1155(ctx.ecosystemAddr).safeTransferFrom(ctx.creator, ctx.buyer, ctx.ticketId, amountToBuy, "");

        userSalePurchases[saleId][ctx.buyer] += amountToBuy;
        currentSale.totalSoldUnits += amountToBuy; // <--- This will now correctly update storage
        userEcosystemPurchasesValue[ctx.ecosystemAddr][ctx.buyer][ctx.paymentTokenAddr] += grossSalePrice;

        emit SalePurchase(
            saleId,
            ctx.buyer,
            ctx.paymentTokenAddr,
            grossSalePrice,
            ctx.platformFee,
            discountAmount,
            0,
            ctx.ticketId,
            amountToBuy
        );
        emit EcosystemOwnerInteraction(ctx.ecosystemAddr, ctx.buyer, ctx.paymentTokenAddr, grossSalePrice);
    }
    // Ensure the _handlePaymentAndFee function signature remains unchanged,
    // as it correctly accepts the creatorReceives amount calculated by the caller.
    /** @dev Handles payment collection and distribution for primary sales */
    function _handlePaymentAndFee(
        uint256 saleId, // <-- NEW PARAMETER
        address buyer,
        address paymentTokenAddr,
        uint256 finalCostToBuyer,
        uint256 platformFee,
        uint256 creatorReceives, // Receives the adjusted amount calculated in purchaseFromSale
        address creator,
        address txInitiator // <-- NEW PARAMETER
    ) internal {
        IERC20 paymentToken = IERC20(paymentTokenAddr);
        // 1. Collect total payment from buyer into this contract
        paymentToken.transferFrom(buyer, address(this), finalCostToBuyer);
        console.log(1234);
        // 2. Handle platform fee distribution via the Rewards contract
        if (platformFee > 0) {
            // Transfer the full fee amount to the rewards contract, which will then split it internally
            paymentToken.transfer(address(rewardsContract), platformFee);
            console.log(12345);
            rewardsContract.recordFee(paymentTokenAddr, platformFee, txInitiator);
        }
        console.log(2345);
        // 3. Handle creator proceeds distribution
        if (creatorReceives > 0) {
            SaleInfo storage sale = sales[saleId]; // Fetch the sale to access its distribution
            if (sale.distribution.length > 0) {
                // --- New Logic: Split proceeds ---
                uint256 distributedAmount = 0;
                for (uint i = 0; i < sale.distribution.length; i++) {
                    DistributionShare storage share = sale.distribution[i];
                    uint256 amountToSend = (creatorReceives * share.basisPoints) / BASIS_POINTS_DIVISOR;
                    if (amountToSend > 0) {
                        console.log(3456);
                        paymentToken.transfer(share.recipient, amountToSend);
                        distributedAmount += amountToSend;
                    }
                }
                // Send any remaining amount (from rounding or incomplete distribution) to the original creator
                uint256 remainder = creatorReceives - distributedAmount;
                if (remainder > 0) {
                    console.log(4567);
                    paymentToken.transfer(creator, remainder);
                }
            } else {
                // --- Original Logic: Creator gets all proceeds ---
                console.log(5678);
                paymentToken.transfer(creator, creatorReceives);
            }
        }
    }
    // Ensure the _handlePrimarySaleRewards function signature and logic remain unchanged,
    // returning amount.
    /** @dev Handles reward calculation and minting trigger for primary sales */
    function _handlePrimarySaleRewards(
        address buyer,
       
        address ecosystemAddr,
        address paymentTokenAddr,
        uint256 priceP, // Base reward on original price
        uint256 saleId
    ) internal returns (uint256 baseRewardAmount) {
        // --- Early Supporter Bonus Check ---
        uint256 currentNonce = ++salePurchaseNonce[saleId];
        uint16 bonusBp = 0;
        if (currentNonce <= EARLY_SUPPORTER_COUNT) {
            bonusBp = uint16((MAX_EARLY_BONUS_BP * (EARLY_SUPPORTER_COUNT + 1 - currentNonce)) / EARLY_SUPPORTER_COUNT);
        }
    
        // --- Reward Token Calculation & Mint ---
        uint256 rewardRate = rewardsContract.getRewardMintRate(paymentTokenAddr);
        uint256 baseRewardAmount = (priceP * rewardRate) / WEI_PER_ETHER;
        if (bonusBp > 0) {
            baseRewardAmount = (baseRewardAmount * (BASIS_POINTS_DIVISOR + bonusBp)) / BASIS_POINTS_DIVISOR;
        }
        if (baseRewardAmount > 0) {
            rewardsContract.executeMint(buyer, uint256(uint160(paymentTokenAddr)), baseRewardAmount);
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
        require(trustedTokens[paymentToken] > uint32(block.timestamp), "Payment token not trusted");
        if (amount == 0 || pricePerTicket == 0) revert AmountMustBePositive();
        if (ecosystemAddress == address(0)) revert ZeroAddress();
        if (IERC1155(ecosystemAddress).balanceOf(msg.sender, ticketId) < amount) revert InsufficientTicketBalance();
        // --- Check if Seller is Ecosystem Owner ---
        bool isOwnerListing = false;
        try IOwnership(ecosystemAddress).owner() returns (address owner) {
            if (owner == msg.sender && owner != address(0)) {
                isOwnerListing = true;
            }
        } catch {
            /* Ignore error */
        }
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
        ListingInfo listingRef; // Pointer to update storage
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
        uint256 finalRewardAmount;
        bool isOwnerListing; // Cache owner flag
    }
    /** @inheritdoc ITicketExchange*/
    /* Refactored to reduce stack depth.*/
      /** @inheritdoc ITicketExchange*/
    /* Refactored to reduce stack depth.*/
    function purchaseTicket(
        uint256 listingId,
        uint256 amountToBuy,
        uint256 buyerExpectedRoyaltyFee,
        address txInitiator // <-- THIS PARAMETER
    ) external ReentrancyGuard {
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
        ctx.platformFee = (ctx.grossSalePrice * platformFeeBasisPoints) / BASIS_POINTS_DIVISOR;
        ctx.buyerPaysTotal = ctx.grossSalePrice + ctx.platformFee;

        // --- Royalty Calculation & Verification ---
        (ctx.royaltyReceiver, ctx.currentRoyaltyFee) = _handleRoyalty(ctx.ecosystemAddr, ctx.ticketId, ctx.grossSalePrice, buyerExpectedRoyaltyFee);
        // total amount seller receives
        ctx.sellerReceives = ctx.grossSalePrice - ctx.platformFee - ctx.currentRoyaltyFee;

        // --- Apply Discount ---
        ctx.discountAmount = rewardsContract.useDiscount(ctx.buyer, ctx.paymentTokenAddr);
        ctx.finalCostToBuyer = ctx.buyerPaysTotal > ctx.discountAmount ? ctx.buyerPaysTotal - ctx.discountAmount : 0;

        // --- DEBUGGING LOGS IN TicketExchange.purchaseTicket ---
        console.log("TicketExchange.purchaseTicket: Before calling _handleSecondaryPaymentAndDistribution");
        console.logUint(ctx.platformFee); // Log platformFee here
        console.logAddress(txInitiator); // Log txInitiator here
        // --- END DEBUGGING LOGS ---

        // --- Handle Payment & Distribution ---
        _handleSecondaryPaymentAndDistribution(
            ctx.buyer,
            ctx.paymentTokenAddr,
            ctx.finalCostToBuyer,
            ctx.platformFee, // <--- This is the platformFee value being passed
            ctx.royaltyReceiver,
            ctx.currentRoyaltyFee,
            ctx.seller,
            ctx.sellerReceives,
            txInitiator // <--- This is the txInitiator value being passed
        );



        // --- Reward Token Minting ---
        uint256 rewardRate = rewardsContract.getRewardMintRate(ctx.paymentTokenAddr);
        uint256 baseRewardAmount = (ctx.grossSalePrice * rewardRate) / WEI_PER_ETHER;
        ctx.finalRewardAmount =  baseRewardAmount;
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
            listingId,
            ctx.buyer,
            ctx.seller,
            ctx.paymentTokenAddr,
            amountToBuy,
            ctx.grossSalePrice,
            ctx.platformFee,
            ctx.currentRoyaltyFee,
            ctx.discountAmount,
            ctx.finalRewardAmount
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
    /** @dev Handles payment collection and distribution for secondary sales (Arguments seem okay) */
    function _handleSecondaryPaymentAndDistribution(
        address buyer,
        address paymentTokenAddr,
        uint256 finalCostToBuyer,
        uint256 platformFee, // <--- THIS IS THE RECEIVED platformFee
        address royaltyReceiver,
        uint256 royaltyFee,
        address seller,
        uint256 sellerReceives,
        address txInitiator // <--- THIS IS THE RECEIVED txInitiator
    ) internal {
        // --- DEBUGGING LOGS IN _handleSecondaryPaymentAndDistribution ---
        console.log("_handleSecondaryPaymentAndDistribution: Received values");
        console.logUint(platformFee); // Log received platformFee
        console.logAddress(txInitiator); // Log received txInitiator
        // --- END DEBUGGING LOGS ---

        IERC20 paymentToken = IERC20(paymentTokenAddr);
        paymentToken.transferFrom(buyer, address(this), finalCostToBuyer);
        if (platformFee > 0) {
            paymentToken.transfer(address(rewardsContract), platformFee);
            // Update the call to recordFee
            rewardsContract.recordFee(paymentTokenAddr, platformFee, txInitiator);
        }
        if (royaltyFee > 0 && royaltyReceiver != address(0)) {
            paymentToken.transfer(royaltyReceiver, royaltyFee);
        }
        if (sellerReceives > 0) {
            paymentToken.transfer(seller, sellerReceives);
        }
    }
    /** @inheritdoc ITicketExchange*/
 function cancelListing(uint256 listingId) external override { // Removed onlyOwnerOrSeller modifier
    ListingInfo storage listing = listings[listingId];
    // First, check if the listing exists and is active
    if (!listing.active) revert ListingNotActive(); // This correctly catches non-existent or already inactive listings

    // Then, check permissions
    if (msg.sender != owner() && msg.sender != listing.seller) {
        revert NotListingOwner();
    }

    // If checks pass, proceed with cancellation
    listing.active = false; // Deactivate the listing

    // Return tickets from escrow to the seller
    IERC1155(listing.ecosystemAddress).safeTransferFrom(address(this), listing.seller, listing.ticketId, listing.amountAvailable, "");

    emit ListingCancelled(listingId, listing.seller, listing.ticketId, listing.amountAvailable);
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
    function getUserEcosystemValue(
        address ecosystemAddress,
        address user,
        address paymentToken
    ) external view override returns (uint256 totalValuePaid) {
        return userEcosystemPurchasesValue[ecosystemAddress][user][paymentToken];
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
        uint256 platformFee = (priceP * platformFeeBasisPoints) / BASIS_POINTS_DIVISOR;
        return priceP + platformFee;
    }
    /** @inheritdoc ITicketExchange*/
    function getBuyerPriceForListing(uint256 listingId, uint256 amountToBuy) external view override returns (uint256 totalBuyerPrice) {
        ListingInfo storage listing = listings[listingId];
        if (!listing.active) revert ListingNotActive();
        if (amountToBuy == 0) revert AmountMustBePositive();
        if (listing.amountAvailable < amountToBuy) revert NotEnoughListed();
        uint256 grossSalePrice = listing.pricePerTicket * amountToBuy;
        uint256 platformFee = (grossSalePrice * platformFeeBasisPoints) / BASIS_POINTS_DIVISOR;
        return grossSalePrice + platformFee;
    }
    /** @inheritdoc ITicketExchange*/
    function getExpectedRoyalty(
        address ecosystemAddress,
        uint256 ticketId,
        uint256 grossSalePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        // Royalty limit checks removed here too, only call and return raw value or 0.
        try IERC2981(ecosystemAddress).royaltyInfo(ticketId, grossSalePrice) returns (address r, uint256 a) {
            if (a > grossSalePrice) {
                // Sanity check
                return (address(0), 0);
            }
            return (r, a);
        } catch {
            return (address(0), 0); // No royalty if interface not supported or call reverts
        }
    }
    // --- Supports Interface ---
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Holder,IERC165) returns (bool) {
        return interfaceId == type(ITicketExchange).interfaceId || super.supportsInterface(interfaceId);
    }
} 