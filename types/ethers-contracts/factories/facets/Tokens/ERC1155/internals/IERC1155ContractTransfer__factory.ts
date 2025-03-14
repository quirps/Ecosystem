/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../../../common";
import type {
  IERC1155ContractTransfer,
  IERC1155ContractTransferInterface,
} from "../../../../../facets/Tokens/ERC1155/internals/IERC1155ContractTransfer";

const _abi = [
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
  "0x6080604052348015600f57600080fd5b50603f80601d6000396000f3fe6080604052600080fdfea2646970667358221220ec198c79d70eac9e482db2d0ff0073056161569ff6c4cd7e630491abcf2a34a464736f6c63430008090033";

type IERC1155ContractTransferConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: IERC1155ContractTransferConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class IERC1155ContractTransfer__factory extends ContractFactory {
  constructor(...args: IERC1155ContractTransferConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<IERC1155ContractTransfer> {
    return super.deploy(overrides || {}) as Promise<IERC1155ContractTransfer>;
  }
  override getDeployTransaction(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  override attach(address: string): IERC1155ContractTransfer {
    return super.attach(address) as IERC1155ContractTransfer;
  }
  override connect(signer: Signer): IERC1155ContractTransfer__factory {
    return super.connect(signer) as IERC1155ContractTransfer__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): IERC1155ContractTransferInterface {
    return new utils.Interface(_abi) as IERC1155ContractTransferInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): IERC1155ContractTransfer {
    return new Contract(
      address,
      _abi,
      signerOrProvider
    ) as IERC1155ContractTransfer;
  }
}
