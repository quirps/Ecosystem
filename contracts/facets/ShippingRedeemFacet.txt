pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ShippingRedeem is Ownable {
    using SafeMath for uint256;

    struct ShippingTicket {
        address userAddress;
        uint32 maxRedeemTime;
        uint32 maxFreeHoldTime;
        bool redeemed;
        bool completed;
        bool cancelled;
        bool shipped;
        uint256 linearRate;
        uint32 redeemedTime;
        bool sellRated;
        bool buyerRated;
        uint32 autoCompletionTime;
    }

    IERC1155 public tokenContract;
    IERC20 public paymentToken;
    mapping(uint256 => ShippingTicket) public shippingTicket;

    event Redeemed(uint256 indexed itemId, address indexed user, bytes encryptedData);
    event Shipped(uint256 indexed itemId);
    event AddressChanged(uint256 indexed itemId, address indexed user, bytes newEncryptedAddress);
    event Message(uint256 indexed itemId, address indexed sender, bytes encryptedMessage);
    event Rated(uint256 indexed itemId, address indexed rater, uint8 rating, bytes encryptedMessage);
    event Tracking(uint256 indexed itemId, bytes encryptedTrackingNumber);
    event Cancelled(uint256[] indexed itemId);
    event Returned(uint256 indexed itemId, bytes indexed encryptedData);
    event Completed(uint256 indexed itemId);

    constructor(address _tokenContract, address _paymentToken) {
        tokenContract = IERC1155(_tokenContract);
        paymentToken = IERC20(_paymentToken);
    }

    //onlyOwner
    function shippingMint(
        uint256[] memory ticketIds,
        uint32[] memory maxRedeemTime,
        uint32[] memory maxFreeHoldTime,
        uint256[] memory linearRate,
        uint32[] memory autoCompletionTime
    ) external {
        require(
            ticketIds.length == maxRedeemTime.length && maxRedeemTime.length == maxFreeHoldTime.length && maxFreeHoldTime.length == linearRate.length,
            "MM: Ticket IDs and shipping details must be same length."
        );
        for (uint256 i; i < ticketIds.length; i++) {
            require(uint32(block.timestamp) <= maxFreeHoldTime[i] && maxFreeHoldTime[i] <= maxRedeemTime[i], "Inconsistent Time Contraints.");
            shippingTicket[ticketIds[i]] = ShippingTicket(
                _msgSender(),
                maxRedeemTime[i],
                maxFreeHoldTime[i],
                false,
                false,
                false,
                false,
                linearRate[i],
                uint32(block.timestamp),
                false,
                false,
                autoCompletionTime[i]
            );
        }
    }

    function holdingRateCost(uint256 ticketId) external view returns (uint256 holdingCost_) {
        uint32 _redeemedTime = shippingTicket[ticketId].redeemedTime;
        uint32 _maxFreeHoldTime = shippingTicket[ticketId].maxFreeHoldTime;
        uint32 _maxRedeemTime = shippingTicket[ticketId].maxRedeemTime;
        uint256 _linearRate = shippingTicket[ticketId].linearRate;
        require(_redeemedTime + _maxRedeemTime < block.timestamp, "Ticket has surpassed the maxRedeemTime");
        require(_redeemedTime != 0, "Ticket must have been redeemed");
        // Redeemed and Less than maxRedeemTime
        if (uint32(block.timestamp) - _redeemedTime < _maxFreeHoldTime) {
            holdingCost_ = 0;
        } else {
            holdingCost_ = (uint32(block.timestamp) - (_redeemedTime + _maxFreeHoldTime)) * _linearRate;
        }
    }

    //onlyOwner
    function shippingCancel(uint256[] memory ticketIds) external {
        for (uint256 i; i < ticketIds.length; i++) {
            delete shippingTicket[ticketIds[i]];
        }
        emit Cancelled(ticketIds);
    }

    //buyer must complete shipping
    function shippingComplete(uint256 ticketId) external {
        delete shippingTicket[ticketId];
        emit Completed(ticketId);
        //change status to complete
    }

    //user only
    function shippingReturn(uint256 itemId, bytes memory encryptedData) external {
        require(shippingTicket[itemId].userAddress == _msgSender(), "Must own the ticket");
        emit Returned(itemId, encryptedData);
    }

    function redeem(uint256 itemId, bytes memory encryptedData) public {
        ShippingTicket memory details = shippingTicket[itemId];

        require(block.timestamp <= details.maxRedeemTime, "Redemption period has ended");
        require(!details.shipped, "Item already shipped");

        uint256 elapsed = block.timestamp.sub(details.redeemedTime);
        uint256 charges;

        if (elapsed > details.maxFreeHoldTime) {
            charges = elapsed.sub(details.maxFreeHoldTime).mul(details.linearRate);
            require(paymentToken.transferFrom(msg.sender, owner(), charges), "Failed to transfer payment");
        }

        tokenContract.safeTransferFrom(msg.sender, address(this), itemId, 1, "");
        shippingTicket[itemId].redeemed = true;
        emit Redeemed(itemId, msg.sender, encryptedData);
    }

    function shipped(uint256 itemId) public onlyOwner {
        require(!shippingTicket[itemId].shipped, "Item already shipped");
        shippingTicket[itemId].shipped = true;

        emit Shipped(itemId);
    }

    function trackingInformation(uint256 itemId, bytes memory encryptedTrackingNumber) public onlyOwner {
        require(shippingTicket[itemId].shipped, "Item hasn't shipped yet.");

        emit Tracking(itemId, encryptedTrackingNumber);
    }

    function changeAddress(uint256 itemId, bytes memory newEncryptedAddress) public {
        require(!shippingTicket[itemId].shipped, "Item already shipped");
        require(msg.sender == shippingTicket[itemId].userAddress, "Not the owner of the item");

        emit AddressChanged(itemId, msg.sender, newEncryptedAddress);
    }

    function message(uint256 itemId, bytes memory encryptedMessage) public {
        emit Message(itemId, msg.sender, encryptedMessage);
    }

    function shippedRating(uint256 itemId, uint8 rating, bytes memory encryptedRatingMessage) public {
        require(rating >= 0 && rating <= 50, "Rating must be between 0 and 50");
        if (_msgSender() == owner()) {
            require(!shippingTicket[itemId].sellRated, "Seller has already rated");
            shippingTicket[itemId].sellRated = true;
        } else {
            require(!shippingTicket[itemId].buyerRated, "User has already rated");
            shippingTicket[itemId].buyerRated = true;
        }
        emit Rated(itemId, msg.sender, rating, encryptedRatingMessage);
    }
}

