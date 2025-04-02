/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../common";
import type {
  DiamondLoupeFacet,
  DiamondLoupeFacetInterface,
} from "../../../facets/Diamond/DiamondLoupeFacet";

const _abi = [
  {
    inputs: [
      {
        internalType: "bytes4",
        name: "_functionSelector",
        type: "bytes4",
      },
    ],
    name: "facetAddress",
    outputs: [
      {
        internalType: "address",
        name: "facetAddress_",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "facetAddresses",
    outputs: [
      {
        internalType: "address[]",
        name: "facetAddresses_",
        type: "address[]",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_facet",
        type: "address",
      },
    ],
    name: "facetFunctionSelectors",
    outputs: [
      {
        internalType: "bytes4[]",
        name: "facetFunctionSelectors_",
        type: "bytes4[]",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "facets",
    outputs: [
      {
        components: [
          {
            internalType: "address",
            name: "facetAddress",
            type: "address",
          },
          {
            internalType: "bytes4[]",
            name: "functionSelectors",
            type: "bytes4[]",
          },
        ],
        internalType: "struct IDiamondLoupe.Facet[]",
        name: "facets_",
        type: "tuple[]",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes4",
        name: "_interfaceId",
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
  "0x6080604052348015600e575f5ffd5b506106398061001c5f395ff3fe608060405234801561000f575f5ffd5b5060043610610055575f3560e01c806301ffc9a71461005957806352ef6b2c146100b95780637a0ed627146100ce578063adfca15e146100e3578063cdffacc614610103575b5f5ffd5b6100a4610067366004610443565b6001600160e01b0319165f9081527fc8fcad8db84d3cc18b4c41d551ea0ee66dd599cde068d998e57d5e09332c131f602052604090205460ff1690565b60405190151581526020015b60405180910390f35b6100c1610159565b6040516100b09190610471565b6100d66101c8565b6040516100b09190610500565b6100f66100f1366004610583565b61037c565b6040516100b091906105a9565b610141610111366004610443565b6001600160e01b0319165f9081525f5160206105e45f395f51905f5260205260409020546001600160a01b031690565b6040516001600160a01b0390911681526020016100b0565b60605f5f5160206105e45f395f51905f52600281018054604080516020808402820181019092528281529394508301828280156101bd57602002820191905f5260205f20905b81546001600160a01b0316815260019091019060200180831161019f575b505050505091505090565b7fc8fcad8db84d3cc18b4c41d551ea0ee66dd599cde068d998e57d5e09332c131e546060905f5160206105e45f395f51905f52908067ffffffffffffffff811115610215576102156105bb565b60405190808252806020026020018201604052801561025a57816020015b604080518082019091525f8152606060208201528152602001906001900390816102335790505b5092505f5b81811015610376575f83600201828154811061027d5761027d6105cf565b905f5260205f20015f9054906101000a90046001600160a01b03169050808583815181106102ad576102ad6105cf565b6020908102919091018101516001600160a01b0392831690529082165f9081526001860182526040908190208054825181850281018501909352808352919290919083018282801561034857602002820191905f5260205f20905f905b82829054906101000a900460e01b6001600160e01b0319168152602001906004019060208260030104928301926001038202915080841161030a5790505b505050505085838151811061035f5761035f6105cf565b60209081029190910181015101525060010161025f565b50505090565b6001600160a01b0381165f9081527fc8fcad8db84d3cc18b4c41d551ea0ee66dd599cde068d998e57d5e09332c131d602090815260409182902080548351818402810184019094528084526060935f5160206105e45f395f51905f52939092919083018282801561043657602002820191905f5260205f20905f905b82829054906101000a900460e01b6001600160e01b031916815260200190600401906020826003010492830192600103820291508084116103f85790505b5050505050915050919050565b5f60208284031215610453575f5ffd5b81356001600160e01b03198116811461046a575f5ffd5b9392505050565b602080825282518282018190525f918401906040840190835b818110156104b15783516001600160a01b031683526020938401939092019160010161048a565b509095945050505050565b5f8151808452602084019350602083015f5b828110156104f65781516001600160e01b0319168652602095860195909101906001016104ce565b5093949350505050565b5f602082016020835280845180835260408501915060408160051b8601019250602086015f5b8281101561057757868503603f19018452815180516001600160a01b03168652602090810151604091870182905290610561908701826104bc565b9550506020938401939190910190600101610526565b50929695505050505050565b5f60208284031215610593575f5ffd5b81356001600160a01b038116811461046a575f5ffd5b602081525f61046a60208301846104bc565b634e487b7160e01b5f52604160045260245ffd5b634e487b7160e01b5f52603260045260245ffdfec8fcad8db84d3cc18b4c41d551ea0ee66dd599cde068d998e57d5e09332c131ca264697066735822122038454de000fca3c917eb5966cd88fbdc95529dbfbe5f8b7dd78e5ffd86e02cde64736f6c634300081c0033";

type DiamondLoupeFacetConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: DiamondLoupeFacetConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class DiamondLoupeFacet__factory extends ContractFactory {
  constructor(...args: DiamondLoupeFacetConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<DiamondLoupeFacet> {
    return super.deploy(overrides || {}) as Promise<DiamondLoupeFacet>;
  }
  override getDeployTransaction(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  override attach(address: string): DiamondLoupeFacet {
    return super.attach(address) as DiamondLoupeFacet;
  }
  override connect(signer: Signer): DiamondLoupeFacet__factory {
    return super.connect(signer) as DiamondLoupeFacet__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): DiamondLoupeFacetInterface {
    return new utils.Interface(_abi) as DiamondLoupeFacetInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): DiamondLoupeFacet {
    return new Contract(address, _abi, signerOrProvider) as DiamondLoupeFacet;
  }
}
