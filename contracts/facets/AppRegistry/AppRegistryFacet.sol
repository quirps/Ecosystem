// contracts/facets/AppRegistryLinkFacet.sol (MODIFIED)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Inherit from iOwnership ONLY if onlyOwner modifier is needed here
import { iOwnership } from "../Ownership/_Ownership.sol"; // Adjust path if needed
// Inherit the internal app management logic
import { iAppRegistry } from "./_AppRegistry.sol"; // Adjust path 
import { LibAppStorage } from "./LibAppStorage.sol";
import {IAppRegistryLinkFacet} from "./IAppRegistryLinkFacet.sol"; 

// Inherit iAppManagementInternal for logic, iOwnership for onlyOwner 
contract AppRegistryLinkFacet is IAppRegistryLinkFacet, iAppRegistry, iOwnership { 

    // --- State for Trusted Registry --- (as defined before)
    bytes32 internal constant TRUSTED_REGISTRY_STORAGE_SLOT = keccak256("diamond.standard.app.registry.address");

    function _setTrustedRegistry(address registryAddress) internal { // Keep internal storage logic here
        bytes32 position = TRUSTED_REGISTRY_STORAGE_SLOT;
        assembly { sstore(position, registryAddress) }
    }

    function _trustedRegistry() internal view returns (address registryAddress) { // Keep internal storage logic here
        bytes32 position = TRUSTED_REGISTRY_STORAGE_SLOT;
        assembly { registryAddress := sload(position) }
    }

    // --- Modifier ---
    modifier onlyTrustedRegistry() {
        require(msg.sender == _trustedRegistry(), "AppRegistryLinkFacet: Caller not trusted registry");
        _;
    }


    // --- Functions ---

    /**
     * @notice Sets or updates the installed app instance address for a given event type.
     * @dev Only callable by the trusted AppRegistry contract. Uses internal logic.
     */
    function setInstalledAppFromRegistry(bytes32 eventType, address instanceAddress)
        external
        override
        onlyTrustedRegistry // Access Control
    {
        // Read old value ONLY to emit correct event (optional optimization: remove read)
        // address oldInstance = LibAppStorage.getAppInstance(eventType); // Read via Lib directly ok

        // Call internal function inherited from iAppManagementInternal
        _setInstalledApp(eventType, instanceAddress);

        // Emit appropriate event
        if (instanceAddress != address(0)) {
            emit AppInstalled(eventType, instanceAddress);
        } else {
            emit AppUninstalled(eventType);
        }
    }

    /**
     * @notice Sets the address of the trusted AppRegistry contract.
     * @dev Only callable by the Diamond owner. Uses modifier from iOwnership.
     */
    function setAppRegistryAddress(address registryAddress) external override onlyOwner {
        require(registryAddress != address(0), "AppRegistryLinkFacet: Zero address");
        address oldRegistry = _trustedRegistry();
        if (oldRegistry != registryAddress) {
            _setTrustedRegistry(registryAddress);
            emit AppRegistrySet(registryAddress);
        }
    }

    /**
     * @notice Returns the address of the currently trusted AppRegistry.
     */
    function getTrustedAppRegistry() external view override returns (address) {
        return _trustedRegistry();
    }

    /**
     * @notice Helper to view installed app for a type (optional public getter)
     */
    function getInstalledApp(bytes32 eventType) external view returns(address) {
        // Reads directly using LibAppStorage helper
        return LibAppStorage.getAppInstance(eventType);
    }
}