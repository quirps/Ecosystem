pragma solidity ^0.8.28;

import {LibAppStorage} from "./LibAppStorage.sol"; // Adjust path
contract iAppRegistry {
    // --- Events ---
    // Events related to app installation state changes are defined here
    // (but emitted by the facet that calls the internal functions)

    /**
     * @notice Internal function to set or uninstall the logic app instance for an event type.
     * @dev Writes directly to LibAppStorage. Access control must be handled by the caller.
     * Allows setting address(0) to uninstall.
     * @param eventType The event type identifier.
     * @param instanceAddress The address of the logic app instance, or address(0) to uninstall.
     */
    function _setInstalledApp(bytes32 eventType, address instanceAddress) internal {
        // Access control is responsibility of the calling function (e.g., in AppRegistryLinkFacet)
        // Allow setting address(0) for uninstallation
        LibAppStorage.setAppInstance(eventType, instanceAddress);
    }

    /**
     * @notice Internal function to retrieve the installed app instance for an event type.
     * @dev Reads directly from LibAppStorage. Reverts if no app is installed for the type.
     * @param eventType The type identifier.
     * @return instanceAddress The address of the installed instance.
     */
    function _getLogicAppInstance(bytes32 eventType) internal view returns (address instanceAddress) {
        instanceAddress = LibAppStorage.getAppInstance(eventType);
        require(instanceAddress != address(0), "iAppMgmtInternal: No app installed for event type");
    }

    /**
     * @notice Internal function to check if an app is installed for an event type.
     * @dev Reads directly from LibAppStorage.
     * @param eventType The type identifier.
     * @return True if an app instance address (non-zero) is stored.
     */
    function _isAppInstalledForType(bytes32 eventType) internal view returns (bool) {
        // Exists function for clarity, used by EventFacet's createEvent
        return LibAppStorage.isAppInstalled(eventType);
    }
}
