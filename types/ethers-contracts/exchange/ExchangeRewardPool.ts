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
} from "../common";

export interface ExchangeRewardPoolInterface extends utils.Interface {
  functions: {
    "batchStakeTimePool(uint256[],uint8[],uint256[],address[])": FunctionFragment;
    "calculateReward(address,uint8,uint32,uint256)": FunctionFragment;
    "collectReward(uint256)": FunctionFragment;
    "collectRewardCleanupUser(address,uint32)": FunctionFragment;
    "collectRewardCleanupUser(address[],uint32[])": FunctionFragment;
    "rollingEarningsSumRatio()": FunctionFragment;
    "stakeSumGetter(address,uint32,uint8)": FunctionFragment;
    "stakeTimePool(uint256,uint8,uint256,address)": FunctionFragment;
    "timePoolStakes(uint256)": FunctionFragment;
    "timeSlotActivationBitMap(address,uint32)": FunctionFragment;
    "timeSlotRewards(address,uint32)": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "batchStakeTimePool"
      | "calculateReward"
      | "collectReward"
      | "collectRewardCleanupUser(address,uint32)"
      | "collectRewardCleanupUser(address[],uint32[])"
      | "rollingEarningsSumRatio"
      | "stakeSumGetter"
      | "stakeTimePool"
      | "timePoolStakes"
      | "timeSlotActivationBitMap"
      | "timeSlotRewards"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "batchStakeTimePool",
    values: [
      PromiseOrValue<BigNumberish>[],
      PromiseOrValue<BigNumberish>[],
      PromiseOrValue<BigNumberish>[],
      PromiseOrValue<string>[]
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "calculateReward",
    values: [
      PromiseOrValue<string>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "collectReward",
    values: [PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "collectRewardCleanupUser(address,uint32)",
    values: [PromiseOrValue<string>, PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "collectRewardCleanupUser(address[],uint32[])",
    values: [PromiseOrValue<string>[], PromiseOrValue<BigNumberish>[]]
  ): string;
  encodeFunctionData(
    functionFragment: "rollingEarningsSumRatio",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "stakeSumGetter",
    values: [
      PromiseOrValue<string>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "stakeTimePool",
    values: [
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<string>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "timePoolStakes",
    values: [PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "timeSlotActivationBitMap",
    values: [PromiseOrValue<string>, PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "timeSlotRewards",
    values: [PromiseOrValue<string>, PromiseOrValue<BigNumberish>]
  ): string;

  decodeFunctionResult(
    functionFragment: "batchStakeTimePool",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "calculateReward",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "collectReward",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "collectRewardCleanupUser(address,uint32)",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "collectRewardCleanupUser(address[],uint32[])",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "rollingEarningsSumRatio",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "stakeSumGetter",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "stakeTimePool",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "timePoolStakes",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "timeSlotActivationBitMap",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "timeSlotRewards",
    data: BytesLike
  ): Result;

  events: {
    "MigrationCancelled(address,uint32)": EventFragment;
    "MigrationInitiated(address,uint32)": EventFragment;
    "OwnershipChanged(address,address)": EventFragment;
    "Staked(uint32,uint8,uint256,address)": EventFragment;
    "StakerRewardsCollected(address,uint256)": EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: "MigrationCancelled"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "MigrationInitiated"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "OwnershipChanged"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "Staked"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "StakerRewardsCollected"): EventFragment;
}

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

export interface OwnershipChangedEventObject {
  oldOwner: string;
  newOwner: string;
}
export type OwnershipChangedEvent = TypedEvent<
  [string, string],
  OwnershipChangedEventObject
>;

export type OwnershipChangedEventFilter =
  TypedEventFilter<OwnershipChangedEvent>;

export interface StakedEventObject {
  timeStart: number;
  stakeInterval: number;
  stakeAmouunt: BigNumber;
  staker: string;
}
export type StakedEvent = TypedEvent<
  [number, number, BigNumber, string],
  StakedEventObject
>;

export type StakedEventFilter = TypedEventFilter<StakedEvent>;

export interface StakerRewardsCollectedEventObject {
  staker: string;
  amount: BigNumber;
}
export type StakerRewardsCollectedEvent = TypedEvent<
  [string, BigNumber],
  StakerRewardsCollectedEventObject
>;

export type StakerRewardsCollectedEventFilter =
  TypedEventFilter<StakerRewardsCollectedEvent>;

export interface ExchangeRewardPool extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: ExchangeRewardPoolInterface;

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
    batchStakeTimePool(
      _stakeIds: PromiseOrValue<BigNumberish>[],
      _stakeIntervals: PromiseOrValue<BigNumberish>[],
      _stakeAmounts: PromiseOrValue<BigNumberish>[],
      _tokenAddresses: PromiseOrValue<string>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    calculateReward(
      _tokenAddress: PromiseOrValue<string>,
      _stakeInterval: PromiseOrValue<BigNumberish>,
      _stakeStartTimeSlot: PromiseOrValue<BigNumberish>,
      _stakeAmount: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[BigNumber] & { reward_: BigNumber }>;

    collectReward(
      _stakeId: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    "collectRewardCleanupUser(address,uint32)"(
      _tokenAddress: PromiseOrValue<string>,
      _startTimeSlot: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    "collectRewardCleanupUser(address[],uint32[])"(
      _tokenAddresses: PromiseOrValue<string>[],
      _startTimeSlots: PromiseOrValue<BigNumberish>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    rollingEarningsSumRatio(overrides?: CallOverrides): Promise<[BigNumber]>;

    stakeSumGetter(
      _tokenAddress: PromiseOrValue<string>,
      _timeSlot: PromiseOrValue<BigNumberish>,
      _stakeDayInterval: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;

    stakeTimePool(
      _stakeId: PromiseOrValue<BigNumberish>,
      _stakeInterval: PromiseOrValue<BigNumberish>,
      _stakeAmount: PromiseOrValue<BigNumberish>,
      _tokenAddress: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    timePoolStakes(
      arg0: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<
      [number, string, number, BigNumber, string, number] & {
        startTimeSlot: number;
        staker: string;
        stakeInterval: number;
        amount: BigNumber;
        tokenAddress: string;
        status: number;
      }
    >;

    timeSlotActivationBitMap(
      arg0: PromiseOrValue<string>,
      arg1: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[string]>;

    timeSlotRewards(
      arg0: PromiseOrValue<string>,
      arg1: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<
      [BigNumber, BigNumber] & {
        totalSlotSum: BigNumber;
        totalEarningsPerSum: BigNumber;
      }
    >;
  };

  batchStakeTimePool(
    _stakeIds: PromiseOrValue<BigNumberish>[],
    _stakeIntervals: PromiseOrValue<BigNumberish>[],
    _stakeAmounts: PromiseOrValue<BigNumberish>[],
    _tokenAddresses: PromiseOrValue<string>[],
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  calculateReward(
    _tokenAddress: PromiseOrValue<string>,
    _stakeInterval: PromiseOrValue<BigNumberish>,
    _stakeStartTimeSlot: PromiseOrValue<BigNumberish>,
    _stakeAmount: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  collectReward(
    _stakeId: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  "collectRewardCleanupUser(address,uint32)"(
    _tokenAddress: PromiseOrValue<string>,
    _startTimeSlot: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  "collectRewardCleanupUser(address[],uint32[])"(
    _tokenAddresses: PromiseOrValue<string>[],
    _startTimeSlots: PromiseOrValue<BigNumberish>[],
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  rollingEarningsSumRatio(overrides?: CallOverrides): Promise<BigNumber>;

  stakeSumGetter(
    _tokenAddress: PromiseOrValue<string>,
    _timeSlot: PromiseOrValue<BigNumberish>,
    _stakeDayInterval: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  stakeTimePool(
    _stakeId: PromiseOrValue<BigNumberish>,
    _stakeInterval: PromiseOrValue<BigNumberish>,
    _stakeAmount: PromiseOrValue<BigNumberish>,
    _tokenAddress: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  timePoolStakes(
    arg0: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<
    [number, string, number, BigNumber, string, number] & {
      startTimeSlot: number;
      staker: string;
      stakeInterval: number;
      amount: BigNumber;
      tokenAddress: string;
      status: number;
    }
  >;

  timeSlotActivationBitMap(
    arg0: PromiseOrValue<string>,
    arg1: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<string>;

  timeSlotRewards(
    arg0: PromiseOrValue<string>,
    arg1: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<
    [BigNumber, BigNumber] & {
      totalSlotSum: BigNumber;
      totalEarningsPerSum: BigNumber;
    }
  >;

  callStatic: {
    batchStakeTimePool(
      _stakeIds: PromiseOrValue<BigNumberish>[],
      _stakeIntervals: PromiseOrValue<BigNumberish>[],
      _stakeAmounts: PromiseOrValue<BigNumberish>[],
      _tokenAddresses: PromiseOrValue<string>[],
      overrides?: CallOverrides
    ): Promise<void>;

    calculateReward(
      _tokenAddress: PromiseOrValue<string>,
      _stakeInterval: PromiseOrValue<BigNumberish>,
      _stakeStartTimeSlot: PromiseOrValue<BigNumberish>,
      _stakeAmount: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    collectReward(
      _stakeId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    "collectRewardCleanupUser(address,uint32)"(
      _tokenAddress: PromiseOrValue<string>,
      _startTimeSlot: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    "collectRewardCleanupUser(address[],uint32[])"(
      _tokenAddresses: PromiseOrValue<string>[],
      _startTimeSlots: PromiseOrValue<BigNumberish>[],
      overrides?: CallOverrides
    ): Promise<void>;

    rollingEarningsSumRatio(overrides?: CallOverrides): Promise<BigNumber>;

    stakeSumGetter(
      _tokenAddress: PromiseOrValue<string>,
      _timeSlot: PromiseOrValue<BigNumberish>,
      _stakeDayInterval: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    stakeTimePool(
      _stakeId: PromiseOrValue<BigNumberish>,
      _stakeInterval: PromiseOrValue<BigNumberish>,
      _stakeAmount: PromiseOrValue<BigNumberish>,
      _tokenAddress: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<void>;

    timePoolStakes(
      arg0: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<
      [number, string, number, BigNumber, string, number] & {
        startTimeSlot: number;
        staker: string;
        stakeInterval: number;
        amount: BigNumber;
        tokenAddress: string;
        status: number;
      }
    >;

    timeSlotActivationBitMap(
      arg0: PromiseOrValue<string>,
      arg1: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<string>;

    timeSlotRewards(
      arg0: PromiseOrValue<string>,
      arg1: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<
      [BigNumber, BigNumber] & {
        totalSlotSum: BigNumber;
        totalEarningsPerSum: BigNumber;
      }
    >;
  };

  filters: {
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

    "OwnershipChanged(address,address)"(
      oldOwner?: null,
      newOwner?: null
    ): OwnershipChangedEventFilter;
    OwnershipChanged(
      oldOwner?: null,
      newOwner?: null
    ): OwnershipChangedEventFilter;

    "Staked(uint32,uint8,uint256,address)"(
      timeStart?: null,
      stakeInterval?: null,
      stakeAmouunt?: null,
      staker?: null
    ): StakedEventFilter;
    Staked(
      timeStart?: null,
      stakeInterval?: null,
      stakeAmouunt?: null,
      staker?: null
    ): StakedEventFilter;

    "StakerRewardsCollected(address,uint256)"(
      staker?: null,
      amount?: null
    ): StakerRewardsCollectedEventFilter;
    StakerRewardsCollected(
      staker?: null,
      amount?: null
    ): StakerRewardsCollectedEventFilter;
  };

  estimateGas: {
    batchStakeTimePool(
      _stakeIds: PromiseOrValue<BigNumberish>[],
      _stakeIntervals: PromiseOrValue<BigNumberish>[],
      _stakeAmounts: PromiseOrValue<BigNumberish>[],
      _tokenAddresses: PromiseOrValue<string>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    calculateReward(
      _tokenAddress: PromiseOrValue<string>,
      _stakeInterval: PromiseOrValue<BigNumberish>,
      _stakeStartTimeSlot: PromiseOrValue<BigNumberish>,
      _stakeAmount: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    collectReward(
      _stakeId: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    "collectRewardCleanupUser(address,uint32)"(
      _tokenAddress: PromiseOrValue<string>,
      _startTimeSlot: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    "collectRewardCleanupUser(address[],uint32[])"(
      _tokenAddresses: PromiseOrValue<string>[],
      _startTimeSlots: PromiseOrValue<BigNumberish>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    rollingEarningsSumRatio(overrides?: CallOverrides): Promise<BigNumber>;

    stakeSumGetter(
      _tokenAddress: PromiseOrValue<string>,
      _timeSlot: PromiseOrValue<BigNumberish>,
      _stakeDayInterval: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    stakeTimePool(
      _stakeId: PromiseOrValue<BigNumberish>,
      _stakeInterval: PromiseOrValue<BigNumberish>,
      _stakeAmount: PromiseOrValue<BigNumberish>,
      _tokenAddress: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    timePoolStakes(
      arg0: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    timeSlotActivationBitMap(
      arg0: PromiseOrValue<string>,
      arg1: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    timeSlotRewards(
      arg0: PromiseOrValue<string>,
      arg1: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    batchStakeTimePool(
      _stakeIds: PromiseOrValue<BigNumberish>[],
      _stakeIntervals: PromiseOrValue<BigNumberish>[],
      _stakeAmounts: PromiseOrValue<BigNumberish>[],
      _tokenAddresses: PromiseOrValue<string>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    calculateReward(
      _tokenAddress: PromiseOrValue<string>,
      _stakeInterval: PromiseOrValue<BigNumberish>,
      _stakeStartTimeSlot: PromiseOrValue<BigNumberish>,
      _stakeAmount: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    collectReward(
      _stakeId: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    "collectRewardCleanupUser(address,uint32)"(
      _tokenAddress: PromiseOrValue<string>,
      _startTimeSlot: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    "collectRewardCleanupUser(address[],uint32[])"(
      _tokenAddresses: PromiseOrValue<string>[],
      _startTimeSlots: PromiseOrValue<BigNumberish>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    rollingEarningsSumRatio(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    stakeSumGetter(
      _tokenAddress: PromiseOrValue<string>,
      _timeSlot: PromiseOrValue<BigNumberish>,
      _stakeDayInterval: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    stakeTimePool(
      _stakeId: PromiseOrValue<BigNumberish>,
      _stakeInterval: PromiseOrValue<BigNumberish>,
      _stakeAmount: PromiseOrValue<BigNumberish>,
      _tokenAddress: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    timePoolStakes(
      arg0: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    timeSlotActivationBitMap(
      arg0: PromiseOrValue<string>,
      arg1: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    timeSlotRewards(
      arg0: PromiseOrValue<string>,
      arg1: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;
  };
}
