// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract AppRegistry is Ownable {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    struct AppMetadata {
        address developer;
        string name;
        bytes32 descriptionHash; // keccak256 of detailed description JSON string
        string metadataUri; // e.g., ipfs://<hash_containing_image_abi_etc>
        bool isApproved;
        uint256 version; // Simple version tracking
        // We don't store the full init_code on-chain due to gas costs.
        // The deployer (creator) will need to provide it when calling deployApp.
    }

    // Mapping from init_code_hash (fingerprint) to metadata
    mapping(bytes32 => AppMetadata) public appMetadata;

    // Sets to easily iterate approved/pending apps (optional, adds gas)
    EnumerableSet.Bytes32Set private approvedAppFingerprints;
    EnumerableSet.Bytes32Set private pendingAppFingerprints; // Apps awaiting approval

    // Keep track of deployed instances per creator (optional)
    mapping(address => mapping(bytes32 => address[])) public deployedInstances;

    event AppSubmitted(
        bytes32 indexed fingerprint,
        address indexed developer,
        string name,
        string metadataUri,
        uint256 version
    );
    event AppApproved(bytes32 indexed fingerprint);
    event AppRejected(bytes32 indexed fingerprint); // Or just remove from pending
    event AppDeployed(
        bytes32 indexed fingerprint,
        address indexed creator,
        address instanceAddress,
        bytes salt
    );

    constructor(address _initialOwner) Ownable(_initialOwner) {}

    /**
     * @notice Submit a new app or a new version of an existing app.
     * @param _name App name.
     * @param _description Description (consider hashing a structured JSON off-chain).
     * @param _metadataUri URI pointing to more metadata (icon, ABI, detailed desc).
     * @param _initCode The deployment bytecode of the app contract.
     * @param _previousVersionFingerprint The fingerprint of the previous version, if updating (bytes32(0) for new app).
     */
    function submitApp(
        string calldata _name,
        string calldata _description, // Pass the full description, hash it on-chain
        string calldata _metadataUri,
        bytes calldata _initCode,
        bytes32 _previousVersionFingerprint // For simple upgrade tracking
    ) external {
        require(bytes(_name).length > 0, "Name required");
        require(_initCode.length > 0, "Bytecode required");

        bytes32 fingerprint = keccak256(_initCode);
        require(appMetadata[fingerprint].developer == address(0), "Fingerprint exists"); // Prevent duplicate bytecode submission

        // Simple versioning based on previous submission by the same dev
        uint256 nextVersion = 1;
        if (_previousVersionFingerprint != bytes32(0)) {
            AppMetadata storage prevMeta = appMetadata[_previousVersionFingerprint];
            require(prevMeta.developer == msg.sender, "Not previous version owner");
            nextVersion = prevMeta.version + 1;
        }

        appMetadata[fingerprint] = AppMetadata({
            developer: msg.sender,
            name: _name,
            descriptionHash: keccak256(bytes(_description)),
            metadataUri: _metadataUri,
            isApproved: false, // Requires admin approval
            version: nextVersion
        });

        pendingAppFingerprints.add(fingerprint);

        emit AppSubmitted(fingerprint, msg.sender, _name, _metadataUri, nextVersion);
    }

    /**
     * @notice Approve an app, making it deployable. Only owner.
     */
    function approveApp(bytes32 _fingerprint) external onlyOwner {
        require(appMetadata[_fingerprint].developer != address(0), "App not found");
        require(!appMetadata[_fingerprint].isApproved, "Already approved");
        require(pendingAppFingerprints.contains(_fingerprint), "Not pending"); // Ensure it was pending

        appMetadata[_fingerprint].isApproved = true;
        pendingAppFingerprints.remove(_fingerprint);
        approvedAppFingerprints.add(_fingerprint);

        emit AppApproved(_fingerprint);
    }

    /**
     * @notice Reject an app. Only owner.
     */
    function rejectApp(bytes32 _fingerprint) external onlyOwner {
        // Could add more logic, like preventing re-submission?
        require(pendingAppFingerprints.contains(_fingerprint), "Not pending");
        // Optionally delete metadata or just remove from pending set
        pendingAppFingerprints.remove(_fingerprint);
        // Optionally delete appMetadata[_fingerprint]; to allow resubmission with same code?
        emit AppRejected(_fingerprint);
    }

    /**
     * @notice Deploy an instance of an approved app using CREATE2.
     * @param _fingerprint The keccak256 hash of the init_code for the approved app version.
     * @param _initCode The actual init_code (deployment bytecode) - verified against the fingerprint.
     * @param _salt A unique salt provided by the deployer (e.g., keccak256(abi.encodePacked(msg.sender, nonce))).
     * @param _constructorArgs ABI encoded constructor arguments for the app instance.
     */
    function deployAppInstance(
        bytes32 _fingerprint,
        bytes calldata _initCode,
        bytes32 _salt,
        bytes calldata _constructorArgs
    ) external payable returns (address instanceAddress) { // Payable if constructor needs funds
        require(appMetadata[_fingerprint].isApproved, "App not approved");
        require(keccak256(_initCode) == _fingerprint, "Code mismatch"); // CRITICAL CHECK

        // Combine init code with constructor arguments
        bytes memory deploymentCode = abi.encodePacked(_initCode, _constructorArgs);

        // Deploy using CREATE2
        instanceAddress = Create2.deploy(msg.value, _salt, deploymentCode); // msg.value forwards ETH if needed

        require(instanceAddress != address(0), "Deployment failed");

        // Optional: Track deployed instances
        bytes32 instanceSaltHash = keccak256(abi.encodePacked(msg.sender, _salt)); // Unique identifier for this deployment attempt
        deployedInstances[msg.sender][_fingerprint].push(instanceAddress);

        emit AppDeployed(_fingerprint, msg.sender, instanceAddress, _salt);
    }

    // --- View Functions ---

    function getAppMetadata(bytes32 _fingerprint) external view returns (AppMetadata memory) {
        return appMetadata[_fingerprint];
    }

    function isApproved(bytes32 _fingerprint) external view returns (bool) {
        return appMetadata[_fingerprint].isApproved;
    }

    // Functions to get lists of approved/pending apps (use pagination off-chain)
    function getApprovedAppCount() external view returns (uint256) {
        return approvedAppFingerprints.length();
    }

    function getApprovedAppFingerprint(uint256 _index) external view returns (bytes32) {
        return approvedAppFingerprints.at(_index);
    }

     function getPendingAppCount() external view returns (uint256) {
        return pendingAppFingerprints.length();
    }

    function getPendingAppFingerprint(uint256 _index) external view returns (bytes32) {
        return pendingAppFingerprints.at(_index);
    }

    function predictDeterministicAddress(bytes32 _fingerprint, bytes32 _salt, address _deployer) public view returns (address) {
         require(appMetadata[_fingerprint].developer != address(0), "App not found"); // Check if app exists
         // Note: This prediction requires the INIT_CODE_HASH, which is the fingerprint IF no constructor args are used.
         // If constructor args are used, the actual hash needed by Create2.computeAddress is keccak256(abi.encodePacked(INIT_CODE, CONSTRUCTOR_ARGS)).
         // For a simple prediction without args, we can use the fingerprint directly.
         // A more accurate prediction function would need the _constructorArgs as well.
         return Create2.computeAddress(_salt, _fingerprint, _deployer);
    }
}