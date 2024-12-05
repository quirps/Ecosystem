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
import type { FunctionFragment, Result } from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type {
  TypedEventFilter,
  TypedEvent,
  TypedListener,
  OnEvent,
  PromiseOrValue,
} from "../../common";

export declare namespace IStake {
  export type RewardRateStruct = {
    initialRate: PromiseOrValue<BigNumberish>;
    rateIncrease: PromiseOrValue<BigNumberish>;
    rateIncreaseStopDuration: PromiseOrValue<BigNumberish>;
  };

  export type RewardRateStructOutput = [number, number, number] & {
    initialRate: number;
    rateIncrease: number;
    rateIncreaseStopDuration: number;
  };
}

export interface IStakeInterface extends utils.Interface {
  functions: {
    "batchStake(address[],uint256[],uint8[],uint256[])": FunctionFragment;
    "fundStakeAccount(uint256)": FunctionFragment;
    "setRewardRates(uint8[],(uint16,uint16,uint16)[])": FunctionFragment;
    "stake(address,uint256,uint8,uint256)": FunctionFragment;
    "unstake(address,uint256,uint256)": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "batchStake"
      | "fundStakeAccount"
      | "setRewardRates"
      | "stake"
      | "unstake"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "batchStake",
    values: [
      PromiseOrValue<string>[],
      PromiseOrValue<BigNumberish>[],
      PromiseOrValue<BigNumberish>[],
      PromiseOrValue<BigNumberish>[]
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "fundStakeAccount",
    values: [PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "setRewardRates",
    values: [PromiseOrValue<BigNumberish>[], IStake.RewardRateStruct[]]
  ): string;
  encodeFunctionData(
    functionFragment: "stake",
    values: [
      PromiseOrValue<string>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "unstake",
    values: [
      PromiseOrValue<string>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>
    ]
  ): string;

  decodeFunctionResult(functionFragment: "batchStake", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "fundStakeAccount",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "setRewardRates",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "stake", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "unstake", data: BytesLike): Result;

  events: {};
}

export interface IStake extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: IStakeInterface;

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
    batchStake(
      user: PromiseOrValue<string>[],
      amount: PromiseOrValue<BigNumberish>[],
      tier: PromiseOrValue<BigNumberish>[],
      stakeIds: PromiseOrValue<BigNumberish>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    fundStakeAccount(
      amount: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    setRewardRates(
      _stakeTier: PromiseOrValue<BigNumberish>[],
      _rewardRate: IStake.RewardRateStruct[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    stake(
      user: PromiseOrValue<string>,
      amount: PromiseOrValue<BigNumberish>,
      tier: PromiseOrValue<BigNumberish>,
      stakeId: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    unstake(
      user: PromiseOrValue<string>,
      amount: PromiseOrValue<BigNumberish>,
      stakeId: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;
  };

  batchStake(
    user: PromiseOrValue<string>[],
    amount: PromiseOrValue<BigNumberish>[],
    tier: PromiseOrValue<BigNumberish>[],
    stakeIds: PromiseOrValue<BigNumberish>[],
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  fundStakeAccount(
    amount: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  setRewardRates(
    _stakeTier: PromiseOrValue<BigNumberish>[],
    _rewardRate: IStake.RewardRateStruct[],
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  stake(
    user: PromiseOrValue<string>,
    amount: PromiseOrValue<BigNumberish>,
    tier: PromiseOrValue<BigNumberish>,
    stakeId: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  unstake(
    user: PromiseOrValue<string>,
    amount: PromiseOrValue<BigNumberish>,
    stakeId: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  callStatic: {
    batchStake(
      user: PromiseOrValue<string>[],
      amount: PromiseOrValue<BigNumberish>[],
      tier: PromiseOrValue<BigNumberish>[],
      stakeIds: PromiseOrValue<BigNumberish>[],
      overrides?: CallOverrides
    ): Promise<void>;

    fundStakeAccount(
      amount: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    setRewardRates(
      _stakeTier: PromiseOrValue<BigNumberish>[],
      _rewardRate: IStake.RewardRateStruct[],
      overrides?: CallOverrides
    ): Promise<void>;

    stake(
      user: PromiseOrValue<string>,
      amount: PromiseOrValue<BigNumberish>,
      tier: PromiseOrValue<BigNumberish>,
      stakeId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    unstake(
      user: PromiseOrValue<string>,
      amount: PromiseOrValue<BigNumberish>,
      stakeId: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;
  };

  filters: {};

  estimateGas: {
    batchStake(
      user: PromiseOrValue<string>[],
      amount: PromiseOrValue<BigNumberish>[],
      tier: PromiseOrValue<BigNumberish>[],
      stakeIds: PromiseOrValue<BigNumberish>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    fundStakeAccount(
      amount: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    setRewardRates(
      _stakeTier: PromiseOrValue<BigNumberish>[],
      _rewardRate: IStake.RewardRateStruct[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    stake(
      user: PromiseOrValue<string>,
      amount: PromiseOrValue<BigNumberish>,
      tier: PromiseOrValue<BigNumberish>,
      stakeId: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    unstake(
      user: PromiseOrValue<string>,
      amount: PromiseOrValue<BigNumberish>,
      stakeId: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    batchStake(
      user: PromiseOrValue<string>[],
      amount: PromiseOrValue<BigNumberish>[],
      tier: PromiseOrValue<BigNumberish>[],
      stakeIds: PromiseOrValue<BigNumberish>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    fundStakeAccount(
      amount: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    setRewardRates(
      _stakeTier: PromiseOrValue<BigNumberish>[],
      _rewardRate: IStake.RewardRateStruct[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    stake(
      user: PromiseOrValue<string>,
      amount: PromiseOrValue<BigNumberish>,
      tier: PromiseOrValue<BigNumberish>,
      stakeId: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    unstake(
      user: PromiseOrValue<string>,
      amount: PromiseOrValue<BigNumberish>,
      stakeId: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;
  };
}
