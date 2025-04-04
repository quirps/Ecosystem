/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type {
  IMemberRegistry,
  IMemberRegistryInterface,
} from "../../../facets/MemberRegistry/IMemberRegistry";

const _abi = [
  {
    inputs: [
      {
        internalType: "string",
        name: "username",
        type: "string",
      },
    ],
    name: "cancelVerify",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "string",
        name: "username",
        type: "string",
      },
    ],
    name: "finalizeRecovery",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "string",
        name: "username",
        type: "string",
      },
    ],
    name: "setUsernameAddressPair",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "string[]",
        name: "username",
        type: "string[]",
      },
      {
        internalType: "address[]",
        name: "userAddress",
        type: "address[]",
      },
    ],
    name: "setUsernameOwner",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "string",
        name: "username",
        type: "string",
      },
    ],
    name: "setUsernamePair",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "string",
        name: "username",
        type: "string",
      },
    ],
    name: "usernameRecovery",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        components: [
          {
            internalType: "string",
            name: "username",
            type: "string",
          },
          {
            internalType: "address",
            name: "userAddress",
            type: "address",
          },
        ],
        internalType: "struct LibMemberRegistry.Leaf",
        name: "_leaf",
        type: "tuple",
      },
      {
        internalType: "bytes32[]",
        name: "_merkleProof",
        type: "bytes32[]",
      },
    ],
    name: "verifyAndUsername",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;

export class IMemberRegistry__factory {
  static readonly abi = _abi;
  static createInterface(): IMemberRegistryInterface {
    return new utils.Interface(_abi) as IMemberRegistryInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): IMemberRegistry {
    return new Contract(address, _abi, signerOrProvider) as IMemberRegistry;
  }
}
