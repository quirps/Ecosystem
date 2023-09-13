const {FACETS} = require("../constants")

function facetNameOrder(facetNames){
    return subset.sort((a, b) => {
        return FACETS.indexOf(a) - FACETS.indexOf(b);
      });
}

function facetUploadVersionConvert(facetContractFactories){
  let facetsUpload = []
  for( let factory of facetContractFactories){
      facetsUpload.push( [factory.address, getSelectors] )
  }
}

module.exports = {facetNameOrder}