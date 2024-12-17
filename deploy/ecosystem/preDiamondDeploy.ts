//Deploys current version

const {
    ethers
} = require('hardhat')
const {
    selectorCollision,
    getSelectors
} = require("../libraries/diamond")
 
const {getFacetNames} = require('./versions')

import type {Facet, FacetCut, EthereumAddress } from "../../types/web3" 
import { FacetCutAction  } from "../../types/web3" 


import type { Ecosystem } from "../../types/ethers-contracts/Ecosystem"
import type { EcosystemRegistry } from "../../types/ethers-contracts/registry/Registry.sol/EcosystemRegistry"
import type { IDiamondCut } from "../../types/ethers-contracts/facets/Diamond/IDiamondCut"
import type { EcosystemConfig } from "../../types/deploy/userConfig"
 
import type {Signer} from "ethers"
//Import a class for registry
// uint240 versionNumber,
// address diamondAddress,
// uint256[][] memory optimizationMaps,
// Facet[] memory facets
//Likely import this from config


//add specific types for address, selector

  
///need to mesh diamond deploy here with registry deploy
export async function facetDeploy(version : string) {
    let diamondCutFacetAddress;
    

    const facetNames : string[] = getFacetNames(version)
    const facets : Facet[] = []
    const deployedStatuses : Promise<Facet>[] = [];
    
    //deploy every facet
    for (let facetName of facetNames ) {
        let selectors : string[];
        
        const Facet = await ethers.getContractFactory(facetName);
        const facet = await Facet.deploy()

        deployedStatuses.push(facet.deployed());
 
        if (facetName == "DiamondCutFacet") {
            diamondCutFacetAddress = facet.address;
        }
        selectors = getSelectors(facet);
        let _facetCut : FacetCut = {facetAddress: facet.address, action : FacetCutAction.Add, functionSelectors : selectors}
        facets.push( {name : facetName, facetCut : _facetCut} );
    }
    await Promise.all(deployedStatuses) 

    //check for facet collisions
    const collision = await selectorCollision(facets)
    if (collision) {
         throw Error(`Collsion detected at facet ${collision[0]} and facet ${collision[1]} with selector ${collision[2]} \n `)
    }


    return facets
}


/**
 * Deploys a Diamond Registry and a Diamond Deploy contract for an ecosystem.
 * 
 * This function deploys a Diamond Factory and DiamondRegistry contract, and then uploads a version/
 *  with the provided facets,
 * 
 *
 * @param version - The version string for the ecosystem being deployed.
 * @param ecosystemName - The name of the ecosystem being deployed.
 * @param facets - An array of Facet objects representing the facets to be included in the Diamond.
 * 
 * @returns An object containing:
 *   - registry: The deployed DiamondRegistry contract instance.
 */
export async function registryDeploy( ) {
    let diamondAddress;

    let diamondBytecode = (await ethers.getContractFactory('Diamond')).bytecode
    //diamondDeploy 
    const DiamondDeploy = await ethers.getContractFactory("DiamondDeploy")
    const diamondDeploy = await DiamondDeploy.deploy(diamondBytecode);

    //registryDeploy 
    let Registry = await ethers.getContractFactory('EcosystemRegistry')
    let registry = await  Registry.deploy(diamondDeploy.address);
    await registry.deployed();

    //set registry address
    await diamondDeploy.setRegistry(registry.address);

    

    // let Diamond = await ethers.getContractFactory('Diamond');
    // let diamond = await Diamond.deploy(registry.address, registry.address, facetCuts);
    // Success!

    // const gasEstimate = await diamondDeploy.estimateGas.deployVersion(
    //     registry.address, 3849498, diamondBytecode, facetCuts
    //   );
    //await diamondDeploy.deploy(registry.address, 3849498, diamondBytecode, facetCuts,{gasLimit : 10000000});
    
    return {registry}
}

// contract Diamond is iOwnership{    

//     constructor(address _owner, address _registry, IDiamondCut.FacetCut[] memory _cuts) payable {    
//         LibOwnership._setRegistry( _registry );    
//         LibOwnership._setEcosystemOwner( _owner ); 
//         LibDiamond.diamondCut(_cuts, address(0), "");        
//     }

/**
 * Deploys an ecosystem on the Ethereum network using a pre-existing diamond registry.
 *
 * @param version - The version of the ecosystem to be deployed.
 * @param registry - The pre-existing diamond registry contract instance.
 * @param diamondAddress - The address of the diamond contract to be used for the ecosystem.
 * @param ecosystemName - The name of the ecosystem to be deployed.
 *
 * @returns A deployed ecosystem contract instance with a cumullative ABI of all the facets.
 */
export async function deployEcosystems(
    ecosystemConfig : EcosystemConfig,
    registry : EcosystemRegistry,
    owner : Signer
): Promise<Ecosystem> {
    const salt : number= 34242424244;
    let ecosystem : Ecosystem;
    let diamondAddress : string; 
    let diamondBytecode = (await ethers.getContractFactory('Diamond')).bytecode;

    const { version, name } = ecosystemConfig
    const versionBytes = ethers.utils.formatBytes32String( version );

    //connect owner for deploy of ecosystem
    const registryWithSigner = registry.connect(owner);

    diamondAddress  = await registryWithSigner.callStatic.deployVersion(versionBytes, name, salt, diamondBytecode);
    console.log(diamondAddress)
    await registryWithSigner.deployVersion(versionBytes, name, salt, diamondBytecode, {gasLimit: 10000000});

    ecosystem = await ethers.getContractAt('Ecosystem', diamondAddress);

    return ecosystem;
}

export async function registryUploadVersion(  facets : Facet[], registry : EcosystemRegistry, version : string){
    const versionBytes = ethers.utils.formatBytes32String(version);

    const facetCuts : IDiamondCut.FacetCutStruct[] = facets.map((facet) => ({
        facetAddress: facet.facetCut.facetAddress,
        action: facet.facetCut.action,
        functionSelectors: facet.facetCut.functionSelectors
    }));

    await registry.uploadVersion(versionBytes, facetCuts);
}




// if (require.main === module) {
//     preDiamondDeploy()
//         .then(() => process.exit(0))
//         .catch(error => {
//             console.error(error)
//             process.exit(1)
//         })
// }
