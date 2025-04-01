// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../facets/ERC2981/IERC2981.sol"; // Include needed interfaces
  
/**
 * @title ITicketExchange Interface
 * @dev Interface for the multi-ecosystem ticket marketplace contract.
 */
interface ITicketExchange {
    // --- Structs for return types ---
    struct SaleInfo {
        uint256 saleId;
        address creator; // Must be ecosystem owner
        address ecosystemAddress; // The ecosystem/ticket contract address
        uint32 startTime;
        uint32 endTime;
        uint16 membershipLevel;
        address paymentTokenAddress;
        uint256 limitPerUser;
        uint256 predecessorSaleId;
        uint256 ticketId; // Assuming one ticket type per primary sale now
        uint256 ticketAmountPerPurchase; // Amount per purchase unit
        uint256 paymentAmount; // Price ('P') per purchase unit (excludes platform fee)
        uint256 totalSoldUnits;
        bool active;
        // isEcosystemOwnerSale is implicitly true as only owner can create
    }
    struct ListingInfo {
        uint256 listingId;
        address seller;
        address ecosystemAddress; // The ecosystem/ticket contract address
        uint256 ticketId;
        uint256 amountAvailable;
        uint256 pricePerTicket; // Price 'P' set by seller (excludes platform fee, includes royalty base)
        address paymentToken;
        bool isEcosystemOwnerListing; // True if seller == owner at time of listing
        bool active;
    }
 
    // --- Events ---
    event SaleCreated(uint256 indexed saleId, address indexed creator, address indexed ecosystemAddress, address paymentTokenAddress, uint256 ticketId, uint256 paymentAmount);
    event SalePurchase(uint256 indexed saleId, address indexed buyer, address indexed paymentTokenAddress, uint256 valuePaid, uint256 platformFee, uint256 discountApplied, uint256 rewardTokensMinted, bool boosterNftUsed, uint256 ticketId, uint256 ticketAmountPerPurchase);
    event EcosystemOwnerInteraction(address indexed ecosystemAddress, address indexed user, address indexed paymentToken, uint256 valuePaid); // Tracks owner sales/listings purchases
    event TicketListed(uint256 indexed listingId, address indexed seller, address indexed ecosystemAddress, uint256  ticketId, uint256 amount, uint256 pricePerTicket, bool isOwnerListing);
    event TicketPurchased(uint256 indexed listingId, address indexed buyer, address indexed seller, address paymentTokenAddress, uint256 amountBought, uint256 grossSalePrice, uint256 platformFee, uint256 royaltyPaid, uint256 discountApplied, uint256 rewardTokensMinted, bool boosterNftUsed);
    event TicketListingCancelled(uint256 indexed listingId);
    event RewardsContractSet(address indexed rewardsContract);
    // Removed TicketTokenSet as we don't have a single ticket token anymore
    event PlatformFeeSet(uint16 feeBasisPoints);
    event PaymentTokenWhitelisted(address indexed tokenAddress, bool allowed);
    event MaxRoyaltySet(address indexed ecosystemAddress, uint16 maxBasisPoints); // For royalty limit

    // --- Sale Functions ---
    function createSale(
        address ecosystemAddress, // The ecosystem/ticket contract
        uint32 startTime,
        uint32 endTime,
        uint16 membershipLevel,
        address paymentTokenAddress,
        uint256 limitPerUser,
        uint256 predecessorSaleId,
        uint256 ticketId, // Single ticket type per sale
        uint256 ticketAmountPerPurchase, // Amount per unit
        uint256 paymentAmount // Price 'P' per unit
    ) external;

    function purchaseFromSale(
        uint256 saleId,
        uint256 boosterNftId // Optional: Pass 0 if not using
    ) external;

    // --- Listing Functions ---
    function listTicket(
        address ecosystemAddress, // The ecosystem/ticket contract
        uint256 ticketId,
        uint256 amount,
        uint256 pricePerTicket, // Price 'P'
        address paymentToken
    ) external;

    function purchaseTicket(
        uint256 listingId,
        uint256 amountToBuy,
        uint256 buyerExpectedRoyaltyFee, // Royalty verification
        uint256 boosterNftId // Optional: Pass 0 if not using
    ) external;

    function cancelListing(uint256 listingId) external;

    // --- Admin / Configuration ---
    function setRewardsContract(address _rewardsContract) external;
    function setPlatformFee(uint16 _feeBasisPoints) external;
    function setPaymentTokenWhitelist(address tokenAddress, bool allowed) external;
    function setMaxRoyalty(address ecosystemAddress, uint16 _maxBasisPoints) external; // 0 address for global?
    function setGlobalMaxRoyalty(uint16 _maxBasisPoints) external;


    // --- View Functions ---
    function getSale(uint256 saleId) external view returns (SaleInfo memory);
    function getListing(uint256 listingId) external view returns (ListingInfo memory);
    function getUserSalePurchases(uint256 saleId, address user) external view returns (uint256 unitsPurchased);
    function getUserEcosystemValue(address ecosystemAddress, address user, address paymentToken) external view returns (uint256 totalValuePaid); // Renamed for clarity
    function isPaymentTokenAllowed(address token) external view returns (bool);
    function getRewardsContract() external view returns (address);
    function getPlatformFee() external view returns (uint16);
    function getMaxRoyalty(address ecosystemAddress) external view returns (uint16); // Checks specific then global
    // Calculate price buyer pays (includes platform fee)
    function getBuyerPriceForSale(uint256 saleId) external view returns (uint256 buyerPrice);
    function getBuyerPriceForListing(uint256 listingId, uint256 amountToBuy) external view returns (uint256 totalBuyerPrice);
    // Calculate expected royalty for UI hints
    function getExpectedRoyalty(address ecosystemAddress, uint256 ticketId, uint256 grossSalePrice) external view returns (address receiver, uint256 royaltyAmount);

}