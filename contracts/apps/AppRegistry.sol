// contracts/core/AppRegistry.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {IEventFacet} from "../facets/Events/IEventFacet.sol";

// Interface for ecosystem owner check
interface IEcosystemOwner {
    function owner() external view returns (address);
}

contract AppRegistry is Ownable {
    enum AppStatus {
        Pending,
        Active,
        Deprecated,
        Archived
    }

    // App Information - Now stores only base bytecode hash
    struct AppInfo {
        bytes32 baseBytecodeHash; // Hash of the app's base bytecode (without constructor args)
        string name;
        string description;
        string developerName;
        string logoURI;
        string sourceCodeURI;
        string[] tags;
        AppStatus status;
        uint256 registrationTimestamp;
    }

    // --- State ---
    bool public registrationIsRestricted;
    mapping(bytes32 => AppInfo) private s_appInfo;
    bytes32[] private s_registeredEventTypes;
    mapping(bytes32 => uint256) private s_eventTypeIndex;

    // --- Events ---
    event AppTypeRegistered(
        bytes32 indexed eventType,
        address indexed registrant,
        uint256 arrayIndex,
        AppInfo appInfo
    );
    event AppTypeMetadataUpdated(bytes32 indexed eventType, string name);
    event AppTypeStatusChanged(bytes32 indexed eventType, AppStatus newStatus);
    event RegistrationRestriction(bool isRestricted);
    event AppInstanceInstalledForEcosystem(
        bytes32 indexed eventType,
        address indexed ecosystemAddress,
        address indexed instanceAddress
    );
    // Updated event for bytecode hash comparison during installation
    event BytecodeHashComparison(
        bytes32 indexed eventType,
        address indexed ecosystemAddress,
        bytes32 providedBaseBytecodeHash, // Hash of the base bytecode provided to installAppForEcosystem
        bytes32 storedBaseBytecodeHash    // Hash of the base bytecode stored in AppInfo
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
     * @dev Takes raw base bytecode and hashes it on-chain.
     * @param eventType A unique identifier for this app type.
     * @param _baseBytecode The raw base bytecode of the app (contract code without constructor args).
     * @param infoMetadata The metadata for the app.
     */
    function registerAppType(
        bytes32 eventType,
        bytes calldata _baseBytecode, // Now takes base bytecode
        AppInfo calldata infoMetadata
    ) public onlyOwnerIfRestricted {
        require(eventType != bytes32(0), "AppRegistry: Zero eventType");
        require(s_eventTypeIndex[eventType] == 0, "AppRegistry: EventType already registered");
        require(_baseBytecode.length > 0, "AppRegistry: Empty base bytecode");
        require(bytes(infoMetadata.name).length > 0, "AppRegistry: Name required");

        // Hash base bytecode on-chain
        bytes32 baseBytecodeHash_ = keccak256(_baseBytecode);

        require(baseBytecodeHash_ != bytes32(0), "AppRegistry: Zero base bytecode hash after hashing");

        AppInfo memory newAppInfo = infoMetadata;
        newAppInfo.baseBytecodeHash = baseBytecodeHash_; // Store hashed value
        newAppInfo.status = AppStatus.Active;
        newAppInfo.registrationTimestamp = block.timestamp;

        uint256 eventTypeIndex = s_registeredEventTypes.length;
        s_appInfo[eventType] = newAppInfo;
        s_registeredEventTypes.push(eventType);
        s_eventTypeIndex[eventType] = eventTypeIndex + 1;

        emit AppTypeRegistered(eventType, _msgSender(), eventTypeIndex, newAppInfo);
    }

    /**
     * @notice Updates the status of an existing app type.
     */
    function setAppTypeStatus(bytes32 eventType, AppStatus newStatus) public onlyOwnerIfRestricted {
        require(s_eventTypeIndex[eventType] != 0, "AppRegistry: AppType not registered");
        s_appInfo[eventType].status = newStatus;
        emit AppTypeStatusChanged(eventType, newStatus);
    }

    function isAppExist(bytes32 eventType) external view returns (bool) {
        return s_eventTypeIndex[eventType] != 0;
    }

    // --- Installation (Called by Ecosystem Owner) ---

    /**
     * @notice Installs an app instance for a specific ecosystem using CREATE2 directly.
     * @dev MUST be called by the owner of the target ecosystemAddress.
     * @dev Deploys using CREATE2 directly, then calls back to the ecosystem's registerApp function.
     * @param ecosystemAddress The address of the target ecosystem contract.
     * @param _baseBytecode The raw base bytecode of the app (contract code without constructor args).
     * @param _constructorArgs The ABI-encoded constructor arguments for the app.
     * @param eventType The type identifier of the app to install.
     */
    function installAppForEcosystem(
        address ecosystemAddress,
        bytes calldata _baseBytecode,      // Base bytecode
        bytes calldata _constructorArgs,   // ABI-encoded constructor arguments
        bytes32 eventType
    ) external payable {
        // --- Pre-checks ---
        require(ecosystemAddress != address(0), "AppRegistry: Zero ecosystem address");
        require(s_eventTypeIndex[eventType] != 0, "AppRegistry: AppType not registered");

        AppInfo storage info = s_appInfo[eventType];
        require(info.status == AppStatus.Active, "AppRegistry: AppType not active");

        // Verify that the provided base bytecode matches the registered hash (hashed on-chain)
        bytes32 providedBaseBytecodeHash = keccak256(_baseBytecode);
        bytes32 storedBaseBytecodeHash = info.baseBytecodeHash;

        // Emit event to log both hashes for debugging purposes
        emit BytecodeHashComparison(eventType, ecosystemAddress, providedBaseBytecodeHash, storedBaseBytecodeHash);

        require(providedBaseBytecodeHash == storedBaseBytecodeHash, "AppRegistry: Provided base bytecode hash mismatch");


        // --- Authorization Check ---
        address ecosystemOwner;
        try IEcosystemOwner(ecosystemAddress).owner() returns (address owner) {
            ecosystemOwner = owner;
        } catch {
            revert("AppRegistry: Failed to get ecosystem owner or contract does not have owner()");
        }
        require(_msgSender() == ecosystemOwner, "AppRegistry: Caller is not ecosystem owner");

        // Combine base bytecode and constructor arguments for final creation bytecode
        bytes memory finalCreationBytecode = abi.encodePacked(_baseBytecode, _constructorArgs);

        bytes32 salt = getSalt(ecosystemAddress, eventType); // Salt specific to ecosystem/appType

        // Compute the expected address using the hash of the *final* creation bytecode
        bytes32 finalCreationBytecodeHash = keccak256(finalCreationBytecode);
        address expectedInstanceAddress = Create2.computeAddress(salt, finalCreationBytecodeHash, address(this));

        // Ensure contract does not already exist at the predicted address
        require(!isContract(expectedInstanceAddress), "AppRegistry: Contract already exists at predicted address");

        address newInstanceAddress;

        // Deploy with CREATE2 using assembly for direct control
        assembly {
            let size := mload(finalCreationBytecode) // Length of the finalCreationBytecode
            let offset := add(finalCreationBytecode, 32) // Offset to the actual bytecode content

            newInstanceAddress := create2(callvalue(), offset, size, salt)

            if iszero(newInstanceAddress) {
                revert(0, 0) // Revert if deployment failed
            }
        }

        // --- Post-Deployment Callback to Ecosystem ---
        try IEventFacet(ecosystemAddress).registerApp(newInstanceAddress, true) {} catch {
            revert("AppRegistry: Failed to register App in Ecosystem");
        }
        emit AppInstanceInstalledForEcosystem(
            eventType,
            ecosystemAddress,
            newInstanceAddress
        );
    }

    // --- Retrieval Functions ---
    function getAppInfo(bytes32 eventType) public view returns (AppInfo memory info) {
        require(s_eventTypeIndex[eventType] != 0, "AppRegistry: AppType not registered");
        info = s_appInfo[eventType];
    }

    function getAppTypesCount() public view returns (uint256) {
        return s_registeredEventTypes.length;
    }

    function getPaginatedAppTypes(uint256 cursor, uint256 size) public view returns (bytes32[] memory eventTypes, uint256 nextCursor) {
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
     * @dev Requires _baseBytecode and _constructorArgs to compute the full creation bytecode hash for prediction.
     */
    function predictDeploymentAddress(
        address ecosystemAddress,
        bytes calldata _baseBytecode,      // Base bytecode
        bytes calldata _constructorArgs,   // ABI-encoded constructor arguments
        bytes32 eventType
    ) public view returns (address predictedAddress) {
        require(ecosystemAddress != address(0), "AppRegistry: Zero ecosystem address");
        require(s_eventTypeIndex[eventType] != 0, "AppRegistry: AppType not registered");
        require(_baseBytecode.length > 0, "AppRegistry: Empty base bytecode for prediction");

        // Verify that the provided base bytecode matches the registered hash
        AppInfo storage info = s_appInfo[eventType];
        require(keccak256(_baseBytecode) == info.baseBytecodeHash, "AppRegistry: Provided base bytecode hash mismatch for prediction");

        bytes32 salt = getSalt(ecosystemAddress, eventType);

        // Compute the hash of the *full* creation bytecode for CREATE2 prediction
        bytes memory fullCreationBytecode = abi.encodePacked(_baseBytecode, _constructorArgs);
        bytes32 fullCreationBytecodeHash = keccak256(fullCreationBytecode);

        predictedAddress = Create2.computeAddress(salt, fullCreationBytecodeHash, address(this));
    }

    function getSalt(address ecosystemAddress, bytes32 eventType) private pure returns (bytes32 salt_) {
        salt_ = keccak256(abi.encodePacked(ecosystemAddress, eventType));
    }

    // Helper to check if an address is a contract
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}