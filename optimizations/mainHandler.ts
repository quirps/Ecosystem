// this function what gets executed from frontend
// should 
const fs = require('fs')

const { maxTicket } = require('./optimizationHandlers/maxTicket.ts')

interface OptimizationFrontend {
    optimizationName: string;
    optimizationParams: any;
}

let handlerRouter = {
    maxTicket: maxTicket
}
// if optimization is outside the external section of the facet, must keep track
// of the dependencies
/**
 * How to track dependencies? If an optimization is added?
 * We can manually track which facets would need to be replaced with 
 * optimization
 * Registry - How should it be organized?
 *      Probably a mapping to struct, where mapping is bytes?
 *  struct Optimization{
 *      bytes12 mainVersion;
 *      address facetAddress;
 *      facetName string;
 *  }
 * main version -> optimization -> string[] facetNames
 * Facet AND Optimization, different. 
 * 
 * Need a diamong registry, more needs to be added
 * 
 * mapping(bytecode_signature => Facet)
 * What is mapping key? bytecode signature?
 * Could create another mapping   mainVersion -> facetName -> Optimization version {address}
 * Also need to store face
*/

/**
 * There is set of facetNames per each main version.
 * Should be a signature, which is the first 8 bytes of keccack bytecode 
 * of optimized facet where optimization parameters are emitted via an event.
 * This would allow some sense of verification if outside users were able to recreate
 * optimizations 
 * 
 * Each main version will have an associated facetNames, optimizationParameter.
 * Create struct containing all structs for each optimization function param.
 * This is the encoding blueprint for input data to optimizer functions are
 * How would we update the types on-chain? Could just provide type string,
 * ['uint256','address',...] which enables ethers to naturally decode the 
 * event. 
 */

function codeInsertion() {

}

function loadFile() {

}

function retrieveBytecode() {

}

function mainOptimizationHandler(optimizationFrontend: OptimizationFrontend[]): boolean {
    let optimizationConfig = JSON.parse(fs.readFileSync("./optimization.json"))
    //load file
    for (let _optimization of optimizationFrontend) {
        let { optimizationName, optimizationParams } = _optimization;
        let optimizationStruct = optimizationConfig[optimizationName]
        let codeString: string = handlerRouter[optimizationStruct.handlerName](optimizationParams)
        //code insertion
    }
    return true
}