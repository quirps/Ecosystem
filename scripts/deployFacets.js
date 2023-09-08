/*
* Should accept a list of facet names
* Should deploy diamond through registry 
* Should return all listed contracts via diamond Address
* Alternative module should handle initializing, potentially pipelining this
*/




if(require.main == module){
    deployDiamond().then( () => process.exit(0))
    .catch( (e) => {
        console.log(e)
        process.exit(1)
        })
}  
exports.deployDiamond = deployDiamond
  
