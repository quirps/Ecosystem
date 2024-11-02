pragma solidity ^0.8.0;

import {LibSales} from "./LibSales.sol"; 
import {iSales} from "./_Sales.sol"; 

contract Sales is iSales {
    
    function createSale(uint256 saleId, LibSales.Sale memory saleData, uint256 predecessorSaleId) external{
        _createSale(saleId, saleData, predecessorSaleId);
    }
    function retrieveSaleAndPredecessors(uint256 saleId) external view returns (LibSales.Sale[] memory){
        return _retrieveSaleAndPredecessors(saleId);
    }
    function validatePurchase(uint256 saleId, uint256 numBundles) external view{
        _validatePurchase(saleId, numBundles);
    }
    
}   