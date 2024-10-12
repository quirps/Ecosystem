// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../libraries/utils/Ownable.sol"; 
import "../Tokens/ERC1155/internals/iERC1155Transfer.sol";

/**
 * @title Sales Contract
 * @dev A contract to handle sales of items with ERC1155 standard
 */
contract Sales is  iERC1155Transfer {
    // Structs
    struct Sale {
        uint32 startTime;
        uint32 endTime;
        uint256 rankRequired;
        uint256 limit;
        uint256 predecessorSaleId;
        uint256[] itemIds;
        uint256[] itemAmounts;
        uint256 paymentTokenId;
        uint256 paymentAmount;
    }
    // State variables
    uint256 public salesCounter;
    mapping(address => uint256) public memberRank;
    mapping(uint256 => Sale) public sales;
    mapping(uint256 => mapping(address => uint256)) public saleStats;

    // Events
    event SaleCreated(uint256 saleId);
    event ItemPurchased(uint256 saleId, address buyer, uint256 numBundles);

    // External functions
    function createTieredSales(Sale[] calldata salesData) external  {
        for (uint256 i = 0; i < salesData.length; i++) {
            uint256 predecessorSaleId = (i == 0) ? 0 : salesCounter;
            createSale(salesCounter + 1, salesData[i], predecessorSaleId);
            salesCounter++;
        }
    }

    function viewSale(uint256 saleId) external view returns (Sale[] memory) {
        return _retrieveSaleAndPredecessors(saleId);
    }

    function buyItems(uint256 saleId, uint256 numBundles) external {
        _validatePurchase(saleId, numBundles);

        Sale storage sale = sales[saleId];
        uint256 totalPrice = sale.paymentAmount * numBundles;

        _safeTransferFrom(msg.sender, owner(), sale.paymentTokenId, totalPrice, "");

        for (uint i = 0; i < sale.itemIds.length; i++) {
            uint256 itemId = sale.itemIds[i];
            uint256 itemAmount = sale.itemAmounts[i] * numBundles;
            _safeTransferFrom(owner(), msg.sender, itemId, itemAmount, "");
        }

        saleStats[saleId][msg.sender] += numBundles;
        emit ItemPurchased(saleId, msg.sender, numBundles);
    }

    // Internal functions
    function createSale(uint256 saleId, Sale memory saleData, uint256 predecessorSaleId) internal {
        require(saleData.itemIds.length == saleData.itemAmounts.length, "Mismatched item data");
        require(saleData.endTime > saleData.startTime, "Invalid time range");

        saleData.predecessorSaleId = predecessorSaleId; // Assign the predecessorSaleId

        sales[saleId] = saleData;

        emit SaleCreated(saleId);
    }

    function _retrieveSaleAndPredecessors(uint256 saleId) internal view returns (Sale[] memory salesList) {
        require(sales[saleId].endTime > 0, "Nonexistent sale");

        uint256 maxPredecessors = 100;
        salesList = new Sale[](maxPredecessors);
        uint256 count = 0;

        while (saleId != 0 && count < maxPredecessors) {
            salesList[count] = sales[saleId];
            saleId = sales[saleId].predecessorSaleId;
            count++;
        }

        // Resize array to match the actual count
        Sale[] memory trimmedSalesList = new Sale[](count);
        for (uint256 i = 0; i < count; i++) {
            trimmedSalesList[i] = salesList[i];
        }

        return trimmedSalesList;
    }

    function _validatePurchase(uint256 saleId, uint256 numBundles) internal view {
        Sale memory sale = sales[saleId];

        require(block.timestamp >= sale.startTime && block.timestamp <= sale.endTime, "Sale not active");
        require(memberRank[msg.sender] >= sale.rankRequired, "Insufficient rank");
        require(saleStats[saleId][msg.sender] + numBundles <= sale.limit, "Purchase limit exceeded");

        if (sale.predecessorSaleId != 0) {
            require(saleStats[sale.predecessorSaleId][msg.sender] > 0, "Must purchase from predecessor sale first");
        }
    }
}
