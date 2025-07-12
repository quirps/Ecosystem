// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Internal Interfaces (if they were defined in separate files and used by TicketExchange)
import "./IExchangeRewards.sol"; // Assuming this interface exists
import "./IRewardToken.sol";     // Assuming this interface exists
import "../../facets/Ownership/IOwnership.sol"; // Assuming this interface exists
import "../../facets/ERC2981/IERC2981.sol"; // Assuming this interface exists
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IEcosystemRegistry } from "../../registry/IRegistry.sol"; // Assuming this interface exists
import "@openzeppelin/contracts/utils/introspection/IERC165.sol"; // For supportsInterface

/**
 * @title ITicketExchange Interface
 * @dev Interface for the TicketExchange Contract v3.
 * Defines all external and public functions, events, errors, and structs.
 */
interface ITicketExchange is IERC165 {

    // --- Structs ---
    struct DistributionShare {
        address recipient;
        uint16 basisPoints;
    }

    struct SaleInfo {
        uint256 saleId;
        address creator;
        address ecosystemAddress; // The ERC1155 contract address for the ticket
        uint32 startTime;
        uint32 endTime;
        uint16 membershipLevel;
        address paymentTokenAddress; // The ERC20 token used for payment
        uint256 limitPerUser; // Max units per user for this sale
        uint256 predecessorSaleId; // For sequential sales (0 if none)
        uint256 ticketId; // The ID of the ERC1155 ticket being sold
        uint256 ticketAmountPerPurchase; // How many tickets per purchase unit
        uint256 paymentAmount; // Price 'P' set by owner for one purchase unit
        uint256 totalSoldUnits; // Total units sold in this sale
        bool active;
        DistributionShare[] distribution; // NEW: How proceeds are split
    }

    struct ListingInfo {
        uint256 listingId;
        address seller;
        address ecosystemAddress; // The ERC1155 contract address for the ticket
        uint256 ticketId; // The ID of the ERC1155 ticket being listed
        uint256 amountAvailable; // Current amount available for purchase
        uint256 pricePerTicket; // Price 'P' set by seller for one ticket
        address paymentToken; // The ERC20 token accepted for payment
        bool isEcosystemOwnerListing; // True if listed by the ecosystem owner
        bool active;
    }

    // --- Events ---
    event RewardsContractSet(address indexed newRewardsContract);
    event PlatformFeeSet(uint16 newFeeBasisPoints);
    event SaleCreated(
        uint256 indexed saleId,
        address indexed creator,
        address indexed ecosystemAddress,
        address paymentTokenAddress,
        uint256 ticketId,
        uint256 paymentAmount
    );
    event SalePurchase(
        uint256 indexed saleId,
        address indexed buyer,
        address paymentTokenAddress,
        uint256 pricePaid, // Original price P
        uint256 platformFee,
        uint256 discountAmount,
        uint256 rewardAmount,
        bool boosted,
        uint256 ticketId,
        uint256 ticketAmount
    );
    event EcosystemOwnerInteraction(
        address indexed ecosystemAddress,
        address indexed user,
        address paymentToken,
        uint256 value
    );
    event TicketListed(
        uint256 indexed listingId,
        address indexed seller,
        address indexed ecosystemAddress,
        uint256 ticketId,
        uint256 amount,
        uint256 pricePerTicket,
        bool isEcosystemOwnerListing
    );
    event TicketPurchased(
        uint256 indexed listingId,
        address indexed buyer,
        address indexed seller,
        address paymentToken,
        uint256 amountBought,
        uint256 grossSalePrice,
        uint256 platformFee,
        uint256 royaltyFee,
        uint256 discountAmount,
        uint256 rewardAmount,
        bool boosted
    );
    event TicketListingCancelled(uint256 indexed listingId);
    event SalePaused(uint256 indexed saleId);
    event SaleUnpaused(uint256 indexed saleId);


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
    error MembershipLevelNotMet(); // Not directly used in provided code, but in interface
    error InsufficientAllowance();
    error InsufficientPaymentBalance();
    error ListingNotActive();
    error NotEnoughListed();
    error NotListingOwner();
    error TransferFailed();
    error RoyaltyMismatch();
    error RoyaltyExceedsPrice();
    error ZeroAddress();
    error BoosterNftFailed(); // Not directly used in TicketExchange, but in ExchangeRewards
    error SaleIsPaused(); // NEW
    error PurchaseAmountExceedsMax(); // NEW
    error MaxTicketsPerBuyerExceeded(); // NEW

