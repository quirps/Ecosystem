/**
 * deploys facets
 * deploys registry 
 * deploys diamond and cuts facets
 * initializes
 * actions
 */
const {getSelectors} = require('../scripts/libraries/diamond')

const {preDiamondDeploy}  = require("./preDiamondDeploy")
const {registryDeploy, registryVersionUploadDeploy} = require("./registryDeploy")


async function main(){
    let registry;
    const[diamondDeployAddress, facets] = await preDiamondDeploy();

    registry = await registryDeploy();
    let Verion = [
        1,
        diamondDeployAddress,
        [],

    ]
    registryVersionUploadDeploy(registry, )
}