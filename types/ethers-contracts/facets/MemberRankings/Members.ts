/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BigNumber,
  BigNumberish,
  BytesLike,
  CallOverrides,
  ContractTransaction,
  Overrides,
  PopulatedTransaction,
  Signer,
  utils,
} from "ethers";
import type {
  FunctionFragment,
  Result,
  EventFragment,
} from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type {
  TypedEventFilter,
  TypedEvent,
  TypedListener,
  OnEvent,
  PromiseOrValue,
} from "../../common";

export declare namespace IMembers {
  export type BountyStruct = {
    currencyId: PromiseOrValue<BigNumberish>;
    maxBalance: PromiseOrValue<BigNumberish>;
    bountyAddress: PromiseOrValue<string>;
    upRate: PromiseOrValue<BigNumberish>;
    downRate: PromiseOrValue<BigNumberish>;
  };

  export type BountyStructOutput = [
    BigNumber,
    BigNumber,
    string,
    BigNumber,
    BigNumber
  ] & {
    currencyId: BigNumber;
    maxBalance: BigNumber;
    bountyAddress: string;
    upRate: BigNumber;
    downRate: BigNumber;
  };
}

export declare namespace LibMembers {
  export type MemberRankStruct = {
    timestamp: PromiseOrValue<BigNumberish>;
    rank: PromiseOrValue<BigNumberish>;
  };

  export type MemberRankStructOutput = [number, number] & {
    timestamp: number;
    rank: number;
  };

  export type LeafStruct = {
    memberAddress: PromiseOrValue<string>;
    memberRank: LibMembers.MemberRankStruct;
  };

  export type LeafStructOutput = [string, LibMembers.MemberRankStructOutput] & {
    memberAddress: string;
    memberRank: LibMembers.MemberRankStructOutput;
  };
}

