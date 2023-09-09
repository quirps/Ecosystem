/*
 * Should accept a list of facet names
 * Should deploy diamond through registry 
 * Should return all listed contracts via diamond Address
 * Alternative module should handle initializing, potentially pipelining this
 */
const ethers = require("ethers")
const {
    facetNameOrder
} = require("../deploy/libraries/libDeploy")

/**
 * 
 * @param {string[]} facetNames - Facets to be deployed 
 */
function deployDiamond(facetsNames) {
    facetNameOrder(facetNames) //Deployment Ordering
    //default deployment
    //facet deployment
}

if (require.main == module) {
    deployDiamond().then(() => process.exit(0))
        .catch((e) => {
            console.log(e)
            process.exit(1)
        })
}
exports.deployDiamond = deployDiamond


/**
 * How should initialization be done?
 * Eventually going to be used after deployed, but when? 
 * Seperating the deploy from intializtion makes sense proceduraly. 
 * So:
 *  Deploy 
 * 
 * Front End tests with multiple ecosystems
 *  -Multiple Deployments
 *  -Multiple initializaitons
 * Initializaitons and deployments have a well defined order, so each
 * version is constrained. 
 * 
 * Create an ordering function, to make the facet lists well ordered
 */


/**
 * Why not just wrap facets into a single ec
 */