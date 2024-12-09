/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../../common";
import type {
  ISales,
  ISalesInterface,
} from "../../../../facets/Sales/_Sales.sol/ISales";

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
        indexed: true,
        internalType: "address",
        name: "account",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "operator",
        type: "address",
      },
      {
        indexed: false,
        internalType: "bool",
        name: "approved",
        type: "bool",
      },
    ],
    name: "ApprovalForAll",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "uint256",
        name: "saleId",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "address",
        name: "buyer",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "numBundles",
        type: "uint256",
      },
    ],
    name: "ItemPurchased",
    type: "event",
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
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "uint256",
        name: "saleId",
        type: "uint256",
      },
    ],
    name: "SaleCreated",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "operator",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "from",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256[]",
        name: "ids",
        type: "uint256[]",
      },
      {
        indexed: false,
        internalType: "uint256[]",
        name: "values",
        type: "uint256[]",
      },
    ],
    name: "TransferBatch",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "operator",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "from",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "id",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "value",
        type: "uint256",
      },
    ],
    name: "TransferSingle",
    type: "event",
  },
] as const;

const _bytecode =
  "0x6080604052348015600f57600080fd5b50603f80601d6000396000f3fe6080604052600080fdfea2646970667358221220c1dbf77f246d9c9948a563b8414c46399c1e523a25cb0c9766d3f584d752b23f64736f6c63430008090033";

type ISalesConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: ISalesConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class ISales__factory extends ContractFactory {
  constructor(...args: ISalesConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ISales> {
    return super.deploy(overrides || {}) as Promise<ISales>;
  }
  override getDeployTransaction(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  override attach(address: string): ISales {
    return super.attach(address) as ISales;
  }
  override connect(signer: Signer): ISales__factory {
    return super.connect(signer) as ISales__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): ISalesInterface {
    return new utils.Interface(_abi) as ISalesInterface;
  }
  static connect(address: string, signerOrProvider: Signer | Provider): ISales {
    return new Contract(address, _abi, signerOrProvider) as ISales;
  }
}
