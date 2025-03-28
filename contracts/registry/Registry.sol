// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../deploy/IDiamondDeploy.sol"; 
import "../facets/Diamond/IDiamondCut.sol"; 

import "hardhat/console.sol";
import "../facets/Ownership/_Ownership.sol";

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
contract EcosystemRegistry is iOwnership {
    // State Variables
    address public owner;
    mapping(bytes32 => Version) public versions;
    mapping(address => Ecosystem[]) userEcosystems;
    //mapping(uint240 => mapping(bytes32 => address)) optimizedFacet;

    // Structs
    struct Version {
        bool exists;
        uint32 uploadedTimestamp;
        address diamondDeployAddress; 
        IDiamondCut.FacetCut[] facetCuts;
    }
    

    struct Ecosystem {
        string name;
        address ecosytemAddress;
        bytes32 versionNumber;
    }

    // Events
    event VersionUploaded(bytes32 versionNumber);
    event EcosystemDeployed(address user, address ecosystem, bytes32 versionNumber, string name);
    event VersionUpgraded(bytes32 newVersion, bytes32 oldVersion, address ecosystemOwner);
    //event OptimizedFacets(uint240 versionNumber, bytes30 optimizationId, uint256 optimizationIndex, bytes[] bytecode, bytes[] params);


    // Constructor
    constructor() {
        owner = msgSender();
    }

    // Owner-Only Functions
    function uploadVersion(
        bytes32 versionNumber,
        address diamondDeployAddress, 
        IDiamondCut.FacetCut[] memory facetCuts
    ) public onlyOwner {
        require(msgSender() == owner, "Only the owner may upload new ecosystem versions.");
        require(! versions[versionNumber].exists, "Version already exists");

        Version storage newVersion = versions[versionNumber];
        newVersion.uploadedTimestamp = uint32(block.timestamp);
        newVersion.exists = true;
        newVersion.diamondDeployAddress = diamondDeployAddress;

        for (uint i = 0; i < facetCuts.length; i++) {
            
            newVersion.facetCuts.push(facetCuts[i]);
        }

        emit VersionUploaded(versionNumber);
    }

    // Public Functions
    function getVersion(bytes32 versionNumber) external view returns (Version memory) {
        return versions[versionNumber];
    }

    function getUserEcosystems(address ecosystemsOwner) external view returns (Ecosystem[] memory ecosystems_) {
        ecosystems_ = userEcosystems[ecosystemsOwner];
    }

    // Placeholder for future optimization related functions
    function registerOptimizationFacet(uint240 mainVersion, bytes2 optimizationType, bytes memory bytecode, bytes memory params) external {
        // Placeholder
    }

    //change to 
    function deployVersion(bytes32 versionNumber, string memory name, uint256 salt, bytes calldata diamondBytecode) public returns (address ecosystemAddress_) {
        Version storage _version = versions[versionNumber];
        // Step 1: Check version number validity
        require(_version.exists, "Version is not valid or not active");
         
        console.log(1); 
        ecosystemAddress_ = IDiamondDeploy(_version.diamondDeployAddress).deploy(msgSender(), salt, diamondBytecode, _version.facetCuts);
        console.log(2);
        // Step 4: Update the user's ecosystems
        Ecosystem memory newEcosystem = Ecosystem(name, ecosystemAddress_, versionNumber);
        userEcosystems[msg.sender].push(newEcosystem);
  
        // Emit Event
        emit EcosystemDeployed(msg.sender, ecosystemAddress_, versionNumber, name);
    }

    // function upgradeVersion(uint240 mainVersion, uint256 ecosystemIndex) external {
    //     // Check if user has a version, if not, reject
    //     Ecosystem[] storage ecosystems = userEcosystems[msg.sender];
    //     require(ecosystems.length > 0, "You do not have any ecosystem deployed");
    //     require(ecosystemIndex < ecosystems.length, "No ecosystem exists for this index.");

    //     Ecosystem memory currentEcosystem = ecosystems[ecosystemIndex];

    //     // Check mainVersion greater than current version
    //     require(mainVersion > currentEcosystem.versionNumber, "New version should be greater than current version");

    //     // Get current and new version details
    //     Version storage oldVersion = versions[currentEcosystem.versionNumber];
    //     Version storage newVersion = versions[mainVersion];
    //     require(newVersion.isActive, "The new version is not valid or active");

    //     // Take current facets and remove via diamondCut
    //     IDiamondCut.FacetCut[] memory removals = new IDiamondCut.FacetCut[](oldVersion.facets.length);
    //     for (uint256 i = 0; i < oldVersion.facets.length; i++) {
    //         removals[i] = IDiamondCut.FacetCut({
    //             facetAddress: address(0), // Removing
    //             action: IDiamondCut.FacetCutAction.Remove,
    //             functionSelectors: oldVersion.facets[i].functionSelectors
    //         });
    //     }
    //     IDiamondCut(currentEcosystem.ecosytemAddress).diamondCut(removals, address(0), "");

    //     // Add facets of new version via diamondCut
    //     IDiamondCut.FacetCut[] memory additions = new IDiamondCut.FacetCut[](newVersion.facets.length);
    //     for (uint256 i = 0; i < newVersion.facets.length; i++) {
    //         additions[i] = IDiamondCut.FacetCut({
    //             facetAddress: newVersion.facets[i].facetAddress,
    //             action: IDiamondCut.FacetCutAction.Add,
    //             functionSelectors: newVersion.facets[i].functionSelectors
    //         });
    //     }
    //     IDiamondCut(currentEcosystem.ecosytemAddress).diamondCut(additions, address(0), "");
    //     emit VersionUpgraded(mainVersion, currentEcosystem.versionNumber, msg.sender);
    //     // Update the current ecosystem's version number
    //     ecosystems[ecosystemIndex].versionNumber = mainVersion;
    //     // Emit Event
        
    // }
}
