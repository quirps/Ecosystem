
 
export function getFacetNames( version : string) : string[] {
    if( version !== undefined ){
        const { facets } = require("./" + version)
        return facets
    }
    else{
        throw Error("Version doesn't exist.")
    }
}