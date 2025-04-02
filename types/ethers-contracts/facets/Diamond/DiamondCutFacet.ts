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

export declare namespace IDiamondCut {
  export type FacetCutStruct = {
    facetAddress: PromiseOrValue<string>;
    action: PromiseOrValue<BigNumberish>;
    functionSelectors: PromiseOrValue<BytesLike>[];
  };

  export type FacetCutStructOutput = [string, number, string[]] & {
    facetAddress: string;
    action: number;
    functionSelectors: string[];
  };
}

export interface DiamondCutFacetInterface extends utils.Interface {
  functions: {
    "cancelMigration()": FunctionFragment;
    "diamondCut((address,uint8,bytes4[])[],address,bytes)": FunctionFragment;
    "initiateMigration()": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "cancelMigration"
      | "diamondCut"
      | "initiateMigration"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "cancelMigration",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "diamondCut",
    values: [
      IDiamondCut.FacetCutStruct[],
      PromiseOrValue<string>,
      PromiseOrValue<BytesLike>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "initiateMigration",
    values?: undefined
  ): string;

  decodeFunctionResult(
    functionFragment: "cancelMigration",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "diamondCut", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "initiateMigration",
    data: BytesLike
  ): Result;

  events: {
    "DiamondCut(tuple[],address,bytes)": EventFragment;
    "DiamondCut(tuple[],address,bytes)": EventFragment;
    "MigrationCancelled(address,uint32)": EventFragment;
    "MigrationInitiated(address,uint32)": EventFragment;
    "OwnershipChanged(address,address)": EventFragment;
  };

  getEvent(
    nameOrSignatureOrTopic: "DiamondCut(tuple[],address,bytes)"
  ): EventFragment;
  getEvent(
    nameOrSignatureOrTopic: "DiamondCut(tuple[],address,bytes)"
  ): EventFragment;
  getEvent(nameOrSignatureOrTopic: "MigrationCancelled"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "MigrationInitiated"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "OwnershipChanged"): EventFragment;
}

export interface DiamondCut_tuple_array_address_bytes_EventObject {
  _diamondCut: IDiamondCut.FacetCutStructOutput[];
  _init: string;
  _calldata: string;
}
export type DiamondCut_tuple_array_address_bytes_Event = TypedEvent<
  [IDiamondCut.FacetCutStructOutput[], string, string],
  DiamondCut_tuple_array_address_bytes_EventObject
>;

export type DiamondCut_tuple_array_address_bytes_EventFilter =
  TypedEventFilter<DiamondCut_tuple_array_address_bytes_Event>;

export interface DiamondCut_tuple_array_address_bytes_EventObject {
  _diamondCut: IDiamondCut.FacetCutStructOutput[];
  _init: string;
  _calldata: string;
}
export type DiamondCut_tuple_array_address_bytes_Event = TypedEvent<
  [IDiamondCut.FacetCutStructOutput[], string, string],
  DiamondCut_tuple_array_address_bytes_EventObject
>;

export type DiamondCut_tuple_array_address_bytes_EventFilter =
  TypedEventFilter<DiamondCut_tuple_array_address_bytes_Event>;

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

export interface DiamondCutFacet extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: DiamondCutFacetInterface;

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
    cancelMigration(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    diamondCut(
      _diamondCut: IDiamondCut.FacetCutStruct[],
      _init: PromiseOrValue<string>,
      _calldata: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    initiateMigration(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;
  };

  cancelMigration(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  diamondCut(
    _diamondCut: IDiamondCut.FacetCutStruct[],
    _init: PromiseOrValue<string>,
    _calldata: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  initiateMigration(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  callStatic: {
    cancelMigration(overrides?: CallOverrides): Promise<void>;

    diamondCut(
      _diamondCut: IDiamondCut.FacetCutStruct[],
      _init: PromiseOrValue<string>,
      _calldata: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<void>;

    initiateMigration(overrides?: CallOverrides): Promise<void>;
  };

  filters: {
    "DiamondCut(tuple[],address,bytes)"(
      _diamondCut?: null,
      _init?: null,
      _calldata?: null
    ): DiamondCut_tuple_array_address_bytes_EventFilter;
    "DiamondCut(tuple[],address,bytes)"(
      _diamondCut?: null,
      _init?: null,
      _calldata?: null
    ): DiamondCut_tuple_array_address_bytes_EventFilter;

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
  };

  estimateGas: {
    cancelMigration(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    diamondCut(
      _diamondCut: IDiamondCut.FacetCutStruct[],
      _init: PromiseOrValue<string>,
      _calldata: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    initiateMigration(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    cancelMigration(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    diamondCut(
      _diamondCut: IDiamondCut.FacetCutStruct[],
      _init: PromiseOrValue<string>,
      _calldata: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    initiateMigration(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;
  };
}
