// contracts/core/AppRegistry.sol (Final Version)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IAppRegistryLinkFacet} from "../facets/AppRegistry/IAppRegistryLinkFacet.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
// No direct dependency on LibEventFactory needed here anymore
 
contract AppRegistry is Ownable {

    // Keep AppStatus enum and AppInfo struct from previous version
    enum AppStatus { Pending, Active, Deprecated, Archived }

    struct AppInfo { // Primarily for metadata about TEMPLATES/VERSIONS now
        address implementation; // Address of the base implementation/template contract
        string name;
        string description;
        string developerName;
        string sourceCodeURI;
        string logoURI;
        // Interaction type flags might still be useful metadata
        bool supportsHold;
        bool supportsBurn;
        bool supportsStake;
        string[] tags;
        AppStatus status;
        bool isOfficial;
        uint256 registrationTimestamp; // When this template/version was registered
    }

    // --- State ---

    // Metadata storage (keyed by implementation address or a unique version hash?)
    // Let's key metadata by implementation address for easier lookup of template info
    mapping(address => AppInfo) private s_appImplementationInfo;
    address[] private s_appImplementations; // For enumeration of templates
    mapping(address => uint256) private s_implementationIndex; // implementation => index + 1

    // --- Events ---
    event AppImplementationRegistered(
        address indexed implementation,
        string name,
        address registrant
    );
    event AppMetadataUpdated(address indexed implementation, string name);
    // event AppStatusChanged(address indexed implementation, AppStatus newStatus); // If tracking status of templates

    // Event for cross-ecosystem installation (emitted by Registry)
    event AppInstanceInstalledForEcosystem(
        address indexed ecosystemProxy,
        bytes32 indexed eventType,
        address indexed instanceAddress,
        address caller // Who initiated the install via registry
    );
     event AppInstanceUninstalledForEcosystem(
        address indexed ecosystemProxy,
        bytes32 indexed eventType,
        address caller
    );


    // --- Constructor ---
    constructor() Ownable(msg.sender) {}

    // --- Template/Metadata Management (Owner Controlled) ---

    /**
     * @notice Registers or updates metadata for a base app implementation/template address.
     */
    function registerAppImplementation(address implementation, AppInfo calldata info) public onlyOwner {
        require(implementation != address(0), "AppRegistry: Zero implementation");
        require(info.implementation == implementation, "AppRegistry: Implementation address mismatch"); // Ensure struct matches key
        require(bytes(info.name).length > 0, "AppRegistry: Name required");

        bool isNew = s_implementationIndex[implementation] == 0;
        s_appImplementationInfo[implementation] = info; // Store/update metadata
        s_appImplementationInfo[implementation].registrationTimestamp = block.timestamp;

        if (isNew) {
            s_appImplementations.push(implementation);
            s_implementationIndex[implementation] = s_appImplementations.length;
            emit AppImplementationRegistered(implementation, info.name, msg.sender);
        } else {
            emit AppMetadataUpdated(implementation, info.name);
        }
    }

    // Add functions to update metadata, status, official flag for TEMPLATES if needed
    // function setImplementationStatus(address implementation, AppStatus newStatus) public onlyOwner { ... }

    // --- Ecosystem App Instance Management (Owner Controlled) ---

    /**
     * @notice Installs a specific app instance address for a given event type into a target ecosystem.
     * @dev Only callable by the registry owner. Calls back to the ecosystem's trusted function.
     * @param ecosystemProxy The address of the target Ecosystem Diamond instance.
     * @param eventType The type identifier (e.g., keccak256("RAFFLE_V1")).
     * @param instanceAddress The address of the app instance deployed specifically for this ecosystem.
     */
    function installAppForEcosystem(
        address ecosystemProxy,
        bytes32 eventType,
        address instanceAddress
    ) public onlyOwner { // Access control: Registry owner manages installations
        require(ecosystemProxy != address(0), "AppRegistry: Zero ecosystem address");
        require(instanceAddress != address(0), "AppRegistry: Zero instance address");
        // Optional: Check if instanceAddress bytecode matches a registered template? (Advanced)
        // require(s_implementationIndex[getCodeHash(instanceAddress)] != 0, "AppRegistry: Instance code not registered");

        // Call the designated function on the target ecosystem
        // The ecosystem must trust THIS registry contract.
        try IAppRegistryLinkFacet(ecosystemProxy).setInstalledAppFromRegistry(eventType, instanceAddress) {
            emit AppInstanceInstalledForEcosystem(ecosystemProxy, eventType, instanceAddress, msg.sender);
        } catch Error(string memory reason) {
            revert(string.concat("AppRegistry: Callback failed: ", reason));
        } catch (bytes memory lowLevelData) {
             revert(string.concat("AppRegistry: Callback failed with low-level data: ", string(lowLevelData))); // Might not be string
            // Alternatively: revert("AppRegistry: Callback failed with low-level data");
        }
    }

     /**
     * @notice Uninstalls an app instance for a given event type from a target ecosystem.
     * @dev Calls back to the ecosystem by setting the instance address to address(0).
     * Only callable by the registry owner.
     * @param ecosystemProxy The address of the target Ecosystem Diamond instance.
     * @param eventType The type identifier (e.g., keccak256("RAFFLE_V1")).
     */
    function uninstallAppForEcosystem(address ecosystemProxy, bytes32 eventType) public onlyOwner {
         require(ecosystemProxy != address(0), "AppRegistry: Zero ecosystem address");

         // Call the designated function on the target ecosystem, setting address(0)
         // NOTE: The Diamond's setInstalledAppFromRegistry *must allow* setting address(0) for this to work.
         try IAppRegistryLinkFacet(ecosystemProxy).setInstalledAppFromRegistry(eventType, address(0)) {
             emit AppInstanceUninstalledForEcosystem(ecosystemProxy, eventType, msg.sender);
         } catch Error(string memory reason) {
             revert(string.concat("AppRegistry: Callback failed: ", reason));
         } catch {
             revert("AppRegistry: Uninstall callback failed");
         }
     }


    // --- Retrieval Functions ---

    /**
     * @notice Gets metadata for a base app implementation address.
     */
    function getAppImplementationInfo(address implementation) public view returns (AppInfo memory info) {
        require(s_implementationIndex[implementation] != 0, "AppRegistry: Implementation not registered");
        info = s_appImplementationInfo[implementation];
    }

    // Add getters for enumeration of implementations (getAppImplementationCount, getPaginatedAppImplementations etc.)
    // ...

}