/**
 * Items can be sold during sales
 * Items can be created and sent by owner
 *
 * When creating an item, must be shippable or non-shippable
 * Items can then be entered into events and or sales
 *
 * Designate an id range to Shipping ids
 * Must use shipping transfer wrapper
 * Need wrapper because we need extra information associated with ticket
 * Seperate ticket for each or same ticket id?
 * Seems like seperate ID with batch minting is a good way to go about it
 *
 *
 * Must comply with the standard.
 * This implies metadata associated with tickets must be handled
 * Or can allow transfers to work as is and let users change attributes
 * (i.e. shipping information)
 * Let transfer conditionals handle require statements, and other
 * For shipping need to mark an id as being redeemed or not, which in turn
 * would block transfer.
 * Would need meta data to handle shipping redeemed bool.
 * Allow meta data to be changed by owner instead of handled before transfer
 * Transfers of tickets should only depend on requires of metadata
 * Rest of metadata surrounding an id handled by the respective facet
 * for that ticket type
 * Currently just a shipping type and general type.
 * Ticket types should have their own mint/burn
 * internal mint/burn checks to see if called by proper method.
 */

/**
 * contract ShippingFacet{
 * //functionality should be new ticketId
 *  function shippingMint(ticketId[], 1 , ShippingDetails[]) external {
 *      require checks for Shipping details
 *      uint128(hash(details)) or create ids off-chain // hash between range
 *      store for each 
 *      emit mint event 
 * }
 * 
 * //this function should be triggered when owner distributes shippingTickets
 * function shippingTicketSale(){
 *      
 * }
 * }
 * 
 * 
 * 
Seller sells to user. 
Once sold, countdown starts to track free hold time. 
view function calculate current hold rate 
view function calculate amount of time before expunged
user redeem ticket with shipping info
seller can cancel
user can change shipping address until seller ships
create max completion time function
once shipped create max completion time
seller can rate once shipped
user can rate once shipped. once user rates, marks as complete


 */
