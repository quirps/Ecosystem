/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type {
  IDiamondDeploy,
  IDiamondDeployInterface,
} from "../../deploy/IDiamondDeploy";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "_owner",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_salt",
        type: "uint256",
      },
      {
        internalType: "bytes",
        name: "_bytecode",
        type: "bytes",
      },
      {
        components: [
          {
            internalType: "address",
            name: "facetAddress",
            type: "address",
          },
          {
            internalType: "enum IDiamondCut.FacetCutAction",
            name: "action",
            type: "uint8",
          },
          {
            internalType: "bytes4[]",
            name: "functionSelectors",
            type: "bytes4[]",
          },
        ],
        internalType: "struct IDiamondCut.FacetCut[]",
        name: "_facetCuts",
        type: "tuple[]",
      },
    ],
    name: "deploy",
    outputs: [
      {
        internalType: "address",
        name: "diamond_",
        type: "address",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "diamondCutFacet",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
] as const;

export class IDiamondDeploy__factory {
  static readonly abi = _abi;
  static createInterface(): IDiamondDeployInterface {
    return new utils.Interface(_abi) as IDiamondDeployInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): IDiamondDeploy {
    return new Contract(address, _abi, signerOrProvider) as IDiamondDeploy;
  }
}
