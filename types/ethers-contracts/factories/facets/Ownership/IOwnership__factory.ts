/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type {
  IOwnership,
  IOwnershipInterface,
} from "../../../facets/Ownership/IOwnership";

const _abi = [
  {
    inputs: [],
    name: "ecosystemOwner",
    outputs: [
      {
        internalType: "address",
        name: "owner_",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_tenativeOwner",
        type: "address",
      },
    ],
    name: "isEcosystemOwnerVerify",
    outputs: [],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_newOwner",
        type: "address",
      },
    ],
    name: "setEcosystemOwner",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;

export class IOwnership__factory {
  static readonly abi = _abi;
  static createInterface(): IOwnershipInterface {
    return new utils.Interface(_abi) as IOwnershipInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): IOwnership {
    return new Contract(address, _abi, signerOrProvider) as IOwnership;
  }
}
