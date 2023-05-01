pragma solidity ^0.8.6;

/**
 * Version assignment for both main and optimization version
 * 
 * Main version is canonical upgrades software version, where there is one
 * set of software that is upgraded. 
 * Optimization version is a hardcoded insertion into a particular function
 * such that it eventually is cost effective. 
 * 
 * How upgrades work in ecosystems is each main version must be upgradable to 
 * the next immediete upgrade, which also implies optimization versions are 
 * succesfully upgradable as well. 
 * 
 * Upgrades follow a chain in which ...
 
 * Facet registry util which maps bytecode of facet to hash, which
 acts as an id such that on-chain registration can exist. 

**Think about on-chain optimization**

For now we deploy 

Have a version check function, which iterates through all facet addresses
to determine main version 


This is a tool for owners/devs to use. In no way is this a definitive version of the 
ecossytem version. Can't be determined on-chain. 


When user wants to create an optimization, deploys it through facet registry. 

Optimization versions are a type {byte32 mainVersion, bytes32 signature}
Where signature is the keccack256(OPTIMIZED_FACET_BYTECODE)

Registry offers an on-chain way to verify what's going to be added to an ecosystem
 */


contract VersionFacet{
    uint32 mainVersion; 
    uint32 optimizationVersion;

    /**
     * Returns array of structs {address,bytes32} which corresponds to a facet's
     * address and bytecode signature respectively. This enables enable dev's to
     * easily verify diamond state. 
     */
    function versionCheck()external{}

}