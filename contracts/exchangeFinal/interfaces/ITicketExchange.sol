// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ITicketExchange Interface
 * @dev Interface for the ticket marketplace contract.
 */
interface ITicketExchange {
    // --- Events (Refined) ---
    event SaleCreated(uint256 indexed saleId, address indexed creator, address indexed paymentTokenAddress, bool  isEcosystemSale, uint32 startTime, uint32 endTime);
    event SalePurchase(uint256 indexed saleId, address indexed buyer, address indexed paymentTokenAddress, uint256 amountPaid, uint256 discountApplied, uint256 rewardTokensMinted, uint256[] itemIds, uint256[] itemAmounts);
    event EcosystemOwnerSalePurchase(address indexed ecosystemAddress, address indexed buyer, uint256 value); // value = cost before discount
    event TicketListed(uint256 indexed listingId, address indexed seller, uint256 indexed ticketId, uint256 amount, uint256 pricePerTicket, address paymentToken);
    event TicketPurchased(uint256 indexed listingId, address indexed buyer, address indexed seller, address  paymentTokenAddress, uint256 amountBought, uint256 totalCost, uint256 discountApplied, uint256 rewardTokensMinted, uint256 ticketId);
    event TicketListingCancelled(uint256 indexed listingId);
    event RewardsContractSet(address indexed rewardsContract);
    event TicketTokenSet(address indexed ticketToken);
    event PlatformFeeSet(uint16 feeBasisPoints);
    event PaymentTokenWhitelisted(address indexed tokenAddress, bool allowed);

    // --- Sale Functions ---
    function createSale(
        uint32 startTime,
        uint32 endTime,
        uint16 membershipLevel,
        address paymentTokenAddress,
        uint256 limitPerUser,
        uint256 predecessorSaleId,
        uint256[] calldata itemIds, // Ticket IDs
        uint256[] calldata itemAmounts, // Amount per purchase unit
        uint256 paymentAmount // Price per purchase unit
    ) external;
    function purchaseFromSale(uint256 saleId) external; // Consider adding amount param if >1 unit can be bought

    // --- Listing Functions ---
    function listTicket(
        uint256 ticketId,
        uint256 amount,
        uint256 pricePerTicket,
        address paymentToken
    ) external;
    function purchaseTicket(uint256 listingId, uint256 amountToBuy) external;
    function cancelListing(uint256 listingId) external;

    // --- Admin / Configuration Functions ---
    function setRewardsContract(address _rewardsContract) external;
    function setTicketToken(address _ticketToken) external;
    function setPlatformFee(uint16 _feeBasisPoints) external;
    function setPaymentTokenWhitelist(address tokenAddress, bool allowed) external;
    function adminMintTickets(address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external; // For initial supply

    // --- View Functions ---
    // Define structs for returning complex data easily
    struct SaleInfo {
        uint256 saleId;
        address creator;
        uint32 startTime;
        uint32 endTime;
        uint16 membershipLevel;
        address paymentTokenAddress;
        uint256 limitPerUser;
        uint256 predecessorSaleId;
        uint256[] itemIds;
        uint256[] itemAmounts;
        uint256 paymentAmount;
        uint256 totalSold;
        bool active;
        bool isEcosystemSale;
        address ecosystemIdentifier;
    }
    struct ListingInfo {
        uint256 listingId;
        address seller;
        uint256 ticketId;
        uint256 amountAvailable;
        uint256 pricePerTicket;
        address paymentToken;
        bool active;
    }

    function getSale(uint256 saleId) external view returns (SaleInfo memory);
    function getListing(uint256 listingId) external view returns (ListingInfo memory);
    function getUserSalePurchases(uint256 saleId, address user) external view returns (uint256 unitsPurchased);
    function getUserEcosystemPurchases(address ecosystemAddress, address user) external view returns (uint256 totalValuePurchased);
    function isPaymentTokenAllowed(address token) external view returns (bool);
    function getRewardsContract() external view returns (address);
    function getTicketToken() external view returns (address);
    function getPlatformFee() external view returns (uint16);
}