export interface MembersInterface extends utils.Interface {
  functions: {
    "addBountyBalance(uint256)": FunctionFragment;
    "bountyAddress()": FunctionFragment;
    "currencyId()": FunctionFragment;
    "downRate()": FunctionFragment;
    "getBounty()": FunctionFragment;
    "getRank(address)": FunctionFragment;
    "getUserRankHistory(address,uint64)": FunctionFragment;
    "maxBalance()": FunctionFragment;
    "removeBountyBalance(uint256)": FunctionFragment;
    "setBountyConfig(uint256,address,uint256,uint256)": FunctionFragment;
    "setMemberRankOwner((address,(uint32,uint32))[])": FunctionFragment;
    "setMembersRankPermissioned((address,(uint32,uint32))[])": FunctionFragment;
    "setMembersRanks(uint8,bytes32,bytes32,address,uint256,(address,(uint32,uint32)))": FunctionFragment;
    "upRate()": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "addBountyBalance"
      | "bountyAddress"
      | "currencyId"
      | "downRate"
      | "getBounty"
      | "getRank"
      | "getUserRankHistory"
      | "maxBalance"
      | "removeBountyBalance"
      | "setBountyConfig"
      | "setMemberRankOwner"
      | "setMembersRankPermissioned"
      | "setMembersRanks"
      | "upRate"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "addBountyBalance",
    values: [PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "bountyAddress",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "currencyId",
    values?: undefined
  ): string;
  encodeFunctionData(functionFragment: "downRate", values?: undefined): string;
  encodeFunctionData(functionFragment: "getBounty", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "getRank",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "getUserRankHistory",
    values: [PromiseOrValue<string>, PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "maxBalance",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "removeBountyBalance",
    values: [PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "setBountyConfig",
    values: [
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<string>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "setMemberRankOwner",
    values: [LibMembers.LeafStruct[]]
  ): string;
  encodeFunctionData(
    functionFragment: "setMembersRankPermissioned",
    values: [LibMembers.LeafStruct[]]
  ): string;
  encodeFunctionData(
    functionFragment: "setMembersRanks",
    values: [
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BytesLike>,
      PromiseOrValue<BytesLike>,
      PromiseOrValue<string>,
      PromiseOrValue<BigNumberish>,
      LibMembers.LeafStruct
    ]
  ): string;
  encodeFunctionData(functionFragment: "upRate", values?: undefined): string;

  decodeFunctionResult(
    functionFragment: "addBountyBalance",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "bountyAddress",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "currencyId", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "downRate", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "getBounty", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "getRank", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "getUserRankHistory",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "maxBalance", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "removeBountyBalance",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "setBountyConfig",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "setMemberRankOwner",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "setMembersRankPermissioned",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "setMembersRanks",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "upRate", data: BytesLike): Result;

  events: {
    "ApprovalForAll(address,address,bool)": EventFragment;
    "BountyBalanceChange(uint256,uint8)": EventFragment;
    "BountyEvent(address,uint256,uint256,uint256,uint256)": EventFragment;
    "MigrationCancelled(address,uint32)": EventFragment;
    "MigrationInitiated(address,uint32)": EventFragment;
    "TransferBatch(address,address,address,uint256[],uint256[])": EventFragment;
    "TransferSingle(address,address,address,uint256,uint256)": EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: "ApprovalForAll"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "BountyBalanceChange"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "BountyEvent"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "MigrationCancelled"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "MigrationInitiated"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "TransferBatch"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "TransferSingle"): EventFragment;
}

export interface ApprovalForAllEventObject {
  account: string;
  operator: string;
  approved: boolean;
}
export type ApprovalForAllEvent = TypedEvent<
  [string, string, boolean],
  ApprovalForAllEventObject
>;

export type ApprovalForAllEventFilter = TypedEventFilter<ApprovalForAllEvent>;

export interface BountyBalanceChangeEventObject {
  amount: BigNumber;
  direction: number;
}
export type BountyBalanceChangeEvent = TypedEvent<
  [BigNumber, number],
  BountyBalanceChangeEventObject
>;

export type BountyBalanceChangeEventFilter =
  TypedEventFilter<BountyBalanceChangeEvent>;

export interface BountyEventEventObject {
  receiver: string;
  bountyUp: BigNumber;
  bountyUpRate: BigNumber;
  bountiesDown: BigNumber;
  bountyDownRate: BigNumber;
}
export type BountyEventEvent = TypedEvent<
  [string, BigNumber, BigNumber, BigNumber, BigNumber],
  BountyEventEventObject
>;

export type BountyEventEventFilter = TypedEventFilter<BountyEventEvent>;

export interface MigrationCancelledEventObject {
  cancellor: string;
  timeCancelled: number;
}
export type MigrationCancelledEvent = TypedEvent<
  [string, number],
  MigrationCancelledEventObject
>;

export type MigrationCancelledEventFilter =
  TypedEventFilter<MigrationCancelledEvent>;

export interface MigrationInitiatedEventObject {
  initiatior: string;
  timeInitiatied: number;
}
export type MigrationInitiatedEvent = TypedEvent<
  [string, number],
  MigrationInitiatedEventObject
>;

export type MigrationInitiatedEventFilter =
  TypedEventFilter<MigrationInitiatedEvent>;

export interface TransferBatchEventObject {
  operator: string;
  from: string;
  to: string;
  ids: BigNumber[];
  values: BigNumber[];
}
export type TransferBatchEvent = TypedEvent<
  [string, string, string, BigNumber[], BigNumber[]],
  TransferBatchEventObject
>;

export type TransferBatchEventFilter = TypedEventFilter<TransferBatchEvent>;

export interface TransferSingleEventObject {
  operator: string;
  from: string;
  to: string;
  id: BigNumber;
  value: BigNumber;
}
export type TransferSingleEvent = TypedEvent<
  [string, string, string, BigNumber, BigNumber],
  TransferSingleEventObject
>;

export type TransferSingleEventFilter = TypedEventFilter<TransferSingleEvent>;

export interface Members extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: MembersInterface;

  queryFilter<TEvent extends TypedEvent>(
    event: TypedEventFilter<TEvent>,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TEvent>>;

  listeners<TEvent extends TypedEvent>(
    eventFilter?: TypedEventFilter<TEvent>
  ): Array<TypedListener<TEvent>>;
  listeners(eventName?: string): Array<Listener>;
  removeAllListeners<TEvent extends TypedEvent>(
    eventFilter: TypedEventFilter<TEvent>
  ): this;
  removeAllListeners(eventName?: string): this;
  off: OnEvent<this>;
  on: OnEvent<this>;
  once: OnEvent<this>;
  removeListener: OnEvent<this>;

  functions: {
    addBountyBalance(
      amount: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    bountyAddress(overrides?: CallOverrides): Promise<[string]>;

    currencyId(overrides?: CallOverrides): Promise<[BigNumber]>;

    downRate(overrides?: CallOverrides): Promise<[BigNumber]>;

    getBounty(
      overrides?: CallOverrides
    ): Promise<
      [IMembers.BountyStructOutput] & { bounty_: IMembers.BountyStructOutput }
    >;

    getRank(
      user: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    getUserRankHistory(
      user: PromiseOrValue<string>,
      depth: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    maxBalance(overrides?: CallOverrides): Promise<[BigNumber]>;

    removeBountyBalance(
      amount: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    setBountyConfig(
      _maxBalance: PromiseOrValue<BigNumberish>,
      _bountyAddress: PromiseOrValue<string>,
      _upRate: PromiseOrValue<BigNumberish>,
      _downRate: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    setMemberRankOwner(
      leaves: LibMembers.LeafStruct[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    setMembersRankPermissioned(
      leaves: LibMembers.LeafStruct[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    setMembersRanks(
      v: PromiseOrValue<BigNumberish>,
      r: PromiseOrValue<BytesLike>,
      s: PromiseOrValue<BytesLike>,
      owner: PromiseOrValue<string>,
      nonce: PromiseOrValue<BigNumberish>,
      leaf: LibMembers.LeafStruct,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    upRate(overrides?: CallOverrides): Promise<[BigNumber]>;
  };

  addBountyBalance(
    amount: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  bountyAddress(overrides?: CallOverrides): Promise<string>;

  currencyId(overrides?: CallOverrides): Promise<BigNumber>;

  downRate(overrides?: CallOverrides): Promise<BigNumber>;

  getBounty(overrides?: CallOverrides): Promise<IMembers.BountyStructOutput>;

  getRank(
    user: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  getUserRankHistory(
    user: PromiseOrValue<string>,
    depth: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  maxBalance(overrides?: CallOverrides): Promise<BigNumber>;

  removeBountyBalance(
    amount: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  setBountyConfig(
    _maxBalance: PromiseOrValue<BigNumberish>,
    _bountyAddress: PromiseOrValue<string>,
    _upRate: PromiseOrValue<BigNumberish>,
    _downRate: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  setMemberRankOwner(
    leaves: LibMembers.LeafStruct[],
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  setMembersRankPermissioned(
    leaves: LibMembers.LeafStruct[],
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  setMembersRanks(
    v: PromiseOrValue<BigNumberish>,
    r: PromiseOrValue<BytesLike>,
    s: PromiseOrValue<BytesLike>,
    owner: PromiseOrValue<string>,
    nonce: PromiseOrValue<BigNumberish>,
    leaf: LibMembers.LeafStruct,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  upRate(overrides?: CallOverrides): Promise<BigNumber>;

  callStatic: {
    addBountyBalance(
      amount: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    bountyAddress(overrides?: CallOverrides): Promise<string>;

    currencyId(overrides?: CallOverrides): Promise<BigNumber>;

    downRate(overrides?: CallOverrides): Promise<BigNumber>;

    getBounty(overrides?: CallOverrides): Promise<IMembers.BountyStructOutput>;

    getRank(
      user: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<number>;

    getUserRankHistory(
      user: PromiseOrValue<string>,
      depth: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<LibMembers.MemberRankStructOutput[]>;

    maxBalance(overrides?: CallOverrides): Promise<BigNumber>;

    removeBountyBalance(
      amount: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    setBountyConfig(
      _maxBalance: PromiseOrValue<BigNumberish>,
      _bountyAddress: PromiseOrValue<string>,
      _upRate: PromiseOrValue<BigNumberish>,
      _downRate: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    setMemberRankOwner(
      leaves: LibMembers.LeafStruct[],
      overrides?: CallOverrides
    ): Promise<void>;

    setMembersRankPermissioned(
      leaves: LibMembers.LeafStruct[],
      overrides?: CallOverrides
    ): Promise<void>;

    setMembersRanks(
      v: PromiseOrValue<BigNumberish>,
      r: PromiseOrValue<BytesLike>,
      s: PromiseOrValue<BytesLike>,
      owner: PromiseOrValue<string>,
      nonce: PromiseOrValue<BigNumberish>,
      leaf: LibMembers.LeafStruct,
      overrides?: CallOverrides
    ): Promise<void>;

    upRate(overrides?: CallOverrides): Promise<BigNumber>;
  };

  filters: {
    "ApprovalForAll(address,address,bool)"(
      account?: PromiseOrValue<string> | null,
      operator?: PromiseOrValue<string> | null,
      approved?: null
    ): ApprovalForAllEventFilter;
    ApprovalForAll(
      account?: PromiseOrValue<string> | null,
      operator?: PromiseOrValue<string> | null,
      approved?: null
    ): ApprovalForAllEventFilter;

    "BountyBalanceChange(uint256,uint8)"(
      amount?: null,
      direction?: null
    ): BountyBalanceChangeEventFilter;
    BountyBalanceChange(
      amount?: null,
      direction?: null
    ): BountyBalanceChangeEventFilter;

    "BountyEvent(address,uint256,uint256,uint256,uint256)"(
      receiver?: null,
      bountyUp?: null,
      bountyUpRate?: null,
      bountiesDown?: null,
      bountyDownRate?: null
    ): BountyEventEventFilter;
    BountyEvent(
      receiver?: null,
      bountyUp?: null,
      bountyUpRate?: null,
      bountiesDown?: null,
      bountyDownRate?: null
    ): BountyEventEventFilter;

    "MigrationCancelled(address,uint32)"(
      cancellor?: null,
      timeCancelled?: null
    ): MigrationCancelledEventFilter;
    MigrationCancelled(
      cancellor?: null,
      timeCancelled?: null
    ): MigrationCancelledEventFilter;

    "MigrationInitiated(address,uint32)"(
      initiatior?: null,
      timeInitiatied?: null
    ): MigrationInitiatedEventFilter;
    MigrationInitiated(
      initiatior?: null,
      timeInitiatied?: null
    ): MigrationInitiatedEventFilter;

    "TransferBatch(address,address,address,uint256[],uint256[])"(
      operator?: PromiseOrValue<string> | null,
      from?: PromiseOrValue<string> | null,
      to?: PromiseOrValue<string> | null,
      ids?: null,
      values?: null
    ): TransferBatchEventFilter;
    TransferBatch(
      operator?: PromiseOrValue<string> | null,
      from?: PromiseOrValue<string> | null,
      to?: PromiseOrValue<string> | null,
      ids?: null,
      values?: null
    ): TransferBatchEventFilter;

    "TransferSingle(address,address,address,uint256,uint256)"(
      operator?: PromiseOrValue<string> | null,
      from?: PromiseOrValue<string> | null,
      to?: PromiseOrValue<string> | null,
      id?: null,
      value?: null
    ): TransferSingleEventFilter;
    TransferSingle(
      operator?: PromiseOrValue<string> | null,
      from?: PromiseOrValue<string> | null,
      to?: PromiseOrValue<string> | null,
      id?: null,
      value?: null
    ): TransferSingleEventFilter;
  };

  estimateGas: {
    addBountyBalance(
      amount: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    bountyAddress(overrides?: CallOverrides): Promise<BigNumber>;

    currencyId(overrides?: CallOverrides): Promise<BigNumber>;

    downRate(overrides?: CallOverrides): Promise<BigNumber>;

    getBounty(overrides?: CallOverrides): Promise<BigNumber>;

    getRank(
      user: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    getUserRankHistory(
      user: PromiseOrValue<string>,
      depth: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    maxBalance(overrides?: CallOverrides): Promise<BigNumber>;

    removeBountyBalance(
      amount: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    setBountyConfig(
      _maxBalance: PromiseOrValue<BigNumberish>,
      _bountyAddress: PromiseOrValue<string>,
      _upRate: PromiseOrValue<BigNumberish>,
      _downRate: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    setMemberRankOwner(
      leaves: LibMembers.LeafStruct[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    setMembersRankPermissioned(
      leaves: LibMembers.LeafStruct[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    setMembersRanks(
      v: PromiseOrValue<BigNumberish>,
      r: PromiseOrValue<BytesLike>,
      s: PromiseOrValue<BytesLike>,
      owner: PromiseOrValue<string>,
      nonce: PromiseOrValue<BigNumberish>,
      leaf: LibMembers.LeafStruct,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    upRate(overrides?: CallOverrides): Promise<BigNumber>;
  };

  populateTransaction: {
    addBountyBalance(
      amount: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    bountyAddress(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    currencyId(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    downRate(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    getBounty(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    getRank(
      user: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    getUserRankHistory(
      user: PromiseOrValue<string>,
      depth: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    maxBalance(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    removeBountyBalance(
      amount: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    setBountyConfig(
      _maxBalance: PromiseOrValue<BigNumberish>,
      _bountyAddress: PromiseOrValue<string>,
      _upRate: PromiseOrValue<BigNumberish>,
      _downRate: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    setMemberRankOwner(
      leaves: LibMembers.LeafStruct[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    setMembersRankPermissioned(
      leaves: LibMembers.LeafStruct[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    setMembersRanks(
      v: PromiseOrValue<BigNumberish>,
      r: PromiseOrValue<BytesLike>,
      s: PromiseOrValue<BytesLike>,
      owner: PromiseOrValue<string>,
      nonce: PromiseOrValue<BigNumberish>,
      leaf: LibMembers.LeafStruct,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    upRate(overrides?: CallOverrides): Promise<PopulatedTransaction>;
  };
}
