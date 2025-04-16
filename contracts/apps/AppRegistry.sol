// contracts/core/AppRegistry.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19; // Match factory pragma

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IAppInstanceFactory } from "./IAppInstanceFactory.sol"; // Use interface 
import { IAppRegistryLinkFacet } from "../facets/AppRegistry/IAppRegistryLinkFacet.sol"; // Use correct path
  
// Interface for ecosystem owner check
interface IEcosystemOwner {
    function owner() external view returns (address);
}

contract AppRegistry is Ownable {

    enum AppStatus { Pending, Active, Deprecated, Archived }

    // App Information - Implementation is the source of code, Factory deploys it
 struct AppInfo {
    // Core Addresses/Hashes
    address factoryAddress;        // Address of the factory for this type
    bytes32 expectedBytecodeHash;  // Hash the factory expects

    // Metadata (Passed during registration call)
    string name;                // User-friendly name (e.g., "Basic Poll v1")
    string description;         // Added
    string developerName;       // Added
    string logoURI;             // Added
    string sourceCodeURI;       // Added
    string[] tags;              // Added (Note: dynamic arrays increase gas cost)

    // Status & Timestamps (Set by the contract logic)
    AppStatus status;            // Status at time of registration
    uint256 registrationTimestamp; // Set via block.timestamp in registration function
}

    // --- State ---

    bool public registrationIsRestricted; // If true, only owner registers app types

    // *** Mappings using eventType (bytes32) as the key ***
    mapping(bytes32 => AppInfo) private s_appInfo; // eventType => Info
    bytes32[] private s_registeredEventTypes;      // Array of registered eventTypes for enumeration
    mapping(bytes32 => uint256) private s_eventTypeIndex; // eventType => array index + 1

    // --- Events ---

    // Fired when a new App Type (eventType) is registered
  event AppTypeRegistered(
    bytes32 indexed eventType,      // The unique ID for this app type
    address indexed registrant,     // Who called the registration function
    uint256 arrayIndex,           // Index within the contract's internal list (s_registeredEventTypes?)
    AppInfo appInfo               // Struct containing the detailed information
);

    // Fired when metadata of an existing app type is updated
    event AppTypeMetadataUpdated(bytes32 indexed eventType, string name);

    // Fired when status of an existing app type is changed
    event AppTypeStatusChanged(bytes32 indexed eventType, AppStatus newStatus);

    // Fired when registration restriction is toggled
    event RegistrationRestriction(bool isRestricted);

    // Fired *after* successful deployment AND callback to ecosystem
    event AppInstanceInstalledForEcosystem(
        bytes32 indexed eventType,          // The type of app installed
        address indexed ecosystemAddress,   // The target ecosystem
        address instanceAddress,        // Address of the new app instance
        address indexed creator             // The ecosystem owner who initiated the installation
    );

    // --- Modifiers ---

    modifier onlyOwnerIfRestricted() {
        if (registrationIsRestricted) {
            require(owner() == msg.sender, "AppRegistry: Caller is not the owner");
        }
        _;
    }

    // --- Constructor ---
    constructor() Ownable(msg.sender) {
        registrationIsRestricted = true;
    }

    // --- Configuration ---
    function setRegistrationRestriction(bool _restricted) public onlyOwner {
        registrationIsRestricted = _restricted;
        emit RegistrationRestriction(_restricted);
    }

    // --- App Type Registration & Management ---

    /**
     * @notice Registers a new App Type identified by a unique eventType.
     * @dev Verifies factory hash. Ensures eventType is globally unique in this registry.
     * @param eventType A unique identifier for this app type (e.g., keccak256("RAFFLE_V1")).
     * @param info The metadata including implementation source, factory, and hash.
     */
    function registerAppType(bytes32 eventType, AppInfo calldata info)
        public
        onlyOwnerIfRestricted
    {
        require(eventType != bytes32(0), "AppRegistry: Zero eventType");
        require(s_eventTypeIndex[eventType] == 0, "AppRegistry: EventType already registered"); // Global uniqueness check
        require(info.factoryAddress != address(0), "AppRegistry: Zero factory address");
        require(info.expectedBytecodeHash != bytes32(0), "AppRegistry: Zero bytecode hash");
        require(bytes(info.name).length > 0, "AppRegistry: Name required");
 
        IAppInstanceFactory factory = IAppInstanceFactory(info.factoryAddress);
        bytes32 actualFactoryExpectedHash = factory.getExpectedBytecodeHash();
        require(actualFactoryExpectedHash == info.expectedBytecodeHash, "AppRegistry: Factory expected hash mismatch");

        // --- Storage --- 
        uint256 eventTypeIndex = s_registeredEventTypes.length; 
        s_appInfo[eventType] = info;
        s_registeredEventTypes.push(eventType);
        s_eventTypeIndex[eventType] = eventTypeIndex + 1; // Store index+1

        emit AppTypeRegistered(
            eventType,
            _msgSender(),
            eventTypeIndex,
            info 
        );
    }

    /**
     * @notice Updates the status of an existing app type.
     */
    function setAppTypeStatus(bytes32 eventType, AppStatus newStatus)
        public
        onlyOwnerIfRestricted
    {
        require(s_eventTypeIndex[eventType] != 0, "AppRegistry: AppType not registered");
        s_appInfo[eventType].status = newStatus;
        emit AppTypeStatusChanged(eventType, newStatus);
    }

    // Add other management functions like updateMetadata if needed...

    // --- Installation (Called by Ecosystem Owner) ---

    /**
     * @notice Installs an app instance for a specific ecosystem.
     * @dev MUST be called by the owner of the target ecosystemAddress.
     * @dev Deploys using CREATE2 via the registered factory, then calls back
     * to the ecosystem's setInstalledAppFromRegistry function.
     * @param ecosystemAddress The address of the target ecosystem contract.
     * @param eventType The type identifier of the app to install.
     */
    function installAppForEcosystem(address ecosystemAddress, bytes calldata bytecode, bytes32 eventType)
        external
    {
        // --- Pre-checks ---
        require(ecosystemAddress != address(0), "AppRegistry: Zero ecosystem address");
        require(s_eventTypeIndex[eventType] != 0, "AppRegistry: AppType not registered");

        AppInfo storage info = s_appInfo[eventType];
        require(info.status == AppStatus.Active, "AppRegistry: AppType not active"); // Status check

        // --- Authorization Check ---
        // Requires ecosystem contract to have a public owner() view function
        address ecosystemOwner;
        try IEcosystemOwner(ecosystemAddress).owner() returns (address owner) {
            ecosystemOwner = owner;
        } catch {
            revert("AppRegistry: Failed to get ecosystem owner");
        }
        require(_msgSender() == ecosystemOwner, "AppRegistry: Caller is not ecosystem owner");

        // Optional Sanity Check: Verify hash again *if desired*, but user said not needed here.
        // require(keccak256(actualBytecode) == info.expectedBytecodeHash, "AppRegistry: Fetched bytecode hash mismatch");

        // --- Prepare for CREATE2 ---
        address factoryAddress = info.factoryAddress;
        IAppInstanceFactory factory = IAppInstanceFactory(factoryAddress);   
        bytes32 salt = keccak256(abi.encodePacked(ecosystemAddress, eventType)); // Salt specific to ecosystem/appType

        // --- Deploy Instance ---   
        address newInstanceAddress; 
        try factory.deployInstance( ecosystemAddress, bytecode, salt) returns (address deployedAddr) {
            newInstanceAddress = deployedAddr;
        } catch Error(string memory reason) {
             revert(string.concat("AppRegistry: Factory deployment failed: ", reason));
        } catch (bytes memory lowLevelData) {
             // Using lowLevelData might expose internal factory reverts, could be less user-friendly
             revert(string.concat("AppRegistry: Factory deployment failed with low-level data")); // Avoid showing raw bytes usually
             // Alternatively: revert("AppRegistry: Factory deployment failed");
        }

        // --- Post-Deployment Callback to Ecosystem ---
        // The ecosystem contract MUST trust this AppRegistry address
        try IAppRegistryLinkFacet(ecosystemAddress).setInstalledAppFromRegistry(eventType, newInstanceAddress) {
            // Callback succeeded
            emit AppInstanceInstalledForEcosystem(
                eventType,
                ecosystemAddress,
                newInstanceAddress,
                msg.sender // The ecosystem owner who initiated
            );
        } catch Error(string memory reason) {
            // CRITICAL: What happens if the callback fails?
            // The instance is deployed, but the ecosystem doesn't know about it.
            // Options:
            // 1. Revert the whole transaction (current behavior if try/catch block reverts). This is safest.
            // 2. Emit an error event and leave instance orphaned (less ideal).
            // 3. Have a recovery mechanism (complex).
            // -> Reverting is the standard approach unless specific handling is needed.
            revert(string.concat("AppRegistry: Ecosystem callback failed: ", reason));
        } catch {
             revert("AppRegistry: Ecosystem callback failed with unknown error");
        }

        // Note: No return value needed as state change is confirmed by event/callback.
    }


    // --- Internal Bytecode Fetching ---

    function _getBytecode(address _addr) internal view returns (bytes memory o_code) {
        assembly {
            let size := extcodesize(_addr)
            o_code := mload(0x40)
            mstore(o_code, size) // Length
            extcodecopy(_addr, add(o_code, 0x20), 0, size) // Copy code
            mstore(0x40, add(add(o_code, 0x20), size)) // Update free memory pointer
        }
    }

    // --- Retrieval Functions ---

    /**
     * @notice Gets metadata for a registered app type.
     */
    function getAppInfo(bytes32 eventType) public view returns (AppInfo memory info) {
        require(s_eventTypeIndex[eventType] != 0, "AppRegistry: AppType not registered");
        info = s_appInfo[eventType];
    }

    /**
      * @notice Get the number of registered app types.
      */
     function getAppTypesCount() public view returns (uint256) {
         return s_registeredEventTypes.length;
     }

     /**
      * @notice Get a paginated list of registered event types.
      */
     function getPaginatedAppTypes(uint256 cursor, uint256 size)
         public
         view
         returns (bytes32[] memory eventTypes, uint256 nextCursor)
     {
         uint256 len = s_registeredEventTypes.length;
         if (size == 0 || cursor >= len) {
             return (new bytes32[](0), len);
         }
         uint256 end = cursor + size;
         if (end > len) {
             end = len;
         }

         eventTypes = new bytes32[](end - cursor);
         for (uint256 i = cursor; i < end; i++) {
             eventTypes[i - cursor] = s_registeredEventTypes[i];
         }
         return (eventTypes, end);
     }

    /**
     * @notice Predicts deployment address for a given app type and ecosystem.
     * @dev Requires implementation code to be available for prediction via factory.
     */
    function predictDeploymentAddress(address ecosystemAddress, bytes32 eventType)
        public
        view
        returns (address predictedAddress)
    {
        
    }
}