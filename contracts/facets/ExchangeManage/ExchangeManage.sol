pragma solidity ^0.8.28;

import { LibExchangeManage } from "./LibExchangeManage.sol";
/**
 * Will remove in the future, 
 */
contract ExchangeManage{
        function addExchange( address _exchange ) external{
            LibExchangeManage._addExchange( _exchange );
        }
        function removeExchange( address _exchange ) external{
            LibExchangeManage._removeExchange( _exchange );
        }
        function viewExchanges() external view{
            LibExchangeManage._viewExchanges( ); 
        }
}