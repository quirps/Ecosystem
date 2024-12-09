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

export declare namespace IPOCreate {
  export type OffChainPurchaseStruct = {
    user: PromiseOrValue<string>;
    purchaseId: PromiseOrValue<BigNumberish>;
    amount: PromiseOrValue<BigNumberish>;
    isCollected: PromiseOrValue<boolean>;
  };

  export type OffChainPurchaseStructOutput = [
    string,
    BigNumber,
    BigNumber,
    boolean
  ] & {
    user: string;
    purchaseId: BigNumber;
    amount: BigNumber;
    isCollected: boolean;
  };

  export type EcosystemStruct = {
    ownerAddress: PromiseOrValue<string>;
    ecosystemAddress: PromiseOrValue<string>;
    IPOFundAddress: PromiseOrValue<string>;
  };

  export type EcosystemStructOutput = [string, string, string] & {
    ownerAddress: string;
    ecosystemAddress: string;
    IPOFundAddress: string;
  };

  export type OutputCurrencyStruct = {
    isBaseCurrency: PromiseOrValue<boolean>;
    tokenAddress: PromiseOrValue<string>;
  };

  export type OutputCurrencyStructOutput = [boolean, string] & {
    isBaseCurrency: boolean;
    tokenAddress: string;
  };
}

