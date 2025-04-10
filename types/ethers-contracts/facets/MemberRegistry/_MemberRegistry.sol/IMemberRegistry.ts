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
} from "../../../common";

export interface IMemberRegistryInterface extends utils.Interface {
  functions: {
    "verificationTime()": FunctionFragment;
  };

  getFunction(nameOrSignatureOrTopic: "verificationTime"): FunctionFragment;

  encodeFunctionData(
    functionFragment: "verificationTime",
    values?: undefined
  ): string;

  decodeFunctionResult(
    functionFragment: "verificationTime",
    data: BytesLike
  ): Result;

  events: {
    "MigrationCancelled(address,uint32)": EventFragment;
    "MigrationInitiated(address,uint32)": EventFragment;
    "OwnershipChanged(address,address)": EventFragment;
    "RecoveryAction(string,address,uint8)": EventFragment;
    "UserRegistered(string,address)": EventFragment;
    "UsersRegistered(string[],address[])": EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: "MigrationCancelled"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "MigrationInitiated"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "OwnershipChanged"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "RecoveryAction"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "UserRegistered"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "UsersRegistered"): EventFragment;
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

export interface RecoveryActionEventObject {
  username: string;
  userAddress: string;
  recoveryStatus: number;
}
export type RecoveryActionEvent = TypedEvent<
  [string, string, number],
  RecoveryActionEventObject
>;

export type RecoveryActionEventFilter = TypedEventFilter<RecoveryActionEvent>;

export interface UserRegisteredEventObject {
  username: string;
  userAddress: string;
}
export type UserRegisteredEvent = TypedEvent<
  [string, string],
  UserRegisteredEventObject
>;

export type UserRegisteredEventFilter = TypedEventFilter<UserRegisteredEvent>;

export interface UsersRegisteredEventObject {
  username: string[];
  userAddress: string[];
}
export type UsersRegisteredEvent = TypedEvent<
  [string[], string[]],
  UsersRegisteredEventObject
>;

export type UsersRegisteredEventFilter = TypedEventFilter<UsersRegisteredEvent>;

export interface IMemberRegistry extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: IMemberRegistryInterface;

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
    verificationTime(overrides?: CallOverrides): Promise<[number]>;
  };

  verificationTime(overrides?: CallOverrides): Promise<number>;

  callStatic: {
    verificationTime(overrides?: CallOverrides): Promise<number>;
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

    "RecoveryAction(string,address,uint8)"(
      username?: null,
      userAddress?: null,
      recoveryStatus?: null
    ): RecoveryActionEventFilter;
    RecoveryAction(
      username?: null,
      userAddress?: null,
      recoveryStatus?: null
    ): RecoveryActionEventFilter;

    "UserRegistered(string,address)"(
      username?: null,
      userAddress?: null
    ): UserRegisteredEventFilter;
    UserRegistered(
      username?: null,
      userAddress?: null
    ): UserRegisteredEventFilter;

    "UsersRegistered(string[],address[])"(
      username?: null,
      userAddress?: null
    ): UsersRegisteredEventFilter;
    UsersRegistered(
      username?: null,
      userAddress?: null
    ): UsersRegisteredEventFilter;
  };

  estimateGas: {
    verificationTime(overrides?: CallOverrides): Promise<BigNumber>;
  };

  populateTransaction: {
    verificationTime(overrides?: CallOverrides): Promise<PopulatedTransaction>;
  };
}
