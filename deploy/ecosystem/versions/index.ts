
const VERSION_FILE : { [ key : string ] : string }= {
    "0.0.0" : "0.0.0"
}
 
export function getFacetNames( version : string) : string[] {
    if( VERSION_FILE[ version ] !== undefined ){
        const { facets } = require("./" + version)
        return facets
    }
    else{
        throw Error("Version doesn't exist.")
    }
}