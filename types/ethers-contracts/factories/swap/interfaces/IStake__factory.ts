/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type { IStake, IStakeInterface } from "../../../swap/interfaces/IStake";

const _abi = [
  {
    inputs: [
      {
        internalType: "address[]",
        name: "user",
        type: "address[]",
      },
      {
        internalType: "uint256[]",
        name: "amount",
        type: "uint256[]",
      },
      {
        internalType: "enum IStake.StakeTier[]",
        name: "tier",
        type: "uint8[]",
      },
      {
        internalType: "uint256[]",
        name: "stakeIds",
        type: "uint256[]",
      },
    ],
    name: "batchStake",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "fundStakeAccount",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "enum IStake.StakeTier[]",
        name: "_stakeTier",
        type: "uint8[]",
      },
      {
        components: [
          {
            internalType: "uint16",
            name: "initialRate",
            type: "uint16",
          },
          {
            internalType: "uint16",
            name: "rateIncrease",
            type: "uint16",
          },
          {
            internalType: "uint16",
            name: "rateIncreaseStopDuration",
            type: "uint16",
          },
        ],
        internalType: "struct IStake.RewardRate[]",
        name: "_rewardRate",
        type: "tuple[]",
      },
    ],
    name: "setRewardRates",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "user",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
      {
        internalType: "enum IStake.StakeTier",
        name: "tier",
        type: "uint8",
      },
      {
        internalType: "uint256",
        name: "stakeId",
        type: "uint256",
      },
    ],
    name: "stake",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "user",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "stakeId",
        type: "uint256",
      },
    ],
    name: "unstake",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;

export class IStake__factory {
  static readonly abi = _abi;
  static createInterface(): IStakeInterface {
    return new utils.Interface(_abi) as IStakeInterface;
  }
  static connect(address: string, signerOrProvider: Signer | Provider): IStake {
    return new Contract(address, _abi, signerOrProvider) as IStake;
  }
}
