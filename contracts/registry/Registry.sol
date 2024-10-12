// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../deploy/IDiamondDeploy.sol"; 
import "../facets/Diamond/IDiamondCut.sol"; 

import "hardhat/console.sol";


/**
TODO
Need to add Owner/Global freeze logic as inherited contract
Need to hardcoded facet <--> constructor dependencies and types
Would be accomplished better with Diamond

Ultimately have a diamond where the owner can only implement new versions.
Would need to add new versions, but have logic in main diamond. 
Upgrades - Get first version (earlier). Step up version upgrades
What changes do we need to watch out for? Forget localized optimizations for now.
    1. Consistent constructor inputs as prior. 
    2. Changing/Adding/Removing relevant facets

For 2, we loop starting at version i + 1  (i is starting version) and go to N (target version)
We should create an array of DiamondCuts. DiamondCuts must have constructor information too. 

 */
contract DiamondRegistry {
    // State Variables
    address public owner;
    mapping(uint240 => Version) public versions;
    mapping(address => Ecosystem[]) userEcosystems;
    mapping(uint240 => mapping(bytes32 => address)) optimizedFacet;

    // Structs
    struct Version {
        address diamondDeploy;
        bool isActive;
        uint32 uploadedTimestamp;
        Facet[] facets;
        uint256[][] optimizationMaps;
    }

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    struct Ecosystem {
        address ecosytemAddress;
        uint240 versionNumber;
    }

    // Events
    event VersionUploaded(uint240 versionNumber);
    event EcosystemDeployed(address user, address ecosystem, uint240 versionNumber);
    event VersionUpgraded(uint240 newVersion, uint240 oldVersion, address ecosystemOwner);
    event OptimizedFacets(uint240 versionNumber, bytes30 optimizationId, uint256 optimizationIndex, bytes[] bytecode, bytes[] params);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // Constructor
    constructor() {
        owner = msg.sender;
    }

    // Owner-Only Functions
    function uploadVersion(
        uint240 versionNumber,
        address diamondAddress,
        uint256[][] memory optimizationMaps,
        Facet[] memory facets
    ) public onlyOwner {
        require(!versions[versionNumber].isActive, "Version already exists");

        Version storage newVersion = versions[versionNumber];
        newVersion.diamondDeploy = diamondAddress;
        newVersion.uploadedTimestamp = uint32(block.timestamp);
        newVersion.isActive = true;
        newVersion.optimizationMaps = optimizationMaps;

        for (uint i = 0; i < facets.length; i++) {
            newVersion.facets.push(facets[i]);
        }

        emit VersionUploaded(versionNumber);
    }

    // Public Functions
    function getVersion(uint240 versionNumber) external view returns (Version memory) {
        return versions[versionNumber];
    }

    function getUserEcosystems(address ecosystemsOwner) external view returns (Ecosystem[] memory ecosystems_) {
        ecosystems_ = userEcosystems[ecosystemsOwner];
    }

    // Placeholder for future optimization related functions
    function registerOptimizationFacet(uint240 mainVersion, bytes2 optimizationType, bytes memory bytecode, bytes memory params) external {
        // Placeholder
    }

    function uploadOptimizedFacets(
        uint240 versionNumber,
        bytes30 optimizationId,
        uint256 optimizationIndex,
        bytes[] memory bytecode,
        bytes[] memory params
    ) public {
        // Check valid version number
        require(versions[versionNumber].isActive, "Version is not valid or not active");

        // Check optimization type non-zero
        require(optimizationId != bytes30(0), "Optimization ID cannot be zero");

        // Parameters arrays should be of the same length
        require(bytecode.length == params.length, "Bytecode and params length must match");

        // Must have nonzero bytecode
        require(bytecode.length > 0, "Bytecode array should not be empty");

        // optimizationIndex should be less than the length of optimizationMaps
        require(optimizationIndex < versions[versionNumber].optimizationMaps.length, "Invalid optimization index");

        uint256[] memory optMap = versions[versionNumber].optimizationMaps[optimizationIndex];

        // Make sure that the number of facets to be replaced match with the optimized facets
        require(optMap.length == bytecode.length, "Mismatch in number of facets to be optimized");

        // Loop through each bytecode and deploy optimization facet if not exists
        for (uint256 i; i < bytecode.length; i++) {
            bytes32 hashValue = keccak256(abi.encode(bytecode[i], params[i]));

            // Check if optimization already exists
            if (optimizedFacet[versionNumber][hashValue] == address(0)) {
                address facetAddress;
                bytes32 salt = keccak256(abi.encodePacked(msg.sender, versionNumber)); // Generate a unique salt
                bytes memory _bytecode = bytecode[i];
                assembly {
                    facetAddress := create2(0, add(_bytecode, 0x20), mload(_bytecode), salt)
                    if iszero(extcodesize(facetAddress)) {
                        revert(0, 0)
                    }
                }

                // Update optimizedFacet mapping
                optimizedFacet[versionNumber][hashValue] = facetAddress;

                // Assuming you would update the version facet list
                versions[versionNumber].facets[optMap[i]].facetAddress = facetAddress;
            }
        }

        emit OptimizedFacets(versionNumber, optimizationId, optimizationIndex, bytecode, params);
    }

    function addOptimizedFacets(uint240 versionNumber, address ecosytem, bytes30[] memory optimizedFacet) external {
        //check valid version number
        //ecosystem matches version number
        //loop over optimizations, replace respsective facets
        //check optimization is under correct version number
        //check
    }

    function deployVersion(uint240 versionNumber, bytes memory bytecode) public returns (address deployedAddress) {
        // Step 1: Check version number validity
        require(versions[versionNumber].isActive, "Version is not valid or not active");

        // Step 2: Retrieve the bytecode
        Version storage _version = versions[versionNumber];
        deployedAddress = IDiamondDeploy(_version.diamondDeploy).deploy(bytecode);

        // Step 4: Add facets
        Facet[] memory facets = _version.facets;
        IDiamondCut.FacetCut[] memory _facetCut = new IDiamondCut.FacetCut[](facets.length);
        for (uint256 i = 0; i < facets.length; i++) {
            console.log(i);
            console.log(facets[i].facetAddress);
            console.logBytes4(facets[i].functionSelectors[0]);
            _facetCut[i] = IDiamondCut.FacetCut({
                facetAddress: facets[i].facetAddress,
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: facets[i].functionSelectors
            });
        }
        IDiamondCut(deployedAddress).diamondCut(_facetCut, address(0), "");

        // Step 5: Update the user's ecosystems
        Ecosystem memory newEcosystem = Ecosystem({ecosytemAddress: deployedAddress, versionNumber: versionNumber});
        userEcosystems[msg.sender].push(newEcosystem);

        // Emit Event
        emit EcosystemDeployed(msg.sender, deployedAddress, versionNumber);
    }

    function upgradeVersion(uint240 mainVersion, uint256 ecosystemIndex) external {
        // Check if user has a version, if not, reject
        Ecosystem[] storage ecosystems = userEcosystems[msg.sender];
        require(ecosystems.length > 0, "You do not have any ecosystem deployed");
        require(ecosystemIndex < ecosystems.length, "No ecosystem exists for this index.");

        Ecosystem memory currentEcosystem = ecosystems[ecosystemIndex];

        // Check mainVersion greater than current version
        require(mainVersion > currentEcosystem.versionNumber, "New version should be greater than current version");

        // Get current and new version details
        Version storage oldVersion = versions[currentEcosystem.versionNumber];
        Version storage newVersion = versions[mainVersion];
        require(newVersion.isActive, "The new version is not valid or active");

        // Take current facets and remove via diamondCut
        IDiamondCut.FacetCut[] memory removals = new IDiamondCut.FacetCut[](oldVersion.facets.length);
        for (uint256 i = 0; i < oldVersion.facets.length; i++) {
            removals[i] = IDiamondCut.FacetCut({
                facetAddress: address(0), // Removing
                action: IDiamondCut.FacetCutAction.Remove,
                functionSelectors: oldVersion.facets[i].functionSelectors
            });
        }
        IDiamondCut(currentEcosystem.ecosytemAddress).diamondCut(removals, address(0), "");

        // Add facets of new version via diamondCut
        IDiamondCut.FacetCut[] memory additions = new IDiamondCut.FacetCut[](newVersion.facets.length);
        for (uint256 i = 0; i < newVersion.facets.length; i++) {
            additions[i] = IDiamondCut.FacetCut({
                facetAddress: newVersion.facets[i].facetAddress,
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: newVersion.facets[i].functionSelectors
            });
        }
        IDiamondCut(currentEcosystem.ecosytemAddress).diamondCut(additions, address(0), "");
        emit VersionUpgraded(mainVersion, currentEcosystem.versionNumber, msg.sender);
        // Update the current ecosystem's version number
        ecosystems[ecosystemIndex].versionNumber = mainVersion;
        // Emit Event
        
    }
}
