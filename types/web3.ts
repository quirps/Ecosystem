import { BigNumberish, BytesLike } from "ethers";

export type Facet = {
    name : string,
    facetCut : FacetCut
}

export type FacetCut = {
    facetAddress : string,
    action : BigNumberish,
    functionSelectors : BytesLike[],

}


export const FacetCutAction = {
    "Add" : 0,
    "Replace" : 1,
    "Remove" : 2
}

export type EthereumAddress = string & { readonly _brand: unique symbol };

// Usage
const myAddress: EthereumAddress = "0x1234567890abcdef1234567890abcdef12345678" as EthereumAddress;

// Validation utility
function isValidEthereumAddress(address: string): address is EthereumAddress {
  return /^0x[a-fA-F0-9]{40}$/.test(address);
}


type Selector = string & { readonly _brand: unique symbol };

// Usage
const mySelector: Selector = "0x12345678" as Selector;

// Validation utility
function isValidSelector(selector: string): selector is Selector {
  return /^0x[a-fA-F0-9]{8}$/.test(selector);
}


type Bytes32 = string & { readonly _brand: unique symbol };

// Usage
const myBytes32: Bytes32 = "0x" + "f".repeat(64) as Bytes32;

// Validation utility
function isValidBytes32(bytes: string): bytes is Bytes32 {
  return /^0x[a-fA-F0-9]{64}$/.test(bytes);
}
