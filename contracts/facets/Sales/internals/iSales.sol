// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/utils/Ownable.sol";
import "../internals/ERC1155/iERC1155Transfer.sol";
import "../libraries/LibSales.sol";

contract iSales is Ownable, iERC1155Transfer {
    using LibSales for LibSales.Sale;

    event SaleCreated(uint256 saleId);
    event ItemPurchased(uint256 saleId, address buyer, uint256 numBundles);

    function _createTieredSales(LibSales.Sale[] calldata salesData) internal onlyOwner {
        LibSales.SalesStorage storage ss = LibSales.salesStorage();

        for (uint256 i = 0; i < salesData.length; i++) {
            uint256 predecessorSaleId = (i == 0) ? 0 : ss.salesCounter;
            _createSale(ss.salesCounter + 1, salesData[i], predecessorSaleId);
            ss.salesCounter++;
        }
    }

    function _viewSale(uint256 saleId) internal view returns (LibSales.Sale[] memory) {
        return _retrieveSaleAndPredecessors(saleId);
    }

    function _buyItems(uint256 saleId, uint256 numBundles) internal {
        _validatePurchase(saleId, numBundles);

        LibSales.Sale memory sale = LibSales.getSale(saleId);
        uint256 totalPrice = sale.paymentAmount * numBundles;

        _safeTransferFrom(msg.sender, owner(), sale.paymentTokenId, totalPrice, "");

        for (uint i = 0; i < sale.itemIds.length; i++) {
            uint256 itemId = sale.itemIds[i];
            uint256 itemAmount = sale.itemAmounts[i] * numBundles;
            _safeTransferFrom(owner(), msg.sender, itemId, itemAmount, "");
        }

        LibSales.setSaleStats(saleId, msg.sender, numBundles);

        emit ItemPurchased(saleId, msg.sender, numBundles);
    }

    function _createSale(uint256 saleId, LibSales.Sale memory saleData, uint256 predecessorSaleId) internal {
        require(saleData.itemIds.length == saleData.itemAmounts.length, "Mismatched item data");
        require(saleData.endTime > saleData.startTime, "Invalid time range");

        saleData.predecessorSaleId = predecessorSaleId;

        LibSales.setSale(saleId, saleData);

        emit SaleCreated(saleId);
    }

    function _retrieveSaleAndPredecessors(uint256 saleId) internal view returns (LibSales.Sale[] memory salesList) {
        LibSales.Sale memory sale = LibSales.getSale(saleId);

        require(sale.endTime > 0, "Nonexistent sale");

        uint256 maxPredecessors = 100;
        salesList = new LibSales.Sale[](maxPredecessors);
        uint256 count = 0;

        while (saleId != 0 && count < maxPredecessors) {
            salesList[count] = sale;
            saleId = sale.predecessorSaleId;
            sale = LibSales.getSale(saleId);
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
        LibSales.Sale memory sale = LibSales.getSale(saleId);
        uint256 userSaleStats = LibSales.getSaleStats(saleId, msg.sender);

        require(block.timestamp >= sale.startTime && block.timestamp <= sale.endTime, "Sale not active");
        require(LibSales.salesStorage().memberRank[msg.sender] >= sale.rankRequired, "Insufficient rank");
        require(userSaleStats + numBundles <= sale.limit, "Purchase limit exceeded");

        if (sale.predecessorSaleId != 0) {
            require(LibSales.getSaleStats(sale.predecessorSaleId, msg.sender) > 0, "Must purchase from predecessor sale first");
        }
    }

    // ... other functions
}
