export type Facet = {
    name : string,
    facetCut : FacetCut
}

export type FacetCut = {
    facetAddress : string,
    action : Number,
    functionSelectors : string[],

}

export const FacetCutAction = {
    "Add" : 0,
    "Replace" : 1,
    "Remove" : 2
}
