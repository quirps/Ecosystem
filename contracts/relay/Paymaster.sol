pragma solidity ^0.8.9;

import { IMassDXSwap } from "../swap/interfaces/ISwap.sol";
import { MassDXSwap } from "../swap/Swap.sol";

import "hardhat/console.sol";
contract Paymaster {
    function swapRelay( address massDXSwap, MassDXSwap.Swap memory inputSwap, MassDXSwap.Swap memory outputSwap, uint256[] memory targetOrders, uint256 _stakeId, bool isOrder) payable external{
       try IMassDXSwap( massDXSwap ).swap( inputSwap, outputSwap, targetOrders, _stakeId, isOrder ){}
       catch( bytes memory error){ 
        console.log("Swap Error");
       }

    }

}