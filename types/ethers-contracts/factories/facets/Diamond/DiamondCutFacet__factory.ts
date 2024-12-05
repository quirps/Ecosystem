/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../common";
import type {
  DiamondCutFacet,
  DiamondCutFacetInterface,
} from "../../../facets/Diamond/DiamondCutFacet";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "_initializationContractAddress",
        type: "address",
      },
      {
        internalType: "bytes",
        name: "_calldata",
        type: "bytes",
      },
    ],
    name: "InitializationFunctionReverted",
    type: "error",
  },
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
        indexed: false,
        internalType: "struct IDiamondCut.FacetCut[]",
        name: "_diamondCut",
        type: "tuple[]",
      },
      {
        indexed: false,
        internalType: "address",
        name: "_init",
        type: "address",
      },
      {
        indexed: false,
        internalType: "bytes",
        name: "_calldata",
        type: "bytes",
      },
    ],
    name: "DiamondCut",
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
    inputs: [],
    name: "cancelMigration",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
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
        name: "_diamondCut",
        type: "tuple[]",
      },
      {
        internalType: "address",
        name: "_init",
        type: "address",
      },
      {
        internalType: "bytes",
        name: "_calldata",
        type: "bytes",
      },
    ],
    name: "diamondCut",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "initiateMigration",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;

