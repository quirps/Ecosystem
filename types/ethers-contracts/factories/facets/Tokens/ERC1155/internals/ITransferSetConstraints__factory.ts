/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../../../common";
import type {
  ITransferSetConstraints,
  ITransferSetConstraintsInterface,
} from "../../../../../facets/Tokens/ERC1155/internals/ITransferSetConstraints";

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
    inputs: [
      {
        internalType: "address",
        name: "from",
        type: "address",
      },
      {
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "ticketId",
        type: "uint256",
      },
    ],
    name: "NonTransferableError",
    type: "error",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "user",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint32",
        name: "timestamp",
        type: "uint32",
      },
    ],
    name: "MemberBanned",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        components: [
          {
            internalType: "address",
            name: "memberAddress",
            type: "address",
          },
          {
            internalType: "uint32",
            name: "level",
            type: "uint32",
          },
          {
            internalType: "uint32",
            name: "timestamp",
            type: "uint32",
          },
        ],
        indexed: false,
        internalType: "struct LibMemberLevel.Leaf",
        name: "leaf",
        type: "tuple",
      },
    ],
    name: "MemberLevelUpdated",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "bytes32",
        name: "newRoot",
        type: "bytes32",
      },
    ],
    name: "MerkleRootUpdated",
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
        internalType: "address",
        name: "oldOwner",
        type: "address",
      },
      {
        indexed: false,
        internalType: "address",
        name: "newOwner",
        type: "address",
      },
    ],
    name: "OwnershipChanged",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "ticketId",
        type: "uint256",
      },
    ],
    name: "expireable",
    outputs: [],
    stateMutability: "view",
    type: "function",
  },
] as const;

const _bytecode =
  "0x6080604052348015600e575f5ffd5b506101598061001c5f395ff3fe608060405234801561000f575f5ffd5b5060043610610029575f3560e01c806345b5fd721461002d575b5f5ffd5b61004061003b36600461010c565b610042565b005b5f8181527f7a8949a66712f1d1ae515adbd4b0835db540861dfc3638f5ebc928c2d0736d2660205260409020547f7a8949a66712f1d1ae515adbd4b0835db540861dfc3638f5ebc928c2d0736d249063ffffffff164281106101075760405162461bcd60e51b815260206004820152603460248201527f457870697265643a20446561646c696e6520666f72207469636b657420636f6e60448201527339bab6b83a34b7b7103430b9903830b9b9b2b21760611b606482015260840160405180910390fd5b505050565b5f6020828403121561011c575f5ffd5b503591905056fea2646970667358221220fd94f9d704ecebecf6fc074ff6a6596eaf6ac037e6dd45c33f955c30dc9bec6b64736f6c634300081c0033";

type ITransferSetConstraintsConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: ITransferSetConstraintsConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class ITransferSetConstraints__factory extends ContractFactory {
  constructor(...args: ITransferSetConstraintsConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ITransferSetConstraints> {
    return super.deploy(overrides || {}) as Promise<ITransferSetConstraints>;
  }
  override getDeployTransaction(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  override attach(address: string): ITransferSetConstraints {
    return super.attach(address) as ITransferSetConstraints;
  }
  override connect(signer: Signer): ITransferSetConstraints__factory {
    return super.connect(signer) as ITransferSetConstraints__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): ITransferSetConstraintsInterface {
    return new utils.Interface(_abi) as ITransferSetConstraintsInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): ITransferSetConstraints {
    return new Contract(
      address,
      _abi,
      signerOrProvider
    ) as ITransferSetConstraints;
  }
}
