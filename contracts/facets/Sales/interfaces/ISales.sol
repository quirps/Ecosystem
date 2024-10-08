pragma solidity ^0.8.0;

import "../libraries/LibSales.sol";

interface ISales{
    function createSale(uint256 saleId, LibSales.Sale memory saleData, uint256 predecessorSaleId) external;
    function retrieveSaleAndPredecessors(uint256 saleId) external view returns (LibSales.Sale[] memory);
    function validatePurchase(uint256 saleId, uint256 numBundles) external view;
}
