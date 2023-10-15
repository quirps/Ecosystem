// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/utils/Ownable.sol";
import "../internals/ERC1155/iERC1155Transfer.sol";
import "../libraries/LibSales.sol";

contract SalesMainFacet is Ownable, iERC1155Transfer {
    using SalesLib for SalesLib.Sale;

    event SaleCreated(uint256 saleId);
    event ItemPurchased(uint256 saleId, address buyer, uint256 numBundles);

    function createTieredSales(SalesLib.Sale[] calldata salesData) external onlyOwner {
        SalesLib.SalesStorage storage ss = SalesLib.salesStorage();

        for (uint256 i = 0; i < salesData.length; i++) {
            uint256 predecessorSaleId = (i == 0) ? 0 : ss.salesCounter;
            createSale(ss.salesCounter + 1, salesData[i], predecessorSaleId);
            ss.salesCounter++;
        }
    }

    function viewSale(uint256 saleId) external view returns (SalesLib.Sale[] memory) {
        return _retrieveSaleAndPredecessors(saleId);
    }

    function buyItems(uint256 saleId, uint256 numBundles) external {
        _validatePurchase(saleId, numBundles);

        SalesLib.Sale memory sale = SalesLib.getSale(saleId);
        uint256 totalPrice = sale.paymentAmount * numBundles;

        _safeTransferFrom(msg.sender, owner(), sale.paymentTokenId, totalPrice, "");

        for (uint i = 0; i < sale.itemIds.length; i++) {
            uint256 itemId = sale.itemIds[i];
            uint256 itemAmount = sale.itemAmounts[i] * numBundles;
            _safeTransferFrom(owner(), msg.sender, itemId, itemAmount, "");
        }

        SalesLib.setSaleStats(saleId, msg.sender, numBundles);

        emit ItemPurchased(saleId, msg.sender, numBundles);
    }

    function createSale(uint256 saleId, SalesLib.Sale memory saleData, uint256 predecessorSaleId) internal {
        require(saleData.itemIds.length == saleData.itemAmounts.length, "Mismatched item data");
        require(saleData.endTime > saleData.startTime, "Invalid time range");

        saleData.predecessorSaleId = predecessorSaleId;

        SalesLib.setSale(saleId, saleData);

        emit SaleCreated(saleId);
    }

    function _retrieveSaleAndPredecessors(uint256 saleId) internal view returns (SalesLib.Sale[] memory salesList) {
        SalesLib.Sale memory sale = SalesLib.getSale(saleId);

        require(sale.endTime > 0, "Nonexistent sale");

        uint256 maxPredecessors = 100;
        salesList = new SalesLib.Sale[](maxPredecessors);
        uint256 count = 0;

        while (saleId != 0 && count < maxPredecessors) {
            salesList[count] = sale;
            saleId = sale.predecessorSaleId;
            sale = SalesLib.getSale(saleId);
            count++;
        }

        // Resize array to match the actual count
        SalesLib.Sale[] memory trimmedSalesList = new SalesLib.Sale[](count);
        for (uint256 i = 0; i < count; i++) {
            trimmedSalesList[i] = salesList[i];
        }

        return trimmedSalesList;
    }

    function _validatePurchase(uint256 saleId, uint256 numBundles) internal view {
        SalesLib.Sale memory sale = SalesLib.getSale(saleId);
        uint256 userSaleStats = SalesLib.getSaleStats(saleId, msg.sender);

        require(block.timestamp >= sale.startTime && block.timestamp <= sale.endTime, "Sale not active");
        require(SalesLib.salesStorage().memberRank[msg.sender] >= sale.rankRequired, "Insufficient rank");
        require(userSaleStats + numBundles <= sale.limit, "Purchase limit exceeded");

        if (sale.predecessorSaleId != 0) {
            require(SalesLib.getSaleStats(sale.predecessorSaleId, msg.sender) > 0, "Must purchase from predecessor sale first");
        }
    }

    // ... other functions
}
