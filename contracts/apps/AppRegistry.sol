// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IBytecodeDeployer.sol"; // Import the interface defined above

/**
 * @title MiniAppRegistry
 * @author Gemini
 * @notice A registry for discovering and deploying predefined "mini-app" contracts.
 * @dev Manages metadata for different mini-app types and triggers deployments via
 * associated BytecodeDeployer contracts using CREATE2.
 */
contract MiniAppRegistry {
    // ======== State Variables ========

    address public owner;
    bool public isOwnerNeeded; // If true, only owner can upload apps. If false, anyone can.

    struct AppInfo {
        string name; // User-facing name (unique constraint enforced by mapping key)
        string description;
        string imageUri;
        address bytecodeDeployer; // Address of the specific deployer for this app type
        bool exists; // Flag to check if an app entry exists for a given name hash
        bool isActive;
    }

    // Mapping from keccak256 hash of the app name to its info
    // Using hash avoids potential issues with string key length/gas and ensures uniqueness check is robust
    mapping(bytes32 => AppInfo) public appInfoMap;

    // Optional: Keep track of app names for enumeration (can be gas-intensive)
    // bytes32[] public appNameHashes;

    // ======== Events ========

    event AppUploaded(
        bytes32 indexed nameHash,
        string name,
        address bytecodeDeployer,
        address uploader
    );
    event AppInstanceDeployed(
        bytes32 indexed nameHash,
        address indexed deployerContract, // The BytecodeDeployer used
        address indexed instanceAddress,  // The newly deployed mini-app instance
        bytes32 salt,
        address initiator // Who called deployApp
    );
    event OwnerNeededSet(bool required);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AppDeactivated(string _appName);   
    // ======== Errors =======
    error DeactivatingNonExistantApp(); 
    // ======== Modifiers ========

    modifier onlyOwner() {
        require(msg.sender == owner, "Registry: Caller is not the owner");
        _;
    }

    // ======== Constructor ========

    constructor(bool _startWithOwnerRestriction) {
        owner = msg.sender;
        isOwnerNeeded = _startWithOwnerRestriction;
        emit OwnershipTransferred(address(0), msg.sender);
        emit OwnerNeededSet(_startWithOwnerRestriction);
    }

    // ======== Owner Functions ========

    /**
     * @notice Sets whether the owner restriction for uploading apps is active.
     * @param _needed True to restrict uploads to owner, false to allow anyone.
     */
    function setOwnerNeeded(bool _needed) external onlyOwner {
        isOwnerNeeded = _needed;
        emit OwnerNeededSet(_needed);
    }

    /**
     * @notice Transfers ownership of the registry contract.
     * @param _newOwner The address of the new owner.
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Registry: New owner cannot be the zero address");
        address oldOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }

    // ======== Core Functions ========

    /**
     * @notice Registers a new type of mini-app in the registry.
     * @dev The app name must be unique. Checks owner restriction if isOwnerNeeded is true.
     * @param _name The unique name of the app type.
     * @param _description A description for the app type.
     * @param _imageUri A URI pointing to an image/icon for the app type.
     * @param _bytecodeDeployer The address of the pre-deployed BytecodeDeployer contract
     * responsible for deploying this specific app type.
     */
    function uploadApp(
        string calldata _name,
        string calldata _description,
        string calldata _imageUri,
        address _bytecodeDeployer // Must implement IBytecodeDeployer
    ) external {
        if (isOwnerNeeded) {
            require(msg.sender == owner, "Registry: Owner restriction active");
        }

        require(_bytecodeDeployer != address(0), "Registry: Deployer cannot be zero address");
        // Check if deployer actually implements the interface (optional but recommended)
        // require(IBytecodeDeployer(_bytecodeDeployer).supportsInterface(type(IBytecodeDeployer).interfaceId), "Registry: Deployer doesn't implement IBytecodeDeployer");
        // Note: supportsInterface requires the deployer to inherit ERC165. If not, skip this check.
        // Consider a simple check like calling getAllowedBytecodeHash() to see if it reverts.
        try IBytecodeDeployer(_bytecodeDeployer).getAllowedBytecodeHash() returns (bytes32) {
            // Success, deployer seems valid
        } catch {
            revert("Registry: Invalid bytecode deployer contract");
        }


        bytes32 nameHash = keccak256(abi.encodePacked(_name));
        require(!appInfoMap[nameHash].exists, "Registry: App name already exists");

        appInfoMap[nameHash] = AppInfo({
            name: _name,
            description: _description,
            imageUri: _imageUri,
            bytecodeDeployer: _bytecodeDeployer,
            exists: true,
            isActive : true 
        });

        // Optional: Add to list for enumeration
        // appNameHashes.push(nameHash);

        emit AppUploaded(nameHash, _name, _bytecodeDeployer, msg.sender);
    }

    /**
     * @notice Deploys an instance of a registered mini-app using its associated BytecodeDeployer.
     * @param _appName The name of the app type to deploy.
     * @param _salt A user-provided salt for CREATE2 predictability. Ensure uniqueness for distinct instances.
     * @param _constructorArgs ABI-encoded constructor arguments for the mini-app instance.
     * @return instanceAddress The address of the newly deployed mini-app contract instance.
     */
    function deployApp(
        string calldata _appName,
        bytes32 _salt,
        bytes calldata _bytecode,
        bytes calldata _constructorArgs
    ) external returns (address instanceAddress) {
        bytes32 nameHash = keccak256(abi.encodePacked(_appName));
        AppInfo storage app = appInfoMap[nameHash];

        require(app.exists, "Registry: App name not found");
        require(app.bytecodeDeployer != address(0), "Registry: Invalid deployer address stored"); // Sanity check

        // Get the deployer contract interface
        IBytecodeDeployer deployer = IBytecodeDeployer(app.bytecodeDeployer);

        // Call the deploy function on the specific BytecodeDeployer contract
        // This deployer contract is responsible for bytecode verification and CREATE2 logic
        instanceAddress = deployer.deploy(_salt, _bytecode, _constructorArgs);

        require(instanceAddress != address(0), "Registry: Deployment failed"); // Deployer should revert on failure, but check address anyway

        emit AppInstanceDeployed(
            nameHash,
            app.bytecodeDeployer,
            instanceAddress,
            _salt,
            msg.sender
        );

        return instanceAddress;
    }

    // ======== View Functions ========

    /**
     * @notice Retrieves the metadata for a registered app type by its name.
     * @param _appName The name of the app type.
     * @return name The app's name.
     * @return description The app's description.
     * @return imageUri The app's image URI.
     * @return bytecodeDeployer The address of the app's deployer contract.
     * @return isActive app is live and hasn't been deactivated.
     */
    function retrieveApp(string calldata _appName)
        external
        view
        returns (
            string memory name,
            string memory description,
            string memory imageUri,
            address bytecodeDeployer,
            bool isActive
        )
    {
        bytes32 nameHash = keccak256(abi.encodePacked(_appName));
        AppInfo storage app = appInfoMap[nameHash];
        require(app.exists, "Registry: App name not found");

        return (
            app.name,
            app.description,
            app.imageUri,
            app.bytecodeDeployer,
            app.isActive
        );
    }

     /**
     * @notice Retrieves the metadata for a registered app type by its name hash.
     * @param _nameHash The keccak256 hash of the app type's name.
     * @return name The app's name.
     * @return description The app's description.
     * @return imageUri The app's image URI.
     * @return bytecodeDeployer The address of the app's deployer contract.
     * @return exists Whether an app with this hash exists.
     * @return isActive app is live and hasn't been deactivated.

     */
    function retrieveAppByHash(bytes32 _nameHash)
        external
        view
        returns (
            string memory name,
            string memory description,
            string memory imageUri,
            address bytecodeDeployer,
            bool exists,
            bool isActive
        )
    {
        AppInfo storage app = appInfoMap[_nameHash];
        // No require here, allow checking for non-existent apps
        return (
            app.name,
            app.description,
            app.imageUri,
            app.bytecodeDeployer,
            app.exists,
            app.isActive
        );
    }

    /**
     * @notice Predicts the deployment address for a mini-app instance using CREATE2.
     * @dev Calls the predictAddress function on the associated BytecodeDeployer.
     * @param _appName The name of the app type.
     * @param _salt The salt intended for deployment.
     * @param _constructorArgs ABI-encoded constructor arguments intended for deployment.
     * @return predictedAddress The pre-calculated deployment address.
     */
    function predictAppInstanceAddress(
        string calldata _appName,
        bytes32 _salt,
        bytes calldata _bytecode,
        bytes calldata _constructorArgs
    ) external view returns (address predictedAddress) {
        bytes32 nameHash = keccak256(abi.encodePacked(_appName));
        AppInfo storage app = appInfoMap[nameHash];

        require(app.exists, "Registry: App name not found");
        require(app.bytecodeDeployer != address(0), "Registry: Invalid deployer address stored");

        IBytecodeDeployer deployer = IBytecodeDeployer(app.bytecodeDeployer);

        return deployer.predictAddress(_salt, _bytecode, _constructorArgs);
    }

    function removeApp(
        string calldata _appName 
    ) external onlyOwner {
        bytes32 nameHash = keccak256(abi.encodePacked(_appName));
        AppInfo storage app = appInfoMap[nameHash];
        if(! app.exists ){
            revert DeactivatingNonExistantApp();
        }
        app.isActive = false;
        emit AppDeactivated(_appName);        
    }

    // Optional: Function to get the number of registered apps (if using appNameHashes)
    // function getAppCount() external view returns (uint256) {
    //     return appNameHashes.length;
    // }

    // Optional: Function to get app hash by index (if using appNameHashes)
    // function getAppHashByIndex(uint256 index) external view returns (bytes32) {
    //     require(index < appNameHashes.length, "Registry: Index out of bounds");
    //     return appNameHashes[index];
    // }

}