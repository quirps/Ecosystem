// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibSales.sol";

contract iSales is iERC1155Transfer {
    event SaleCreated(uint256 saleId);
    event ItemPurchased(uint256 saleId, address buyer, uint256 numBundles);

    function _createSale(uint256 saleId, LibSales.Sale memory saleData, uint256 predecessorSaleId) internal {
        LibSales.SalesStorage storage sstore = LibSales.salesStorage();
        
        require(saleData.itemIds.length == saleData.itemAmounts.length, "Mismatched item data");
        require(saleData.endTime > saleData.startTime, "Invalid time range");

        saleData.predecessorSaleId = predecessorSaleId; 
        sstore.sales[saleId] = saleData;

        emit SaleCreated(saleId);
    }

    function _retrieveSaleAndPredecessors(uint256 saleId) internal view returns (LibSales.Sale[] memory) {
        LibSales.SalesStorage storage sstore = LibSales.salesStorage();
        
        require(sstore.sales[saleId].endTime > 0, "Nonexistent sale");

        uint256 maxPredecessors = 100;
        LibSales.Sale[] memory salesList = new LibSales.Sale[](maxPredecessors);
        uint256 count = 0;

        while (saleId != 0 && count < maxPredecessors) {
            salesList[count] = sstore.sales[saleId];
            saleId = sstore.sales[saleId].predecessorSaleId;
            count++;
        }

        // Resize array to match the actual count
        LibSales.Sale[] memory trimmedSalesList = new LibSales.Sale[](count);
        for (uint256 i = 0; i < count; i++) {
            trimmedSalesList[i] = salesList[i];
        }

        return trimmedSalesList;
    }

    function _validatePurchase(uint256 saleId, uint256 numBundles) internal view {
        LibSales.SalesStorage storage sstore = LibSales.salesStorage();
        
        LibSales.Sale memory sale = sstore.sales[saleId];

        require(block.timestamp >= sale.startTime && block.timestamp <= sale.endTime, "Sale not active");
        require(sstore.memberRank[msg.sender] >= sale.rankRequired, "Insufficient rank");
        require(sstore.saleStats[saleId][msg.sender] + numBundles <= sale.limit, "Purchase limit exceeded");

        if (sale.predecessorSaleId != 0) {
            require(sstore.saleStats[sale.predecessorSaleId][msg.sender] > 0, "Must purchase from predecessor sale first");
        }
    }
}
