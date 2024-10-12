pragma solidity ^0.8.0;

import "../../libraries/LibSales.sol";

contract SalesGetter{
    function getSaleStats(uint256 saleId, address buyer) external view returns (uint256) {
        return LibSales.getSaleStats(saleId, buyer);
    }
    function getSale(uint256 saleId) external view returns (LibSales.Sale memory) {
        return LibSales.getSale(saleId);
    }
}