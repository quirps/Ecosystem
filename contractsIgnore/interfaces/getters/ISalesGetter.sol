// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../libraries/LibSales.sol";

/**
 * @title SalesGetterInterface
 * @dev Interface for the SalesGetter contract.
 */
interface ISalesGetter {

    /**
     * @notice Fetches the sale stats for a given sale ID and buyer.
     * @param saleId The ID of the sale.
     * @param buyer The address of the buyer.
     * @return The sale stats associated with the given sale ID and buyer.
     */
    function getSaleStats(uint256 saleId, address buyer) external view returns (uint256);

    /**
     * @notice Fetches the sale details for a given sale ID.
     * @param saleId The ID of the sale.
     * @return The sale details associated with the given sale ID.
     */
    function getSale(uint256 saleId) external view returns (LibSales.Sale memory);
}
