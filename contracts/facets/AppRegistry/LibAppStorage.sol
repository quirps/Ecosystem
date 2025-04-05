// contracts/libraries/LibAppStorage.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library LibAppStorage {
    // Storage slot for the mapping: bytes32 (eventType) => address (logic contract instance)
    bytes32 internal constant APPS_STORAGE_SLOT = keccak256("diamond.standard.app.storage");

    struct AppStorage {
        mapping(bytes32 => address) installedApps;
    }

    function appStorage() internal pure returns (AppStorage storage ds) {
        bytes32 position = APPS_STORAGE_SLOT;
        assembly {
            ds.slot := position
        }
    }

    // --- Helper functions ---

    function getAppInstance(bytes32 eventType) internal view returns (address) {
        return appStorage().installedApps[eventType];
    }

    function setAppInstance(bytes32 eventType, address instanceAddress) internal {
        // Removed require(instanceAddress != address(0)) here - Allow setting 0 for uninstall
        appStorage().installedApps[eventType] = instanceAddress;
    }

    function isAppInstalled(bytes32 eventType) internal view returns (bool) {
        return appStorage().installedApps[eventType] != address(0);
    } 
}