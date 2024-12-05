/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../../common";
import type {
  IOwnership,
  IOwnershipInterface,
} from "../../../../facets/Ownership/_Ownership.sol/IOwnership";

const _abi = [
  {
    inputs: [],
    name: "MigrationAlreadyCompleted",
    type: "error",
  },
  {
    inputs: [],
    name: "MigrationAlreadyInitiated",
    type: "error",
  },
  {
    inputs: [],
    name: "MigrationNotInitiated",
    type: "error",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "cancellor",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint32",
        name: "timeCancelled",
        type: "uint32",
      },
    ],
    name: "MigrationCancelled",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "initiatior",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint32",
        name: "timeInitiatied",
        type: "uint32",
      },
    ],
    name: "MigrationInitiated",
    type: "event",
  },
] as const;

const _bytecode =
  "0x6080604052348015600f57600080fd5b50603f80601d6000396000f3fe6080604052600080fdfea2646970667358221220bae47a6837ad2f4f88ad848cbc778c9bf54b6e3b5d4d9eab27872840c696cae464736f6c63430008090033";

type IOwnershipConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: IOwnershipConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class IOwnership__factory extends ContractFactory {
  constructor(...args: IOwnershipConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<IOwnership> {
    return super.deploy(overrides || {}) as Promise<IOwnership>;
  }
  override getDeployTransaction(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  override attach(address: string): IOwnership {
    return super.attach(address) as IOwnership;
  }
  override connect(signer: Signer): IOwnership__factory {
    return super.connect(signer) as IOwnership__factory;
  }

  static readonly bytecode = _bytecode;
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
