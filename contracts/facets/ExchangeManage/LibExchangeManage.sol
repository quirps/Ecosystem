pragma solidity ^0.8.28;

import { LibMembers } from "../LibMembers.sol";
/**
    user rank history keys are designed to be unique by following the program of
    using 8 bytes for the total history length ~1E19 for the highest order 8 bytes 
    and the lowest order 20 bytes for their address (28 byte total)

    Why use a key when can just use uint96 for rank history max index?
 */
library LibExchangeManage {
    bytes32 constant EXCHANGE_MANAGE_STORAGE_POSITION = keccak256("diamond.standard.exchangeManage.storage");

    struct ExchangeManageStorage {
        address[] exchanges;
    }
    function memberStorage() internal pure returns (ExchangeManageStorage storage es_) {
        bytes32 position = EXCHANGE_MANAGE_STORAGE_POSITION;
        assembly {
            es_.slot := position
        }
    }

    function _addExchange(address _exchange) internal {
        ExchangeManageStorage storage ems = memberStorage();

        ems.exchanges.push(_exchange);
    }

    function _viewExchanges() internal view returns (address[] memory) {
        ExchangeManageStorage storage ems = memberStorage();
        return ems.exchanges;
    }

    // Function to remove an address from the array
    function _removeExchange(address _address) internal {
        ExchangeManageStorage storage ems = memberStorage();
        uint256 length = ems.exchanges.length;
        for (uint256 i = 0; i < length; i++) {
            if (ems.exchanges[i] == _address) {
                // Replace the element to be removed with the last element
                if (i < length - 1) {
                    ems.exchanges[i] = ems.exchanges[length - 1];
                }
                // Remove the last element
                ems.exchanges.pop();
                return; // Exit the function after removal
            }
        }
        // If the address is not found, revert or handle accordingly
        revert("Address not found in array");
    }
}
