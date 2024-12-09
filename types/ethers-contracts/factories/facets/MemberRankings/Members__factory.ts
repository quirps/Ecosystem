/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../common";
import type {
  Members,
  MembersInterface,
} from "../../../facets/MemberRankings/Members";

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
        name: "amount",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "enum iMembers.BountyAccountChange",
        name: "direction",
        type: "uint8",
      },
    ],
    name: "BountyBalanceChange",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "receiver",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "bountyUp",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "bountyUpRate",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "bountiesDown",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "bountyDownRate",
        type: "uint256",
      },
    ],
    name: "BountyEvent",
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
  {
    inputs: [
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "addBountyBalance",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "bountyAddress",
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
  {
    inputs: [],
    name: "currencyId",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "downRate",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "getBounty",
    outputs: [
      {
        components: [
          {
            internalType: "uint256",
            name: "currencyId",
            type: "uint256",
          },
          {
            internalType: "uint256",
            name: "maxBalance",
            type: "uint256",
          },
          {
            internalType: "address",
            name: "bountyAddress",
            type: "address",
          },
          {
            internalType: "uint256",
            name: "upRate",
            type: "uint256",
          },
          {
            internalType: "uint256",
            name: "downRate",
            type: "uint256",
          },
        ],
        internalType: "struct iMembers.Bounty",
        name: "bounty_",
        type: "tuple",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "user",
        type: "address",
      },
    ],
    name: "getRank",
    outputs: [
      {
        internalType: "uint32",
        name: "rank_",
        type: "uint32",
      },
    ],
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
        internalType: "uint64",
        name: "depth",
        type: "uint64",
      },
    ],
    name: "getUserRankHistory",
    outputs: [
      {
        components: [
          {
            internalType: "uint32",
            name: "timestamp",
            type: "uint32",
          },
          {
            internalType: "uint32",
            name: "rank",
            type: "uint32",
          },
        ],
        internalType: "struct LibMembers.MemberRank[]",
        name: "rank_",
        type: "tuple[]",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "maxBalance",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
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
    name: "removeBountyBalance",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "_maxBalance",
        type: "uint256",
      },
      {
        internalType: "address",
        name: "_bountyAddress",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_upRate",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "_downRate",
        type: "uint256",
      },
    ],
    name: "setBountyConfig",
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
            name: "memberAddress",
            type: "address",
          },
          {
            components: [
              {
                internalType: "uint32",
                name: "timestamp",
                type: "uint32",
              },
              {
                internalType: "uint32",
                name: "rank",
                type: "uint32",
              },
            ],
            internalType: "struct LibMembers.MemberRank",
            name: "memberRank",
            type: "tuple",
          },
        ],
        internalType: "struct LibMembers.Leaf[]",
        name: "leaves",
        type: "tuple[]",
      },
    ],
    name: "setMemberRankOwner",
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
            name: "memberAddress",
            type: "address",
          },
          {
            components: [
              {
                internalType: "uint32",
                name: "timestamp",
                type: "uint32",
              },
              {
                internalType: "uint32",
                name: "rank",
                type: "uint32",
              },
            ],
            internalType: "struct LibMembers.MemberRank",
            name: "memberRank",
            type: "tuple",
          },
        ],
        internalType: "struct LibMembers.Leaf[]",
        name: "leaves",
        type: "tuple[]",
      },
    ],
    name: "setMembersRankPermissioned",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint8",
        name: "v",
        type: "uint8",
      },
      {
        internalType: "bytes32",
        name: "r",
        type: "bytes32",
      },
      {
        internalType: "bytes32",
        name: "s",
        type: "bytes32",
      },
      {
        internalType: "address",
        name: "owner",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "nonce",
        type: "uint256",
      },
      {
        components: [
          {
            internalType: "address",
            name: "memberAddress",
            type: "address",
          },
          {
            components: [
              {
                internalType: "uint32",
                name: "timestamp",
                type: "uint32",
              },
              {
                internalType: "uint32",
                name: "rank",
                type: "uint32",
              },
            ],
            internalType: "struct LibMembers.MemberRank",
            name: "memberRank",
            type: "tuple",
          },
        ],
        internalType: "struct LibMembers.Leaf",
        name: "leaf",
        type: "tuple",
      },
    ],
    name: "setMembersRanks",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "upRate",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
] as const;

