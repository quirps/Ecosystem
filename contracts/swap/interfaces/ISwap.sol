pragma solidity ^0.8.9;

import "../Swap.sol";

interface IMassDXSwap {
    function swap(MassDXSwap.Swap memory inputSwap, MassDXSwap.Swap memory outputSwap, uint256[] memory targetOrders, uint256 _stakeId, bool isOrder) payable external;
}