export interface IPOCreateInterface extends utils.Interface {
  functions: {
    "getOffchainPurchase(uint256,bytes32[],(address,uint256,uint256,bool))": FunctionFragment;
    "getOffchainPurchaseOwner(uint256,address[],uint256[])": FunctionFragment;
    "getOnChainPurchase(uint256,uint256)": FunctionFragment;
    "setIPO(uint256,bytes32,uint256,uint256,uint256,uint32,(address,address,address),(bool,address))": FunctionFragment;
    "uploadIPOMerkleRoot(uint256,bytes32)": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "getOffchainPurchase"
      | "getOffchainPurchaseOwner"
      | "getOnChainPurchase"
      | "setIPO"
      | "uploadIPOMerkleRoot"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "getOffchainPurchase",
    values: [
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BytesLike>[],
      IPOCreate.OffChainPurchaseStruct
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "getOffchainPurchaseOwner",
    values: [
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<string>[],
      PromiseOrValue<BigNumberish>[]
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "getOnChainPurchase",
    values: [PromiseOrValue<BigNumberish>, PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "setIPO",
    values: [
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BytesLike>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>,
      IPOCreate.EcosystemStruct,
      IPOCreate.OutputCurrencyStruct
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "uploadIPOMerkleRoot",
    values: [PromiseOrValue<BigNumberish>, PromiseOrValue<BytesLike>]
  ): string;

  decodeFunctionResult(
    functionFragment: "getOffchainPurchase",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getOffchainPurchaseOwner",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getOnChainPurchase",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "setIPO", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "uploadIPOMerkleRoot",
    data: BytesLike
  ): Result;

  events: {
    "IPOCreated(uint256,uint256,uint256)": EventFragment;
    "IPOPurchaseConsumed(address,uint256,bool)": EventFragment;
    "MigrationCancelled(address,uint32)": EventFragment;
    "MigrationInitiated(address,uint32)": EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: "IPOCreated"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "IPOPurchaseConsumed"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "MigrationCancelled"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "MigrationInitiated"): EventFragment;
}

export interface IPOCreatedEventObject {
  totalAmount: BigNumber;
  maxAmountPerUser: BigNumber;
  ratio: BigNumber;
}
export type IPOCreatedEvent = TypedEvent<
  [BigNumber, BigNumber, BigNumber],
  IPOCreatedEventObject
>;

export type IPOCreatedEventFilter = TypedEventFilter<IPOCreatedEvent>;

export interface IPOPurchaseConsumedEventObject {
  tokenReceiver: string;
  amount: BigNumber;
  isOnChainPurchase: boolean;
}
export type IPOPurchaseConsumedEvent = TypedEvent<
  [string, BigNumber, boolean],
  IPOPurchaseConsumedEventObject
>;

export type IPOPurchaseConsumedEventFilter =
  TypedEventFilter<IPOPurchaseConsumedEvent>;

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

export interface IPOCreate extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: IPOCreateInterface;

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
    getOffchainPurchase(
      IPOid: PromiseOrValue<BigNumberish>,
      proof: PromiseOrValue<BytesLike>[],
      leaf: IPOCreate.OffChainPurchaseStruct,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    getOffchainPurchaseOwner(
      IPOid: PromiseOrValue<BigNumberish>,
      fundedUsers: PromiseOrValue<string>[],
      offChainPurchaseId: PromiseOrValue<BigNumberish>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    getOnChainPurchase(
      amount: PromiseOrValue<BigNumberish>,
      IPOid: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    setIPO(
      IPOid: PromiseOrValue<BigNumberish>,
      _merkleRoot: PromiseOrValue<BytesLike>,
      _totalAmount: PromiseOrValue<BigNumberish>,
      _maxAmountPerUser: PromiseOrValue<BigNumberish>,
      _ratio: PromiseOrValue<BigNumberish>,
      _deadline: PromiseOrValue<BigNumberish>,
      _ecosystem: IPOCreate.EcosystemStruct,
      _outputCurrency: IPOCreate.OutputCurrencyStruct,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    uploadIPOMerkleRoot(
      IPOid: PromiseOrValue<BigNumberish>,
      _merkleRoot: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;
  };

  getOffchainPurchase(
    IPOid: PromiseOrValue<BigNumberish>,
    proof: PromiseOrValue<BytesLike>[],
    leaf: IPOCreate.OffChainPurchaseStruct,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  getOffchainPurchaseOwner(
    IPOid: PromiseOrValue<BigNumberish>,
    fundedUsers: PromiseOrValue<string>[],
    offChainPurchaseId: PromiseOrValue<BigNumberish>[],
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  getOnChainPurchase(
    amount: PromiseOrValue<BigNumberish>,
    IPOid: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  setIPO(
    IPOid: PromiseOrValue<BigNumberish>,
    _merkleRoot: PromiseOrValue<BytesLike>,
    _totalAmount: PromiseOrValue<BigNumberish>,
    _maxAmountPerUser: PromiseOrValue<BigNumberish>,
    _ratio: PromiseOrValue<BigNumberish>,
    _deadline: PromiseOrValue<BigNumberish>,
    _ecosystem: IPOCreate.EcosystemStruct,
    _outputCurrency: IPOCreate.OutputCurrencyStruct,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  uploadIPOMerkleRoot(
    IPOid: PromiseOrValue<BigNumberish>,
    _merkleRoot: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  callStatic: {
    getOffchainPurchase(
      IPOid: PromiseOrValue<BigNumberish>,
      proof: PromiseOrValue<BytesLike>[],
      leaf: IPOCreate.OffChainPurchaseStruct,
      overrides?: CallOverrides
    ): Promise<void>;

    getOffchainPurchaseOwner(
      IPOid: PromiseOrValue<BigNumberish>,
      fundedUsers: PromiseOrValue<string>[],
      offChainPurchaseId: PromiseOrValue<BigNumberish>[],
      overrides?: CallOverrides
    ): Promise<void>;

    getOnChainPurchase(
      amount: PromiseOrValue<BigNumberish>,
      IPOid: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    setIPO(
      IPOid: PromiseOrValue<BigNumberish>,
      _merkleRoot: PromiseOrValue<BytesLike>,
      _totalAmount: PromiseOrValue<BigNumberish>,
      _maxAmountPerUser: PromiseOrValue<BigNumberish>,
      _ratio: PromiseOrValue<BigNumberish>,
      _deadline: PromiseOrValue<BigNumberish>,
      _ecosystem: IPOCreate.EcosystemStruct,
      _outputCurrency: IPOCreate.OutputCurrencyStruct,
      overrides?: CallOverrides
    ): Promise<void>;

    uploadIPOMerkleRoot(
      IPOid: PromiseOrValue<BigNumberish>,
      _merkleRoot: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<void>;
  };

  filters: {
    "IPOCreated(uint256,uint256,uint256)"(
      totalAmount?: null,
      maxAmountPerUser?: null,
      ratio?: null
    ): IPOCreatedEventFilter;
    IPOCreated(
      totalAmount?: null,
      maxAmountPerUser?: null,
      ratio?: null
    ): IPOCreatedEventFilter;

    "IPOPurchaseConsumed(address,uint256,bool)"(
      tokenReceiver?: null,
      amount?: null,
      isOnChainPurchase?: null
    ): IPOPurchaseConsumedEventFilter;
    IPOPurchaseConsumed(
      tokenReceiver?: null,
      amount?: null,
      isOnChainPurchase?: null
    ): IPOPurchaseConsumedEventFilter;

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
    getOffchainPurchase(
      IPOid: PromiseOrValue<BigNumberish>,
      proof: PromiseOrValue<BytesLike>[],
      leaf: IPOCreate.OffChainPurchaseStruct,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    getOffchainPurchaseOwner(
      IPOid: PromiseOrValue<BigNumberish>,
      fundedUsers: PromiseOrValue<string>[],
      offChainPurchaseId: PromiseOrValue<BigNumberish>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    getOnChainPurchase(
      amount: PromiseOrValue<BigNumberish>,
      IPOid: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    setIPO(
      IPOid: PromiseOrValue<BigNumberish>,
      _merkleRoot: PromiseOrValue<BytesLike>,
      _totalAmount: PromiseOrValue<BigNumberish>,
      _maxAmountPerUser: PromiseOrValue<BigNumberish>,
      _ratio: PromiseOrValue<BigNumberish>,
      _deadline: PromiseOrValue<BigNumberish>,
      _ecosystem: IPOCreate.EcosystemStruct,
      _outputCurrency: IPOCreate.OutputCurrencyStruct,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    uploadIPOMerkleRoot(
      IPOid: PromiseOrValue<BigNumberish>,
      _merkleRoot: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    getOffchainPurchase(
      IPOid: PromiseOrValue<BigNumberish>,
      proof: PromiseOrValue<BytesLike>[],
      leaf: IPOCreate.OffChainPurchaseStruct,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    getOffchainPurchaseOwner(
      IPOid: PromiseOrValue<BigNumberish>,
      fundedUsers: PromiseOrValue<string>[],
      offChainPurchaseId: PromiseOrValue<BigNumberish>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    getOnChainPurchase(
      amount: PromiseOrValue<BigNumberish>,
      IPOid: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    setIPO(
      IPOid: PromiseOrValue<BigNumberish>,
      _merkleRoot: PromiseOrValue<BytesLike>,
      _totalAmount: PromiseOrValue<BigNumberish>,
      _maxAmountPerUser: PromiseOrValue<BigNumberish>,
      _ratio: PromiseOrValue<BigNumberish>,
      _deadline: PromiseOrValue<BigNumberish>,
      _ecosystem: IPOCreate.EcosystemStruct,
      _outputCurrency: IPOCreate.OutputCurrencyStruct,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    uploadIPOMerkleRoot(
      IPOid: PromiseOrValue<BigNumberish>,
      _merkleRoot: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;
  };
}