const _bytecode =
  "0x608060405234801561001057600080fd5b50613001806100206000396000f3fe608060405234801561001057600080fd5b50600436106100ea5760003560e01c806379a792d21161008c578063c516358f11610066578063c516358f14610235578063d6e7e96e14610253578063e9ff9b9d1461026f578063f49bff7b1461028d576100ea565b806379a792d2146101e157806390e6f904146101fd578063ab61d0e614610219576100ea565b8063441cb94c116100c8578063441cb94c14610159578063548c0ef41461017557806363962f40146101a557806373ad468a146101c3576100ea565b80630977109f146100ef5780631feeece21461010b57806330d157d614610129575b600080fd5b61010960048036038101906101049190611af7565b6102ab565b005b6101136102bd565b6040516101209190611b6d565b60405180910390f35b610143600480360381019061013e9190611bc8565b6102c2565b6040516101509190611d05565b60405180910390f35b610173600480360381019061016e9190611d27565b6102e0565b005b61018f600480360381019061018a9190611d54565b6102ec565b60405161019c9190611d90565b60405180910390f35b6101ad6102fe565b6040516101ba9190611b6d565b60405180910390f35b6101cb610304565b6040516101d89190611b6d565b60405180910390f35b6101fb60048036038101906101f69190611fd5565b61030a565b005b61021760048036038101906102129190611d27565b61031e565b005b610233600480360381019061022e9190611fd5565b61032a565b005b61023d610336565b60405161024a919061202d565b60405180910390f35b61026d600480360381019061026891906120b7565b61035a565b005b610277610370565b6040516102849190611b6d565b60405180910390f35b610295610376565b6040516102a291906121cb565b60405180910390f35b6102b78484848461038b565b50505050565b600081565b60606102d8838367ffffffffffffffff16610456565b905092915050565b6102e981610469565b50565b60006102f78261054c565b9050919050565b60025481565b60015481565b61031261057f565b61031b816105fd565b50565b610327816109a9565b50565b61033381610a1e565b50565b60008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b610368868686868686610a83565b505050505050565b60035481565b61037e6119e4565b610386610ac5565b905090565b600073ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff1614156103fb576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016103f290612269565b60405180910390fd5b826000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555083600181905550816002819055508060038190555050505050565b60606104628383610b36565b5092915050565b6000610473610ac5565b905060008061048a83600001518460400151610d6d565b9150838261049891906122b8565b905082602001518111156104e1576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016104d890612380565b60405180910390fd5b61050c6104ec610dd6565b846040015185600001518760405180602001604052806000815250610de5565b7f0f031db580241be0dfebea8c8139408c9117fe5f547991e0e61fdec5ff8e9a4384600060405161053e929190612417565b60405180910390a150505050565b6000610559826000610b36565b60018151811061056c5761056b612440565b5b6020026020010151602001519050919050565b61058761107b565b73ffffffffffffffffffffffffffffffffffffffff166105a5610dd6565b73ffffffffffffffffffffffffffffffffffffffff16146105fb576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016105f2906124bb565b60405180910390fd5b565b600061060761108a565b905060008060005b84518110156108bd5760008060008784815181106106305761062f612440565b5b60200260200101516000015188858151811061064f5761064e612440565b5b6020026020010151602001516000015189868151811061067257610671612440565b5b6020026020010151602001516020015192509250925060008760010160008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a90046bffffffffffffffffffffffff1690508760000160006106f4610dd6565b73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206000826bffffffffffffffffffffffff166bffffffffffffffffffffffff16815260200190815260200160002060000160009054906101000a900463ffffffff1663ffffffff168363ffffffff16108061078d5750428363ffffffff16145b1561079b57505050506108aa565b6107c560405180604001604052804263ffffffff1681526020018463ffffffff16815250856110b7565b6000816bffffffffffffffffffffffff1614156107ef5786806107e7906124f7565b9750506108a5565b8163ffffffff168860000160008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206000836bffffffffffffffffffffffff166bffffffffffffffffffffffff16815260200190815260200160002060000160049054906101000a900463ffffffff1663ffffffff161061089557858061088e906124f7565b96506108a3565b86806108a0906124f7565b97505b505b505050505b80806108b590612530565b91505061060f565b5060006108c8610ac5565b9050600081606001519050600082608001519050600081856fffffffffffffffffffffffffffffffff166108fc9190612579565b83876fffffffffffffffffffffffffffffffff1661091a9190612579565b61092491906122b8565b90506109518460400151610936610dd6565b86600001518460405180602001604052806000815250610de5565b7f168db1c48050645f89cf45a86507937dd1519567ca62af2ebe0808d715f3ff4161097a610dd6565b87866060015188886080015160405161099795949392919061260e565b60405180910390a15050505050505050565b60006109b3610ac5565b90506109e081604001516109c561107b565b83600001518560405180602001604052806000815250610de5565b7f0f031db580241be0dfebea8c8139408c9117fe5f547991e0e61fdec5ff8e9a43826001604051610a12929190612417565b60405180910390a15050565b60c860ff16610a33610a2e610dd6565b611271565b60ff161015610a77576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610a6e906126ad565b60405180910390fd5b610a80816105fd565b50565b610a918686868686866112d0565b60608181600081518110610aa857610aa7612440565b5b6020026020010181905250610abc816105fd565b50505050505050565b610acd6119e4565b6040518060a0016040528060008152602001600154815260200160008054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020016002548152602001600354815250905090565b60606000610b4261108a565b60010160008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a90046bffffffffffffffffffffffff169050826bffffffffffffffffffffffff1667ffffffffffffffff811115610bc557610bc4611dc1565b5b604051908082528060200260200182016040528015610bfe57816020015b610beb611a29565b815260200190600190039081610be35790505b50915060005b836bffffffffffffffffffffffff16816bffffffffffffffffffffffff161015610d655760008183610c3691906126e5565b6bffffffffffffffffffffffff161015610c4f57610d65565b610c5761108a565b60000160008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008284610ca591906126e5565b6bffffffffffffffffffffffff166bffffffffffffffffffffffff1681526020019081526020016000206040518060400160405290816000820160009054906101000a900463ffffffff1663ffffffff1663ffffffff1681526020016000820160049054906101000a900463ffffffff1663ffffffff1663ffffffff168152505083826bffffffffffffffffffffffff1681518110610d4757610d46612440565b5b60200260200101819052508080610d5d90612719565b915050610c04565b505092915050565b600080610d786115b0565b905080600001600085815260200190815260200160002060008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205491505092915050565b6000610de06115dd565b905090565b600073ffffffffffffffffffffffffffffffffffffffff168473ffffffffffffffffffffffffffffffffffffffff161415610e55576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610e4c906127c0565b60405180910390fd5b6000610e5f6115b0565b90506000610e6b610dd6565b90506000610e7886611614565b90506000610e8586611614565b9050600084600001600089815260200190815260200160002060008b73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054905086811015610f21576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610f1890612852565b60405180910390fd5b8681038560000160008a815260200190815260200160002060008c73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002081905550868560000160008a815260200190815260200160002060008b73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206000828254610fdc91906122b8565b925050819055508873ffffffffffffffffffffffffffffffffffffffff168a73ffffffffffffffffffffffffffffffffffffffff168573ffffffffffffffffffffffffffffffffffffffff167fc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f628b8b604051611059929190612872565b60405180910390a461106f848b8b8b8b8b61168e565b50505050505050505050565b60006110856118af565b905090565b6000807f46f9ff21a2b472f426fedec0a9a686a7aac5ea547036206278caba142b070caf90508091505090565b60006110c161108a565b60010160008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a90046bffffffffffffffffffffffff169050600060018261112b919061289b565b90508361113661108a565b60000160008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206000836bffffffffffffffffffffffff166bffffffffffffffffffffffff16815260200190815260200160002060008201518160000160006101000a81548163ffffffff021916908363ffffffff16021790555060208201518160000160046101000a81548163ffffffff021916908363ffffffff160217905550905050806111fd61108a565b60010160008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a8154816bffffffffffffffffffffffff02191690836bffffffffffffffffffffffff16021790555050505050565b600061127b6118e2565b60000160008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a900460ff169050919050565b60007f8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f7fc70ef06638535b4881fafcac8287e210e3769ff1a8e91f1b95d6246e61e4d3c67fc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6463060405160200161134b9594939291906128ec565b60405160208183030381529060405280519060200120905060007f6d3276ccb323dbd598f6a2d711c023c174d5f1bf9b8ef0973e5540fa8ff5beca858585604051602001611399919061296e565b604051602081830303815290604052805190602001206040516020016113c29493929190612989565b604051602081830303815290604052805190602001209050600082826040516020016113ef929190612a46565b60405160208183030381529060405280519060200120905060006001828b8b8b6040516000815260200160405260405161142c9493929190612a8c565b6020604051602081039080840390855afa15801561144e573d6000803e3d6000fd5b5050506020604051035190508673ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff16146114c8576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016114bf90612b1d565b60405180910390fd5b600073ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff161415611538576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161152f90612b89565b60405180910390fd5b600061154261108a565b905060008160020154905080881015611590576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161158790612bf5565b60405180910390fd5b808811156115a2578782600201819055505b505050505050505050505050565b6000807f6469616d6f6e642e73746f726167652e6572633131353500000000000000000090508091505090565b600060146000369050101580156115f957506115f83361190f565b5b1561160d57601436033560601c9050611611565b3390505b90565b60606000600167ffffffffffffffff81111561163357611632611dc1565b5b6040519080825280602002602001820160405280156116615781602001602082028036833780820191505090505b509050828160008151811061167957611678612440565b5b60200260200101818152505080915050919050565b6116ad8473ffffffffffffffffffffffffffffffffffffffff16611977565b156118a6573073ffffffffffffffffffffffffffffffffffffffff168473ffffffffffffffffffffffffffffffffffffffff1614156116eb576118a7565b8373ffffffffffffffffffffffffffffffffffffffff1663f23a6e6187878686866040518663ffffffff1660e01b815260040161172c959493929190612c9d565b602060405180830381600087803b15801561174657600080fd5b505af192505050801561177757506040513d601f19601f820116820180604052508101906117749190612d4f565b60015b61181d57611783612d89565b806308c379a014156117e05750611798612dab565b806117a357506117e2565b806040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016117d79190612e85565b60405180910390fd5b505b6040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161181490612f19565b60405180910390fd5b63f23a6e6160e01b7bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916817bffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916146118a4576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161189b90612fab565b60405180910390fd5b505b5b505050505050565b60006118b961198a565b60000160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff16905090565b6000807f8c2c577630c40136bcc18deb16687d093146d4bb8d4918e4af706e0bd8cb086590508091505090565b60008061191a6119b7565b90508060000160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff1614915050919050565b600080823b905060008111915050919050565b6000807fd00049dc7109015045860694acecd3dc33338404aaf6e55a1c98a2bf41477b8590508091505090565b6000807f413a4c31c13c7c3de0c7da37be5d779b152baf3f21a1cb760fda41eb8ca9777690508091505090565b6040518060a001604052806000815260200160008152602001600073ffffffffffffffffffffffffffffffffffffffff16815260200160008152602001600081525090565b6040518060400160405280600063ffffffff168152602001600063ffffffff1681525090565b6000604051905090565b600080fd5b600080fd5b6000819050919050565b611a7681611a63565b8114611a8157600080fd5b50565b600081359050611a9381611a6d565b92915050565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000611ac482611a99565b9050919050565b611ad481611ab9565b8114611adf57600080fd5b50565b600081359050611af181611acb565b92915050565b60008060008060808587031215611b1157611b10611a59565b5b6000611b1f87828801611a84565b9450506020611b3087828801611ae2565b9350506040611b4187828801611a84565b9250506060611b5287828801611a84565b91505092959194509250565b611b6781611a63565b82525050565b6000602082019050611b826000830184611b5e565b92915050565b600067ffffffffffffffff82169050919050565b611ba581611b88565b8114611bb057600080fd5b50565b600081359050611bc281611b9c565b92915050565b60008060408385031215611bdf57611bde611a59565b5b6000611bed85828601611ae2565b9250506020611bfe85828601611bb3565b9150509250929050565b600081519050919050565b600082825260208201905092915050565b6000819050602082019050919050565b600063ffffffff82169050919050565b611c4d81611c34565b82525050565b604082016000820151611c696000850182611c44565b506020820151611c7c6020850182611c44565b50505050565b6000611c8e8383611c53565b60408301905092915050565b6000602082019050919050565b6000611cb282611c08565b611cbc8185611c13565b9350611cc783611c24565b8060005b83811015611cf8578151611cdf8882611c82565b9750611cea83611c9a565b925050600181019050611ccb565b5085935050505092915050565b60006020820190508181036000830152611d1f8184611ca7565b905092915050565b600060208284031215611d3d57611d3c611a59565b5b6000611d4b84828501611a84565b91505092915050565b600060208284031215611d6a57611d69611a59565b5b6000611d7884828501611ae2565b91505092915050565b611d8a81611c34565b82525050565b6000602082019050611da56000830184611d81565b92915050565b600080fd5b6000601f19601f8301169050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b611df982611db0565b810181811067ffffffffffffffff82111715611e1857611e17611dc1565b5b80604052505050565b6000611e2b611a4f565b9050611e378282611df0565b919050565b600067ffffffffffffffff821115611e5757611e56611dc1565b5b602082029050602081019050919050565b600080fd5b600080fd5b611e7b81611c34565b8114611e8657600080fd5b50565b600081359050611e9881611e72565b92915050565b600060408284031215611eb457611eb3611e6d565b5b611ebe6040611e21565b90506000611ece84828501611e89565b6000830152506020611ee284828501611e89565b60208301525092915050565b600060608284031215611f0457611f03611e6d565b5b611f0e6040611e21565b90506000611f1e84828501611ae2565b6000830152506020611f3284828501611e9e565b60208301525092915050565b6000611f51611f4c84611e3c565b611e21565b90508083825260208201905060608402830185811115611f7457611f73611e68565b5b835b81811015611f9d5780611f898882611eee565b845260208401935050606081019050611f76565b5050509392505050565b600082601f830112611fbc57611fbb611dab565b5b8135611fcc848260208601611f3e565b91505092915050565b600060208284031215611feb57611fea611a59565b5b600082013567ffffffffffffffff81111561200957612008611a5e565b5b61201584828501611fa7565b91505092915050565b61202781611ab9565b82525050565b6000602082019050612042600083018461201e565b92915050565b600060ff82169050919050565b61205e81612048565b811461206957600080fd5b50565b60008135905061207b81612055565b92915050565b6000819050919050565b61209481612081565b811461209f57600080fd5b50565b6000813590506120b18161208b565b92915050565b60008060008060008061010087890312156120d5576120d4611a59565b5b60006120e389828a0161206c565b96505060206120f489828a016120a2565b955050604061210589828a016120a2565b945050606061211689828a01611ae2565b935050608061212789828a01611a84565b92505060a061213889828a01611eee565b9150509295509295509295565b61214e81611a63565b82525050565b61215d81611ab9565b82525050565b60a0820160008201516121796000850182612145565b50602082015161218c6020850182612145565b50604082015161219f6040850182612154565b5060608201516121b26060850182612145565b5060808201516121c56080850182612145565b50505050565b600060a0820190506121e06000830184612163565b92915050565b600082825260208201905092915050565b7f426f756e7479206d7573746e27742062652073657420746f20746865207a657260008201527f6f20616464726573730000000000000000000000000000000000000000000000602082015250565b60006122536029836121e6565b915061225e826121f7565b604082019050919050565b6000602082019050818103600083015261228281612246565b9050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b60006122c382611a63565b91506122ce83611a63565b9250827fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0382111561230357612302612289565b5b828201905092915050565b7f424d423a204e657720626f756e74792062616c616e636520657863656564732060008201527f626f756e74794d617842616c616e636500000000000000000000000000000000602082015250565b600061236a6030836121e6565b91506123758261230e565b604082019050919050565b600060208201905081810360008301526123998161235d565b9050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052602160045260246000fd5b600281106123e0576123df6123a0565b5b50565b60008190506123f1826123cf565b919050565b6000612401826123e3565b9050919050565b612411816123f6565b82525050565b600060408201905061242c6000830185611b5e565b6124396020830184612408565b9392505050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052603260045260246000fd5b7f4d757374206265207468652045636f73797374656d206f776e65720000000000600082015250565b60006124a5601b836121e6565b91506124b08261246f565b602082019050919050565b600060208201905081810360008301526124d481612498565b9050919050565b60006fffffffffffffffffffffffffffffffff82169050919050565b6000612502826124db565b91506fffffffffffffffffffffffffffffffff82141561252557612524612289565b5b600182019050919050565b600061253b82611a63565b91507fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff82141561256e5761256d612289565b5b600182019050919050565b600061258482611a63565b915061258f83611a63565b9250817fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff04831182151516156125c8576125c7612289565b5b828202905092915050565b6000819050919050565b60006125f86125f36125ee846124db565b6125d3565b611a63565b9050919050565b612608816125dd565b82525050565b600060a082019050612623600083018861201e565b61263060208301876125ff565b61263d6040830186611b5e565b61264a60608301856125ff565b6126576080830184611b5e565b9695505050505050565b7f4d53202d20496e73756666696369656e742050726976656c656765732e000000600082015250565b6000612697601d836121e6565b91506126a282612661565b602082019050919050565b600060208201905081810360008301526126c68161268a565b9050919050565b60006bffffffffffffffffffffffff82169050919050565b60006126f0826126cd565b91506126fb836126cd565b92508282101561270e5761270d612289565b5b828203905092915050565b6000612724826126cd565b91506bffffffffffffffffffffffff82141561274357612742612289565b5b600182019050919050565b7f455243313135353a207472616e7366657220746f20746865207a65726f20616460008201527f6472657373000000000000000000000000000000000000000000000000000000602082015250565b60006127aa6025836121e6565b91506127b58261274e565b604082019050919050565b600060208201905081810360008301526127d98161279d565b9050919050565b7f455243313135353a20696e73756666696369656e742062616c616e636520666f60008201527f72207472616e7366657200000000000000000000000000000000000000000000602082015250565b600061283c602a836121e6565b9150612847826127e0565b604082019050919050565b6000602082019050818103600083015261286b8161282f565b9050919050565b60006040820190506128876000830185611b5e565b6128946020830184611b5e565b9392505050565b60006128a6826126cd565b91506128b1836126cd565b9250826bffffffffffffffffffffffff038211156128d2576128d1612289565b5b828201905092915050565b6128e681612081565b82525050565b600060a08201905061290160008301886128dd565b61290e60208301876128dd565b61291b60408301866128dd565b6129286060830185611b5e565b612935608083018461201e565b9695505050505050565b6060820160008201516129556000850182612154565b5060208201516129686020850182611c53565b50505050565b6000606082019050612983600083018461293f565b92915050565b600060808201905061299e60008301876128dd565b6129ab602083018661201e565b6129b86040830185611b5e565b6129c560608301846128dd565b95945050505050565b600081905092915050565b7f1901000000000000000000000000000000000000000000000000000000000000600082015250565b6000612a0f6002836129ce565b9150612a1a826129d9565b600282019050919050565b6000819050919050565b612a40612a3b82612081565b612a25565b82525050565b6000612a5182612a02565b9150612a5d8285612a2f565b602082019150612a6d8284612a2f565b6020820191508190509392505050565b612a8681612048565b82525050565b6000608082019050612aa160008301876128dd565b612aae6020830186612a7d565b612abb60408301856128dd565b612ac860608301846128dd565b95945050505050565b7f4d656d6265723a20696e76616c6964207369676e617475726500000000000000600082015250565b6000612b076019836121e6565b9150612b1282612ad1565b602082019050919050565b60006020820190508181036000830152612b3681612afa565b9050919050565b7f45434453413a20696e76616c6964207369676e61747572650000000000000000600082015250565b6000612b736018836121e6565b9150612b7e82612b3d565b602082019050919050565b60006020820190508181036000830152612ba281612b66565b9050919050565b7f454e203a204e6f6e636520686173206578706972656400000000000000000000600082015250565b6000612bdf6016836121e6565b9150612bea82612ba9565b602082019050919050565b60006020820190508181036000830152612c0e81612bd2565b9050919050565b600081519050919050565b600082825260208201905092915050565b60005b83811015612c4f578082015181840152602081019050612c34565b83811115612c5e576000848401525b50505050565b6000612c6f82612c15565b612c798185612c20565b9350612c89818560208601612c31565b612c9281611db0565b840191505092915050565b600060a082019050612cb2600083018861201e565b612cbf602083018761201e565b612ccc6040830186611b5e565b612cd96060830185611b5e565b8181036080830152612ceb8184612c64565b90509695505050505050565b60007fffffffff0000000000000000000000000000000000000000000000000000000082169050919050565b612d2c81612cf7565b8114612d3757600080fd5b50565b600081519050612d4981612d23565b92915050565b600060208284031215612d6557612d64611a59565b5b6000612d7384828501612d3a565b91505092915050565b60008160e01c9050919050565b600060033d1115612da85760046000803e612da5600051612d7c565b90505b90565b600060443d1015612dbb57612e3e565b612dc3611a4f565b60043d036004823e80513d602482011167ffffffffffffffff82111715612deb575050612e3e565b808201805167ffffffffffffffff811115612e095750505050612e3e565b80602083010160043d038501811115612e26575050505050612e3e565b612e3582602001850186611df0565b82955050505050505b90565b600081519050919050565b6000612e5782612e41565b612e6181856121e6565b9350612e71818560208601612c31565b612e7a81611db0565b840191505092915050565b60006020820190508181036000830152612e9f8184612e4c565b905092915050565b7f455243313135353a207472616e7366657220746f206e6f6e2d4552433131353560008201527f526563656976657220696d706c656d656e746572000000000000000000000000602082015250565b6000612f036034836121e6565b9150612f0e82612ea7565b604082019050919050565b60006020820190508181036000830152612f3281612ef6565b9050919050565b7f455243313135353a204552433131353552656365697665722072656a6563746560008201527f6420746f6b656e73000000000000000000000000000000000000000000000000602082015250565b6000612f956028836121e6565b9150612fa082612f39565b604082019050919050565b60006020820190508181036000830152612fc481612f88565b905091905056fea264697066735822122085fa7298c5b006ccb5e9018c106cdd22e1303a351ef0538a2e5aef927292f2e664736f6c63430008090033";

type MembersConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: MembersConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class Members__factory extends ContractFactory {
  constructor(...args: MembersConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<Members> {
    return super.deploy(overrides || {}) as Promise<Members>;
  }
  override getDeployTransaction(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  override attach(address: string): Members {
    return super.attach(address) as Members;
  }
  override connect(signer: Signer): Members__factory {
    return super.connect(signer) as Members__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): MembersInterface {
    return new utils.Interface(_abi) as MembersInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): Members {
    return new Contract(address, _abi, signerOrProvider) as Members;
  }
}
