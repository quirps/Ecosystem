const { facetDeploy, registryDeploy, deployEcosystems} = require('./preDiamondDeploy')

export async function ecosystemDeploy(version : string , ecosystemName : string)  {
    let ecosystems;
    const facets = await facetDeploy(version);
  
    const {registry, diamondAddress} = await registryDeploy(version, ecosystemName, facets);

    ecosystems = deployEcosystems(version, registry, diamondAddress,ecosystemName)
    console.log("finished")
    return ecosystems
}