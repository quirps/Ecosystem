/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../common";
import type {
  MyERC1155Receiver,
  MyERC1155ReceiverInterface,
} from "../../../exchange/ERC1155Receiver.sol/MyERC1155Receiver";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "operator",
        type: "address",
      },
      {
        internalType: "address",
        name: "from",
        type: "address",
      },
      {
        internalType: "uint256[]",
        name: "ids",
        type: "uint256[]",
      },
      {
        internalType: "uint256[]",
        name: "values",
        type: "uint256[]",
      },
      {
        internalType: "bytes",
        name: "data",
        type: "bytes",
      },
    ],
    name: "onERC1155BatchReceived",
    outputs: [
      {
        internalType: "bytes4",
        name: "",
        type: "bytes4",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "operator",
        type: "address",
      },
      {
        internalType: "address",
        name: "from",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "id",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "value",
        type: "uint256",
      },
      {
        internalType: "bytes",
        name: "data",
        type: "bytes",
      },
    ],
    name: "onERC1155Received",
    outputs: [
      {
        internalType: "bytes4",
        name: "",
        type: "bytes4",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes4",
        name: "interfaceId",
        type: "bytes4",
      },
    ],
    name: "supportsInterface",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
] as const;

const _bytecode =
  "0x6080604052348015600e575f5ffd5b5061034e8061001c5f395ff3fe608060405234801561000f575f5ffd5b506004361061003f575f3560e01c806301ffc9a714610043578063bc197c811461006b578063f23a6e61146100a6575b5f5ffd5b610056610051366004610117565b6100c6565b60405190151581526020015b60405180910390f35b61008d6100793660046101e6565b63bc197c8160e01b98975050505050505050565b6040516001600160e01b03199091168152602001610062565b61008d6100b43660046102a5565b63f23a6e6160e01b9695505050505050565b5f6001600160e01b0319821663f23a6e6160e01b14806100f657506001600160e01b0319821663bc197c8160e01b145b8061011157506301ffc9a760e01b6001600160e01b03198316145b92915050565b5f60208284031215610127575f5ffd5b81356001600160e01b03198116811461013e575f5ffd5b9392505050565b80356001600160a01b038116811461015b575f5ffd5b919050565b5f5f83601f840112610170575f5ffd5b50813567ffffffffffffffff811115610187575f5ffd5b6020830191508360208260051b85010111156101a1575f5ffd5b9250929050565b5f5f83601f8401126101b8575f5ffd5b50813567ffffffffffffffff8111156101cf575f5ffd5b6020830191508360208285010111156101a1575f5ffd5b5f5f5f5f5f5f5f5f60a0898b0312156101fd575f5ffd5b61020689610145565b975061021460208a01610145565b9650604089013567ffffffffffffffff81111561022f575f5ffd5b61023b8b828c01610160565b909750955050606089013567ffffffffffffffff81111561025a575f5ffd5b6102668b828c01610160565b909550935050608089013567ffffffffffffffff811115610285575f5ffd5b6102918b828c016101a8565b999c989b5096995094979396929594505050565b5f5f5f5f5f5f60a087890312156102ba575f5ffd5b6102c387610145565b95506102d160208801610145565b94506040870135935060608701359250608087013567ffffffffffffffff8111156102fa575f5ffd5b61030689828a016101a8565b979a969950949750929593949250505056fea26469706673582212208ab892d59383c76e8756da93ff90222d3e9147831f7b28f46f4da1632575b0a064736f6c634300081c0033";

type MyERC1155ReceiverConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: MyERC1155ReceiverConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class MyERC1155Receiver__factory extends ContractFactory {
  constructor(...args: MyERC1155ReceiverConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<MyERC1155Receiver> {
    return super.deploy(overrides || {}) as Promise<MyERC1155Receiver>;
  }
  override getDeployTransaction(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  override attach(address: string): MyERC1155Receiver {
    return super.attach(address) as MyERC1155Receiver;
  }
  override connect(signer: Signer): MyERC1155Receiver__factory {
    return super.connect(signer) as MyERC1155Receiver__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): MyERC1155ReceiverInterface {
    return new utils.Interface(_abi) as MyERC1155ReceiverInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): MyERC1155Receiver {
    return new Contract(address, _abi, signerOrProvider) as MyERC1155Receiver;
  }
}
