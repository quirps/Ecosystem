const {FACETS} = require("../constants")

function facetNameOrder(facetNames){
    return subset.sort((a, b) => {
        return FACETS.indexOf(a) - FACETS.indexOf(b);
      });
}


module.exports = {facetNameOrder}