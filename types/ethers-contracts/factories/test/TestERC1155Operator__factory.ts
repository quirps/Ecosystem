/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../common";
import type {
  TestERC1155Operator,
  TestERC1155OperatorInterface,
} from "../../test/TestERC1155Operator";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "_diamond",
        type: "address",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        internalType: "address",
        name: "from",
        type: "address",
      },
      {
        internalType: "uint256[]",
        name: "id",
        type: "uint256[]",
      },
      {
        internalType: "uint256[]",
        name: "amount",
        type: "uint256[]",
      },
      {
        internalType: "bytes",
        name: "data",
        type: "bytes",
      },
    ],
    name: "safeBatchTransferFrom",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "to",
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
        name: "amount",
        type: "uint256",
      },
      {
        internalType: "bytes",
        name: "data",
        type: "bytes",
      },
    ],
    name: "safeTransferFrom",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;

const _bytecode =
  "0x60a060405234801561001057600080fd5b5060405161093c38038061093c833981810160405281019061003291906100cf565b8073ffffffffffffffffffffffffffffffffffffffff1660808173ffffffffffffffffffffffffffffffffffffffff1681525050506100fc565b600080fd5b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b600061009c82610071565b9050919050565b6100ac81610091565b81146100b757600080fd5b50565b6000815190506100c9816100a3565b92915050565b6000602082840312156100e5576100e461006c565b5b60006100f3848285016100ba565b91505092915050565b60805161081f61011d600039600081816075015261010f015261081f6000f3fe608060405234801561001057600080fd5b50600436106100365760003560e01c80632eb2c2d61461003b578063f242432a14610057575b600080fd5b6100556004803603810190610050919061045d565b610073565b005b610071600480360381019061006c919061052c565b61010d565b005b7f000000000000000000000000000000000000000000000000000000000000000073ffffffffffffffffffffffffffffffffffffffff16632eb2c2d686868686866040518663ffffffff1660e01b81526004016100d4959493929190610718565b600060405180830381600087803b1580156100ee57600080fd5b505af1158015610102573d6000803e3d6000fd5b505050505050505050565b7f000000000000000000000000000000000000000000000000000000000000000073ffffffffffffffffffffffffffffffffffffffff1663f242432a86868686866040518663ffffffff1660e01b815260040161016e95949392919061078f565b600060405180830381600087803b15801561018857600080fd5b505af115801561019c573d6000803e3d6000fd5b505050505050505050565b6000604051905090565b600080fd5b600080fd5b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b60006101e6826101bb565b9050919050565b6101f6816101db565b811461020157600080fd5b50565b600081359050610213816101ed565b92915050565b600080fd5b6000601f19601f8301169050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b6102678261021e565b810181811067ffffffffffffffff821117156102865761028561022f565b5b80604052505050565b60006102996101a7565b90506102a5828261025e565b919050565b600067ffffffffffffffff8211156102c5576102c461022f565b5b602082029050602081019050919050565b600080fd5b6000819050919050565b6102ee816102db565b81146102f957600080fd5b50565b60008135905061030b816102e5565b92915050565b600061032461031f846102aa565b61028f565b90508083825260208201905060208402830185811115610347576103466102d6565b5b835b81811015610370578061035c88826102fc565b845260208401935050602081019050610349565b5050509392505050565b600082601f83011261038f5761038e610219565b5b813561039f848260208601610311565b91505092915050565b600080fd5b600067ffffffffffffffff8211156103c8576103c761022f565b5b6103d18261021e565b9050602081019050919050565b82818337600083830152505050565b60006104006103fb846103ad565b61028f565b90508281526020810184848401111561041c5761041b6103a8565b5b6104278482856103de565b509392505050565b600082601f83011261044457610443610219565b5b81356104548482602086016103ed565b91505092915050565b600080600080600060a08688031215610479576104786101b1565b5b600061048788828901610204565b955050602061049888828901610204565b945050604086013567ffffffffffffffff8111156104b9576104b86101b6565b5b6104c58882890161037a565b935050606086013567ffffffffffffffff8111156104e6576104e56101b6565b5b6104f28882890161037a565b925050608086013567ffffffffffffffff811115610513576105126101b6565b5b61051f8882890161042f565b9150509295509295909350565b600080600080600060a08688031215610548576105476101b1565b5b600061055688828901610204565b955050602061056788828901610204565b9450506040610578888289016102fc565b9350506060610589888289016102fc565b925050608086013567ffffffffffffffff8111156105aa576105a96101b6565b5b6105b68882890161042f565b9150509295509295909350565b6105cc816101db565b82525050565b600081519050919050565b600082825260208201905092915050565b6000819050602082019050919050565b610607816102db565b82525050565b600061061983836105fe565b60208301905092915050565b6000602082019050919050565b600061063d826105d2565b61064781856105dd565b9350610652836105ee565b8060005b8381101561068357815161066a888261060d565b975061067583610625565b925050600181019050610656565b5085935050505092915050565b600081519050919050565b600082825260208201905092915050565b60005b838110156106ca5780820151818401526020810190506106af565b838111156106d9576000848401525b50505050565b60006106ea82610690565b6106f4818561069b565b93506107048185602086016106ac565b61070d8161021e565b840191505092915050565b600060a08201905061072d60008301886105c3565b61073a60208301876105c3565b818103604083015261074c8186610632565b905081810360608301526107608185610632565b9050818103608083015261077481846106df565b90509695505050505050565b610789816102db565b82525050565b600060a0820190506107a460008301886105c3565b6107b160208301876105c3565b6107be6040830186610780565b6107cb6060830185610780565b81810360808301526107dd81846106df565b9050969550505050505056fea26469706673582212204b863583f5c7f786992856425e90329628a9859063d455f632626b8ead39b35264736f6c63430008090033";

type TestERC1155OperatorConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: TestERC1155OperatorConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class TestERC1155Operator__factory extends ContractFactory {
  constructor(...args: TestERC1155OperatorConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    _diamond: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<TestERC1155Operator> {
    return super.deploy(
      _diamond,
      overrides || {}
    ) as Promise<TestERC1155Operator>;
  }
  override getDeployTransaction(
    _diamond: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(_diamond, overrides || {});
  }
  override attach(address: string): TestERC1155Operator {
    return super.attach(address) as TestERC1155Operator;
  }
  override connect(signer: Signer): TestERC1155Operator__factory {
    return super.connect(signer) as TestERC1155Operator__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): TestERC1155OperatorInterface {
    return new utils.Interface(_abi) as TestERC1155OperatorInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): TestERC1155Operator {
    return new Contract(address, _abi, signerOrProvider) as TestERC1155Operator;
  }
}
