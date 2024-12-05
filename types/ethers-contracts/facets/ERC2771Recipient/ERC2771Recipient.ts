/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BigNumber,
  BytesLike,
  CallOverrides,
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

export interface ERC2771RecipientInterface extends utils.Interface {
  functions: {
    "getTrustedForwarder()": FunctionFragment;
    "isTrustedForwarder(address)": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic: "getTrustedForwarder" | "isTrustedForwarder"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "getTrustedForwarder",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "isTrustedForwarder",
    values: [PromiseOrValue<string>]
  ): string;

  decodeFunctionResult(
    functionFragment: "getTrustedForwarder",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "isTrustedForwarder",
    data: BytesLike
  ): Result;

  events: {
    "MigrationCancelled(address,uint32)": EventFragment;
    "MigrationInitiated(address,uint32)": EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: "MigrationCancelled"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "MigrationInitiated"): EventFragment;
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

export interface ERC2771Recipient extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: ERC2771RecipientInterface;

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
    getTrustedForwarder(
      overrides?: CallOverrides
    ): Promise<[string] & { forwarder: string }>;

    isTrustedForwarder(
      forwarder: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<[boolean] & { trusted_: boolean }>;
  };

  getTrustedForwarder(overrides?: CallOverrides): Promise<string>;

  isTrustedForwarder(
    forwarder: PromiseOrValue<string>,
    overrides?: CallOverrides
  ): Promise<boolean>;

  callStatic: {
    getTrustedForwarder(overrides?: CallOverrides): Promise<string>;

    isTrustedForwarder(
      forwarder: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<boolean>;
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
  };

  estimateGas: {
    getTrustedForwarder(overrides?: CallOverrides): Promise<BigNumber>;

    isTrustedForwarder(
      forwarder: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    getTrustedForwarder(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    isTrustedForwarder(
      forwarder: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;
  };
}