    // --- Public Constants ---
    function CURRENCY_PROPOSAL_DELAY() external view returns (uint256);

    // --- Admin / Configuration Functions ---
    function setRewardsContract(address _rewardsContractAddress) external;
    function setPlatformFee(uint16 _feeBasisPoints) external;
    function setEcosystemRegistry(address _registryAddress) external; // Public, but only callable once
    function setMaxRoyalty(address ecosystemAddress, uint16 _maxBasisPoints) external; // Function exists but reverts
    function setGlobalMaxRoyalty(uint16 _maxBasisPoints) external; // Function exists but reverts
    function adminMintTickets(address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external; // Function exists but reverts
    function updateTrustStatus(address tokenAddress, uint32 expiryTimestamp) external; // External, callable by registry
    function proposeCurrency(address tokenAddress) external;
    function approveCurrency(address tokenAddress) external;


    // --- Sale Logic (Primary Market - Owner Only) ---
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
        uint256 paymentAmount,
        DistributionShare[] calldata distribution
    ) external;
    function purchaseFromSale(
        uint256 saleId,
        uint256 boosterNftId,
        address txInitiator
    ) external;

    // --- Listing Logic (Secondary Market) ---
    function listTicket(
        address ecosystemAddress,
        uint256 ticketId,
        uint256 amount,
        uint256 pricePerTicket,
        address paymentToken
    ) external;
    function purchaseTicket(
        uint256 listingId,
        uint256 amountToBuy,
        uint256 buyerExpectedRoyaltyFee,
        uint256 boosterNftId,
        address txInitiator
    ) external;
    function cancelListing(uint256 listingId) external;

    // --- View Functions (Public State Variables) ---
    // function rewardsContract() external view returns (IExchangeRewards);
    // function rewardToken() external view returns (IRewardToken);
    // function ecosystemRegistry() external view returns (IEcosystemRegistry);
    // function trustedTokens(address) external view returns (uint32);
    // function currencyProposals(address) external view returns (bool exists, uint256 approvalTimestamp);
    // function platformFeeBasisPoints() external view returns (uint16);
    // function sales(uint256) external view returns (SaleInfo memory); // Getter for sales mapping
    // function nextSaleId() external view returns (uint256);
    // function nextListingId() external view returns (uint256);
    // function userSalePurchases(uint256, address) external view returns (uint256);
    // function userEcosystemPurchasesValue(address, address, address) external view returns (uint256);
    // function salePurchaseNonce(uint256) external view returns (uint256);


    // --- View Functions (Explicit Getters) ---
    function getSale(uint256 saleId) external view returns (SaleInfo memory);
    function getListing(uint256 listingId) external view returns (ListingInfo memory);
    function getUserSalePurchases(uint256 saleId, address user) external view returns (uint256 unitsPurchased);
    function getUserEcosystemValue(
        address ecosystemAddress,
        address user,
        address paymentToken
    ) external view returns (uint256 totalValuePaid);
    function getRewardsContract() external view returns (address);
    function getPlatformFee() external view returns (uint16);
    function getMaxRoyalty(address ecosystemAddress) external view returns (uint16);
    function getBuyerPriceForSale(uint256 saleId) external view returns (uint256 buyerPrice);
    function getBuyerPriceForListing(uint256 listingId, uint256 amountToBuy) external view returns (uint256 totalBuyerPrice);
    function getExpectedRoyalty(
        address ecosystemAddress,
        uint256 ticketId,
        uint256 grossSalePrice
    ) external view returns (address receiver, uint256 royaltyAmount);

    // --- ERC165 Support ---
}
