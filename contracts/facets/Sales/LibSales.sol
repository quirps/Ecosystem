// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibSales {
    bytes32 constant STORAGE_SALES = keccak256("diamond.storage.sales");

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
        bool isEther;
    }

    struct SalesStorage {
        uint256 salesCounter;
        mapping(address => uint256) memberRank;
        mapping(uint256 => Sale) sales;
        mapping(uint256 => mapping(address => uint256)) saleStats;
    }

    function salesStorage() internal pure returns (SalesStorage storage ss) {
        bytes32 salesKey = STORAGE_SALES;
        assembly {
            ss.slot := salesKey
        }
    }

    function setSale(uint256 saleId, Sale memory saleData) internal {
        SalesStorage storage ss = salesStorage();
        ss.sales[saleId] = saleData;
    }

    function getSale(uint256 saleId) internal view returns (Sale memory) {
        SalesStorage storage ss = salesStorage();
        return ss.sales[saleId];
    }

    function setSaleStats(uint256 saleId, address buyer, uint256 numBundles) internal {
        SalesStorage storage ss = salesStorage();
        ss.saleStats[saleId][buyer] += numBundles;
    }

    function getSaleStats(uint256 saleId, address buyer) internal view returns (uint256) {
        SalesStorage storage ss = salesStorage();
        return ss.saleStats[saleId][buyer];
    }
}