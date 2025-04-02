/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import {
  Signer,
  utils,
  Contract,
  ContractFactory,
  BytesLike,
  Overrides,
} from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../common";
import type {
  DiamondDeploy,
  DiamondDeployInterface,
} from "../../../deploy/diamondDeploy.sol/DiamondDeploy";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "registry",
        type: "address",
      },
      {
        internalType: "bytes",
        name: "_bytecode",
        type: "bytes",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "owner",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_salt",
        type: "uint256",
      },
      {
        internalType: "bytes",
        name: "_bytecode",
        type: "bytes",
      },
      {
        components: [
          {
            internalType: "address",
            name: "facetAddress",
            type: "address",
          },
          {
            internalType: "enum IDiamondCut.FacetCutAction",
            name: "action",
            type: "uint8",
          },
          {
            internalType: "bytes4[]",
            name: "functionSelectors",
            type: "bytes4[]",
          },
        ],
        internalType: "struct IDiamondCut.FacetCut[]",
        name: "_facetCuts",
        type: "tuple[]",
      },
    ],
    name: "deploy",
    outputs: [
      {
        internalType: "address",
        name: "diamond_",
        type: "address",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "registryAddress",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
] as const;

const _bytecode =
  "0x60806040525f805460ff60a01b1916905534801561001b575f5ffd5b5060405161077a38038061077a83398101604081905261003a9161007e565b5f80546001600160a01b0319166001600160a01b039390931692909217909155805160209091012060015561014d565b634e487b7160e01b5f52604160045260245ffd5b5f5f6040838503121561008f575f5ffd5b82516001600160a01b03811681146100a5575f5ffd5b60208401519092506001600160401b038111156100c0575f5ffd5b8301601f810185136100d0575f5ffd5b80516001600160401b038111156100e9576100e961006a565b604051601f8201601f19908116603f011681016001600160401b03811182821017156101175761011761006a565b60405281815282820160200187101561012e575f5ffd5b8160208401602083015e5f602083830101528093505050509250929050565b6106208061015a5f395ff3fe608060405234801561000f575f5ffd5b5060043610610034575f3560e01c8063ed9aab5114610038578063f4615e3b14610066575b5f5ffd5b5f5461004a906001600160a01b031681565b6040516001600160a01b03909116815260200160405180910390f35b61004a6100743660046103bf565b5f5f6001548585604051610089929190610471565b6040518091039020146101175760405162461bcd60e51b815260206004820152604660248201527f42797465636f6465206d757374206d617463682074686174206f66207468652060448201527f4469616d6f6e64206173736f6369617465642077697468207468697320636f6e6064820152653a3930b1ba1760d11b608482015260a40160405180910390fd5b5f87338560405160200161012d93929190610480565b60405160208183030381529060405290505f86868360405160200161015493929190610599565b60405160208183030381529060405290505f33898460405160200161017b939291906105b8565b604051602081830303815290604052805190602001209050808251602084015ff59350833b6101a8575f5ffd5b509198975050505050505050565b80356001600160a01b03811681146101cc575f5ffd5b919050565b634e487b7160e01b5f52604160045260245ffd5b6040516060810167ffffffffffffffff81118282101715610208576102086101d1565b60405290565b604051601f8201601f1916810167ffffffffffffffff81118282101715610237576102376101d1565b604052919050565b5f67ffffffffffffffff821115610258576102586101d1565b5060051b60200190565b5f82601f830112610271575f5ffd5b813561028461027f8261023f565b61020e565b8082825260208201915060208360051b8601019250858311156102a5575f5ffd5b602085015b838110156103b557803567ffffffffffffffff8111156102c8575f5ffd5b86016060818903601f190112156102dd575f5ffd5b6102e56101e5565b6102f1602083016101b6565b8152604082013560038110610304575f5ffd5b6020820152606082013567ffffffffffffffff811115610322575f5ffd5b60208184010192505088601f830112610339575f5ffd5b813561034761027f8261023f565b8082825260208201915060208360051b86010192508b831115610368575f5ffd5b6020850194505b8285101561039f5784356001600160e01b03198116811461038e575f5ffd5b82526020948501949091019061036f565b60408401525050845250602092830192016102aa565b5095945050505050565b5f5f5f5f5f608086880312156103d3575f5ffd5b6103dc866101b6565b945060208601359350604086013567ffffffffffffffff8111156103fe575f5ffd5b8601601f8101881361040e575f5ffd5b803567ffffffffffffffff811115610424575f5ffd5b886020828401011115610435575f5ffd5b60209190910193509150606086013567ffffffffffffffff811115610458575f5ffd5b61046488828901610262565b9150509295509295909350565b818382375f9101908152919050565b6001600160a01b038481168252831660208083019190915260606040830181905283519083018190525f916080600583901b8501810192908501918601845b8281101561057457868503607f19018452815180516001600160a01b03168652602081015160608701906003811061050557634e487b7160e01b5f52602160045260245ffd5b8060208901525060408201519150606060408801528082518083526080890191506020840193505f92505b8083101561055c5783516001600160e01b03191682526020938401936001939093019290910190610530565b509650505060209384019391909101906001016104bf565b509298975050505050505050565b5f81518060208401855e5f93019283525090919050565b828482375f8382015f81526105ae8185610582565b9695505050505050565b6bffffffffffffffffffffffff198460601b1681528260148201525f6105e16034830184610582565b9594505050505056fea26469706673582212203fc7ae23b8e0b14d1582f07038dea7a70f167fcb7c56715cf80bc129cd8e8bda64736f6c634300081c0033";

type DiamondDeployConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: DiamondDeployConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class DiamondDeploy__factory extends ContractFactory {
  constructor(...args: DiamondDeployConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    registry: PromiseOrValue<string>,
    _bytecode: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<DiamondDeploy> {
    return super.deploy(
      registry,
      _bytecode,
      overrides || {}
    ) as Promise<DiamondDeploy>;
  }
  override getDeployTransaction(
    registry: PromiseOrValue<string>,
    _bytecode: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(registry, _bytecode, overrides || {});
  }
  override attach(address: string): DiamondDeploy {
    return super.attach(address) as DiamondDeploy;
  }
  override connect(signer: Signer): DiamondDeploy__factory {
    return super.connect(signer) as DiamondDeploy__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): DiamondDeployInterface {
    return new utils.Interface(_abi) as DiamondDeployInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): DiamondDeploy {
    return new Contract(address, _abi, signerOrProvider) as DiamondDeploy;
  }
}
