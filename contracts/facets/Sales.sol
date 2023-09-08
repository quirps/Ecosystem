// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Sales is Ownable {
    struct Sale {
        uint32 startTime;
        uint32 endTime;
        uint256 rankRequired;
        uint256 limit;
        uint256 predecessorSaleId;
        uint256[] itemIds;
        uint256[] itemAmounts;
        IERC20 paymentToken;
    }

struct SaleInput {
    uint32 startTime;
    uint32 endTime;
    uint256 rankRequired;
    uint256 limit;
    uint256[] itemIds;
    uint256[] itemAmounts;
    address paymentTokenAddress;
}
    uint256 public salesCounter; // New counter to keep track of sale IDs

    // memberRank[address] => rank
    mapping(address => uint256) public memberRank;
    // sales[saleId] => Sale
    mapping(uint256 => Sale) public sales;
    // saleStats[saleId][address] => amount bought by user
    mapping(uint256 => mapping(address => uint256)) public saleStats;
    // item contract
    IERC1155 public itemContract;

    event SaleCreated(uint256 saleId);
    event ItemPurchased(uint256 saleId, address buyer, uint256 amount);

    constructor(address _itemContract) {
        itemContract = IERC1155(_itemContract);
    }

 
function createTieredSales( SaleInput[] calldata salesInputs) external onlyOwner {
    uint256 inputLength = salesInputs.length;
    uint256 localCounter = salesCounter;

    for (uint256 i = 0; i < inputLength; i++) {
        uint256 currentSaleId = localCounter + 1;

        createSale(
            currentSaleId,
            salesInputs[i],
            i == 0 ? 0 : localCounter  // Set predecessorSaleId to 0 for the first sale
        );


        localCounter = currentSaleId;
    }

    salesCounter = localCounter; // Update the salesCounter in storage at the end of the function
}

function createSale(
    uint256 saleId,
    SaleInput calldata saleInput,
    uint256 predecessorSaleId
) internal {
    require(saleInput.itemIds.length == saleInput.itemAmounts.length, "Item IDs and amounts must have the same length");
    require(saleInput.endTime > saleInput.startTime, "End time must be greater than start time");

    sales[saleId] = Sale({
        startTime: saleInput.startTime,
        endTime: saleInput.endTime,
        rankRequired: saleInput.rankRequired,
        limit: saleInput.limit,
        predecessorSaleId: predecessorSaleId,
        itemIds: saleInput.itemIds,
        itemAmounts: saleInput.itemAmounts,
        paymentToken: IERC20(saleInput.paymentTokenAddress)
    });

    emit SaleCreated(saleId);
}

    function viewSale(uint256 saleId) external view returns (Sale[] memory sales_) {
    require(sales[saleId].endTime > 0 ,"Sale must have existed.");

    uint256 maxPredecessors = 100; // to prevent infinite loops, you can adjust this value
    Sale[] memory salesList = new Sale[](maxPredecessors);
    uint256 count = 0;
    Sale memory currentSale = sales[saleId];

    while(currentSale.predecessorSaleId != 0 && count < maxPredecessors) {
        salesList[count] = currentSale;
        count++;
        currentSale = sales[currentSale.predecessorSaleId];
    }
    
    // Add the last sale which has predecessorSaleId = 0
    salesList[count] = currentSale;
    
    // Now we resize the array to remove the unused slots
    Sale[] memory trimmedSalesList = new Sale[](count + 1);
    for(uint256 i = 0; i <= count; i++) {
        trimmedSalesList[i] = salesList[i];
    }

    return trimmedSalesList;
}


    function buyItems(uint256 saleId, uint256 amount) external {
        Sale storage sale = sales[saleId];

        require(block.timestamp >= sale.startTime && block.timestamp <= sale.endTime, "Sale not active");
        require(memberRank[msg.sender] >= sale.rankRequired, "Insufficient rank");
        require(saleStats[saleId][msg.sender] + amount <= sale.limit, "Exceeds limit");

        if (sale.predecessorSaleId != 0) {
            require(saleStats[sale.predecessorSaleId][msg.sender] > 0, "Predecessor sale not bought");
        }

        // Assume equal cost of 1 ERC20 token per unit amount
        uint256 totalPrice = amount;

        require(sale.paymentToken.transferFrom(msg.sender, owner(), totalPrice), "Payment failed");

        for (uint i = 0; i < sale.itemIds.length; i++) {
            uint256 itemId = sale.itemIds[i];
            uint256 itemAmount = sale.itemAmounts[i] * amount;
            itemContract.safeTransferFrom(owner(), msg.sender, itemId, itemAmount, "");
        }

        saleStats[saleId][msg.sender] += amount;

        emit ItemPurchased(saleId, msg.sender, amount);
    }
}