const _bytecode =
  "0x608060405234801561001057600080fd5b50612b39806100206000396000f3fe608060405234801561001057600080fd5b50600436106100415760003560e01c806310639ea0146100465780631f931c1c146100505780635f4d49071461006c575b600080fd5b61004e610076565b005b61006a60048036038101906100659190611afb565b610088565b005b6100746100f2565b005b61007e610104565b610086610182565b565b61009061029f565b6100eb8585906100a09190611e99565b8484848080601f016020809104026020016040519081016040528093929190818152602001838380828437600081840152601f19601f8201169050808301925050505050505061042b565b5050505050565b6100fa610104565b61010261065d565b565b61010c61073e565b73ffffffffffffffffffffffffffffffffffffffff1661012a61074d565b73ffffffffffffffffffffffffffffffffffffffff1614610180576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161017790611f0b565b60405180910390fd5b565b600061018c61075c565b9050600081600201905060008160000160019054906101000a900463ffffffff1690508160000160009054906101000a900460ff1615610268576101cf81610789565b15610206576040517f3dbff3b500000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b60008260000160006101000a81548160ff0219169083151502179055507f0125003cabc73e492b36c5de7e1bada2b3ed6f148993ac56437d449c0e184df161024c61074d565b4260405161025b929190611f59565b60405180910390a161029a565b6040517fd82c3ca200000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b505050565b60006102a961075c565b905060008160020190508060000160009054906101000a900460ff1680156102ea57506102e98160000160019054906101000a900463ffffffff16610789565b5b1561038d578160000160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1661033261074d565b73ffffffffffffffffffffffffffffffffffffffff1614610388576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161037f90611fce565b60405180910390fd5b610427565b8160010160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff166103d061074d565b73ffffffffffffffffffffffffffffffffffffffff1614610426576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161041d90612060565b60405180910390fd5b5b5050565b60005b835181101561061257600084828151811061044c5761044b612080565b5b60200260200101516020015190506000600281111561046e5761046d6120af565b5b816002811115610481576104806120af565b5b14156104d2576104cd85838151811061049d5761049c612080565b5b6020026020010151600001518684815181106104bc576104bb612080565b5b6020026020010151604001516107b4565b6105fe565b600160028111156104e6576104e56120af565b5b8160028111156104f9576104f86120af565b5b141561054a5761054585838151811061051557610514612080565b5b60200260200101516000015186848151811061053457610533612080565b5b602002602001015160400151610a2d565b6105fd565b60028081111561055d5761055c6120af565b5b8160028111156105705761056f6120af565b5b14156105c1576105bc85838151811061058c5761058b612080565b5b6020026020010151600001518684815181106105ab576105aa612080565b5b602002602001015160400151610cb1565b6105fc565b6040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016105f390612150565b60405180910390fd5b5b5b50808061060a906121a9565b91505061042e565b507f8faa70878671ccd212d20771b795c50af8fd3ff6cf27f4bde57e5d4de0aeb673838383604051610646939291906124a1565b60405180910390a16106588282610e3c565b505050565b600061066761075c565b905060008160020190508060000160009054906101000a900460ff16156106ba576040517ff86b5bf500000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b60018160000160006101000a81548160ff021916908315150217905550428160000160016101000a81548163ffffffff021916908363ffffffff1602179055507fe84f152d8e8204dc46b1e48a81ce1ef3b594249669bf602c4b4defbe7b7fa9a961072361074d565b42604051610732929190611f59565b60405180910390a15050565b6000610748610f63565b905090565b6000610757610f96565b905090565b6000807fd00049dc7109015045860694acecd3dc33338404aaf6e55a1c98a2bf41477b8590508091505090565b60008163ffffffff166203f48062ffffff16426107a691906124e6565b63ffffffff16119050919050565b60008151116107f8576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016107ef90612592565b60405180910390fd5b6000610802610fcd565b9050600073ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff161415610874576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161086b90612624565b60405180910390fd5b60008160010160008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206000018054905090506000816bffffffffffffffffffffffff1614156108e2576108e18285610ffa565b5b60005b8351811015610a2657600084828151811061090357610902612080565b5b602002602001015190506000846000016000837bffffffffffffffffffffffffffffffffffffffffffffffffffffffff19167bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916815260200190815260200160002060000160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff169050600073ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff16146109f7576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016109ee906126b6565b60405180910390fd5b610a038583868a6110d5565b8380610a0e906126ee565b94505050508080610a1e906121a9565b9150506108e5565b5050505050565b6000815111610a71576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610a6890612592565b60405180910390fd5b6000610a7b610fcd565b9050600073ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff161415610aed576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610ae490612624565b60405180910390fd5b60008160010160008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206000018054905090506000816bffffffffffffffffffffffff161415610b5b57610b5a8285610ffa565b5b60005b8351811015610caa576000848281518110610b7c57610b7b612080565b5b602002602001015190506000846000016000837bffffffffffffffffffffffffffffffffffffffffffffffffffffffff19167bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916815260200190815260200160002060000160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1690508673ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff161415610c70576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610c6790612795565b60405180910390fd5b610c7b858284611282565b610c878583868a6110d5565b8380610c92906126ee565b94505050508080610ca2906121a9565b915050610b5e565b5050505050565b6000815111610cf5576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610cec90612592565b60405180910390fd5b6000610cff610fcd565b9050600073ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff1614610d70576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610d6790612827565b60405180910390fd5b60005b8251811015610e36576000838281518110610d9157610d90612080565b5b602002602001015190506000836000016000837bffffffffffffffffffffffffffffffffffffffffffffffffffffffff19167bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916815260200190815260200160002060000160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff169050610e21848284611282565b50508080610e2e906121a9565b915050610d73565b50505050565b600073ffffffffffffffffffffffffffffffffffffffff168273ffffffffffffffffffffffffffffffffffffffff161415610e7657610f5f565b610e9882604051806060016040528060288152602001612ab8602891396118e7565b6000808373ffffffffffffffffffffffffffffffffffffffff1683604051610ec09190612883565b600060405180830381855af49150503d8060008114610efb576040519150601f19603f3d011682016040523d82523d6000602084013e610f00565b606091505b509150915081610f5c57600081511115610f1d5780518082602001fd5b83836040517f192105d7000000000000000000000000000000000000000000000000000000008152600401610f5392919061289a565b60405180910390fd5b50505b5050565b6000610f6d61075c565b60000160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff16905090565b60006014600036905010158015610fb25750610fb133611939565b5b15610fc657601436033560601c9050610fca565b3390505b90565b6000807fc8fcad8db84d3cc18b4c41d551ea0ee66dd599cde068d998e57d5e09332c131c90508091505090565b61101c81604051806060016040528060248152602001612ae0602491396118e7565b81600201805490508260010160008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206001018190555081600201819080600181540180825580915050600190039060005260206000200160009091909190916101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055505050565b81846000016000857bffffffffffffffffffffffffffffffffffffffffffffffffffffffff19167bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916815260200190815260200160002060000160146101000a8154816bffffffffffffffffffffffff02191690836bffffffffffffffffffffffff1602179055508360010160008273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206000018390806001815401808255809150506001900390600052602060002090600891828204019190066004029091909190916101000a81548163ffffffff021916908360e01c021790555080846000016000857bffffffffffffffffffffffffffffffffffffffffffffffffffffffff19167bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916815260200190815260200160002060000160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555050505050565b600073ffffffffffffffffffffffffffffffffffffffff168273ffffffffffffffffffffffffffffffffffffffff1614156112f2576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016112e99061293c565b60405180910390fd5b3073ffffffffffffffffffffffffffffffffffffffff168273ffffffffffffffffffffffffffffffffffffffff161415611361576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401611358906129ce565b60405180910390fd5b6000836000016000837bffffffffffffffffffffffffffffffffffffffffffffffffffffffff19167bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916815260200190815260200160002060000160149054906101000a90046bffffffffffffffffffffffff166bffffffffffffffffffffffff169050600060018560010160008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206000018054905061143891906129ee565b90508082146115cc5760008560010160008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020600001828154811061149957611498612080565b5b90600052602060002090600891828204019190066004029054906101000a900460e01b9050808660010160008773ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020600001848154811061151557611514612080565b5b90600052602060002090600891828204019190066004026101000a81548163ffffffff021916908360e01c021790555082866000016000837bffffffffffffffffffffffffffffffffffffffffffffffffffffffff19167bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916815260200190815260200160002060000160146101000a8154816bffffffffffffffffffffffff02191690836bffffffffffffffffffffffff160217905550505b8460010160008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206000018054806116205761161f612a22565b5b60019003818190600052602060002090600891828204019190066004026101000a81549063ffffffff02191690559055846000016000847bffffffffffffffffffffffffffffffffffffffffffffffffffffffff19167bffffffffffffffffffffffffffffffffffffffffffffffffffffffff19168152602001908152602001600020600080820160006101000a81549073ffffffffffffffffffffffffffffffffffffffff02191690556000820160146101000a8154906bffffffffffffffffffffffff0219169055505060008114156118e05760006001866002018054905061170b91906129ee565b905060008660010160008773ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060010154905081811461184c57600087600201838154811061177557611774612080565b5b9060005260206000200160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff169050808860020183815481106117b9576117b8612080565b5b9060005260206000200160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550818860010160008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060010181905550505b866002018054806118605761185f612a22565b5b6001900381819060005260206000200160006101000a81549073ffffffffffffffffffffffffffffffffffffffff021916905590558660010160008773ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206001016000905550505b5050505050565b6000823b9050600081118290611933576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161192a9190612a95565b60405180910390fd5b50505050565b6000806119446119a1565b90508060000160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff1614915050919050565b6000807f413a4c31c13c7c3de0c7da37be5d779b152baf3f21a1cb760fda41eb8ca9777690508091505090565b6000604051905090565b600080fd5b600080fd5b600080fd5b600080fd5b600080fd5b60008083601f840112611a0757611a066119e2565b5b8235905067ffffffffffffffff811115611a2457611a236119e7565b5b602083019150836020820283011115611a4057611a3f6119ec565b5b9250929050565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000611a7282611a47565b9050919050565b611a8281611a67565b8114611a8d57600080fd5b50565b600081359050611a9f81611a79565b92915050565b60008083601f840112611abb57611aba6119e2565b5b8235905067ffffffffffffffff811115611ad857611ad76119e7565b5b602083019150836001820283011115611af457611af36119ec565b5b9250929050565b600080600080600060608688031215611b1757611b166119d8565b5b600086013567ffffffffffffffff811115611b3557611b346119dd565b5b611b41888289016119f1565b95509550506020611b5488828901611a90565b935050604086013567ffffffffffffffff811115611b7557611b746119dd565b5b611b8188828901611aa5565b92509250509295509295909350565b6000601f19601f8301169050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b611bd982611b90565b810181811067ffffffffffffffff82111715611bf857611bf7611ba1565b5b80604052505050565b6000611c0b6119ce565b9050611c178282611bd0565b919050565b600067ffffffffffffffff821115611c3757611c36611ba1565b5b602082029050602081019050919050565b600080fd5b600080fd5b60038110611c5f57600080fd5b50565b600081359050611c7181611c52565b92915050565b600067ffffffffffffffff821115611c9257611c91611ba1565b5b602082029050602081019050919050565b60007fffffffff0000000000000000000000000000000000000000000000000000000082169050919050565b611cd881611ca3565b8114611ce357600080fd5b50565b600081359050611cf581611ccf565b92915050565b6000611d0e611d0984611c77565b611c01565b90508083825260208201905060208402830185811115611d3157611d306119ec565b5b835b81811015611d5a5780611d468882611ce6565b845260208401935050602081019050611d33565b5050509392505050565b600082601f830112611d7957611d786119e2565b5b8135611d89848260208601611cfb565b91505092915050565b600060608284031215611da857611da7611c48565b5b611db26060611c01565b90506000611dc284828501611a90565b6000830152506020611dd684828501611c62565b602083015250604082013567ffffffffffffffff811115611dfa57611df9611c4d565b5b611e0684828501611d64565b60408301525092915050565b6000611e25611e2084611c1c565b611c01565b90508083825260208201905060208402830185811115611e4857611e476119ec565b5b835b81811015611e8f57803567ffffffffffffffff811115611e6d57611e6c6119e2565b5b808601611e7a8982611d92565b85526020850194505050602081019050611e4a565b5050509392505050565b6000611ea6368484611e12565b905092915050565b600082825260208201905092915050565b7f4d757374206265207468652045636f73797374656d206f776e65720000000000600082015250565b6000611ef5601b83611eae565b9150611f0082611ebf565b602082019050919050565b60006020820190508181036000830152611f2481611ee8565b9050919050565b611f3481611a67565b82525050565b600063ffffffff82169050919050565b611f5381611f3a565b82525050565b6000604082019050611f6e6000830185611f2b565b611f7b6020830184611f4a565b9392505050565b7f53656e646572206d75737420626520746865206f776e65722e00000000000000600082015250565b6000611fb8601983611eae565b9150611fc382611f82565b602082019050919050565b60006020820190508181036000830152611fe781611fab565b9050919050565b7f53656e646572206d7573742062652066726f6d2074686520726567697374727960008201527f2e00000000000000000000000000000000000000000000000000000000000000602082015250565b600061204a602183611eae565b915061205582611fee565b604082019050919050565b600060208201905081810360008301526120798161203d565b9050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052603260045260246000fd5b7f4e487b7100000000000000000000000000000000000000000000000000000000600052602160045260246000fd5b7f4c69624469616d6f6e644375743a20496e636f7272656374204661636574437560008201527f74416374696f6e00000000000000000000000000000000000000000000000000602082015250565b600061213a602783611eae565b9150612145826120de565b604082019050919050565b600060208201905081810360008301526121698161212d565b9050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b6000819050919050565b60006121b48261219f565b91507fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff8214156121e7576121e6612170565b5b600182019050919050565b600081519050919050565b600082825260208201905092915050565b6000819050602082019050919050565b61222781611a67565b82525050565b6003811061223e5761223d6120af565b5b50565b600081905061224f8261222d565b919050565b600061225f82612241565b9050919050565b61226f81612254565b82525050565b600081519050919050565b600082825260208201905092915050565b6000819050602082019050919050565b6122aa81611ca3565b82525050565b60006122bc83836122a1565b60208301905092915050565b6000602082019050919050565b60006122e082612275565b6122ea8185612280565b93506122f583612291565b8060005b8381101561232657815161230d88826122b0565b9750612318836122c8565b9250506001810190506122f9565b5085935050505092915050565b600060608301600083015161234b600086018261221e565b50602083015161235e6020860182612266565b506040830151848203604086015261237682826122d5565b9150508091505092915050565b600061238f8383612333565b905092915050565b6000602082019050919050565b60006123af826121f2565b6123b981856121fd565b9350836020820285016123cb8561220e565b8060005b8581101561240757848403895281516123e88582612383565b94506123f383612397565b925060208a019950506001810190506123cf565b50829750879550505050505092915050565b600081519050919050565b600082825260208201905092915050565b60005b83811015612453578082015181840152602081019050612438565b83811115612462576000848401525b50505050565b600061247382612419565b61247d8185612424565b935061248d818560208601612435565b61249681611b90565b840191505092915050565b600060608201905081810360008301526124bb81866123a4565b90506124ca6020830185611f2b565b81810360408301526124dc8184612468565b9050949350505050565b60006124f182611f3a565b91506124fc83611f3a565b92508263ffffffff0382111561251557612514612170565b5b828201905092915050565b7f4c69624469616d6f6e644375743a204e6f2073656c6563746f727320696e206660008201527f6163657420746f20637574000000000000000000000000000000000000000000602082015250565b600061257c602b83611eae565b915061258782612520565b604082019050919050565b600060208201905081810360008301526125ab8161256f565b9050919050565b7f4c69624469616d6f6e644375743a204164642066616365742063616e2774206260008201527f6520616464726573732830290000000000000000000000000000000000000000602082015250565b600061260e602c83611eae565b9150612619826125b2565b604082019050919050565b6000602082019050818103600083015261263d81612601565b9050919050565b7f4c69624469616d6f6e644375743a2043616e2774206164642066756e6374696f60008201527f6e207468617420616c7265616479206578697374730000000000000000000000602082015250565b60006126a0603583611eae565b91506126ab82612644565b604082019050919050565b600060208201905081810360008301526126cf81612693565b9050919050565b60006bffffffffffffffffffffffff82169050919050565b60006126f9826126d6565b91506bffffffffffffffffffffffff82141561271857612717612170565b5b600182019050919050565b7f4c69624469616d6f6e644375743a2043616e2774207265706c6163652066756e60008201527f6374696f6e20776974682073616d652066756e6374696f6e0000000000000000602082015250565b600061277f603883611eae565b915061278a82612723565b604082019050919050565b600060208201905081810360008301526127ae81612772565b9050919050565b7f4c69624469616d6f6e644375743a2052656d6f7665206661636574206164647260008201527f657373206d757374206265206164647265737328302900000000000000000000602082015250565b6000612811603683611eae565b915061281c826127b5565b604082019050919050565b6000602082019050818103600083015261284081612804565b9050919050565b600081905092915050565b600061285d82612419565b6128678185612847565b9350612877818560208601612435565b80840191505092915050565b600061288f8284612852565b915081905092915050565b60006040820190506128af6000830185611f2b565b81810360208301526128c18184612468565b90509392505050565b7f4c69624469616d6f6e644375743a2043616e27742072656d6f76652066756e6360008201527f74696f6e207468617420646f65736e2774206578697374000000000000000000602082015250565b6000612926603783611eae565b9150612931826128ca565b604082019050919050565b6000602082019050818103600083015261295581612919565b9050919050565b7f4c69624469616d6f6e644375743a2043616e27742072656d6f766520696d6d7560008201527f7461626c652066756e6374696f6e000000000000000000000000000000000000602082015250565b60006129b8602e83611eae565b91506129c38261295c565b604082019050919050565b600060208201905081810360008301526129e7816129ab565b9050919050565b60006129f98261219f565b9150612a048361219f565b925082821015612a1757612a16612170565b5b828203905092915050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052603160045260246000fd5b600081519050919050565b6000612a6782612a51565b612a718185611eae565b9350612a81818560208601612435565b612a8a81611b90565b840191505092915050565b60006020820190508181036000830152612aaf8184612a5c565b90509291505056fe4c69624469616d6f6e644375743a205f696e6974206164647265737320686173206e6f20636f64654c69624469616d6f6e644375743a204e657720666163657420686173206e6f20636f6465a2646970667358221220ab8e8a011bbe8d06eabd4e82a92f0cc4f47af7623de963b8f1e5a6f66c1db14764736f6c63430008090033";

type DiamondCutFacetConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: DiamondCutFacetConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class DiamondCutFacet__factory extends ContractFactory {
  constructor(...args: DiamondCutFacetConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<DiamondCutFacet> {
    return super.deploy(overrides || {}) as Promise<DiamondCutFacet>;
  }
  override getDeployTransaction(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  override attach(address: string): DiamondCutFacet {
    return super.attach(address) as DiamondCutFacet;
  }
  override connect(signer: Signer): DiamondCutFacet__factory {
    return super.connect(signer) as DiamondCutFacet__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): DiamondCutFacetInterface {
    return new utils.Interface(_abi) as DiamondCutFacetInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): DiamondCutFacet {
    return new Contract(address, _abi, signerOrProvider) as DiamondCutFacet;
  }
}
