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

export declare namespace Swap {
  export type SwapStruct = {
    token: PromiseOrValue<string>;
    amount: PromiseOrValue<BigNumberish>;
  };

  export type SwapStructOutput = [string, BigNumber] & {
    token: string;
    amount: BigNumber;
  };
}

export interface SwapInterface extends utils.Interface {
  functions: {
    "cancelSwapOrder(uint256,address,address)": FunctionFragment;
    "getOffchainPurchase(uint256,bytes32[],(address,uint256,uint256,bool))": FunctionFragment;
    "getOffchainPurchaseOwner(uint256,address[],uint256[])": FunctionFragment;
    "getOnChainPurchase(uint256,uint256)": FunctionFragment;
    "setIPO(uint256,bytes32,uint256,uint256,uint256,uint32,(address,address,address),(bool,address))": FunctionFragment;
    "swap((address,uint256),(address,uint256),uint256[],uint256,bool)": FunctionFragment;
    "uploadIPOMerkleRoot(uint256,bytes32)": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "cancelSwapOrder"
      | "getOffchainPurchase"
      | "getOffchainPurchaseOwner"
      | "getOnChainPurchase"
      | "setIPO"
      | "swap"
      | "uploadIPOMerkleRoot"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "cancelSwapOrder",
    values: [
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<string>,
      PromiseOrValue<string>
    ]
  ): string;
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
    functionFragment: "swap",
    values: [
      Swap.SwapStruct,
      Swap.SwapStruct,
      PromiseOrValue<BigNumberish>[],
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<boolean>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "uploadIPOMerkleRoot",
    values: [PromiseOrValue<BigNumberish>, PromiseOrValue<BytesLike>]
  ): string;

  decodeFunctionResult(
    functionFragment: "cancelSwapOrder",
    data: BytesLike
  ): Result;
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
  decodeFunctionResult(functionFragment: "swap", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "uploadIPOMerkleRoot",
    data: BytesLike
  ): Result;

  events: {
    "Fill(address,address,uint256,uint256,uint8)": EventFragment;
    "IPOCreated(uint256,uint256,uint256)": EventFragment;
    "IPOPurchaseConsumed(address,uint256,bool)": EventFragment;
    "MigrationCancelled(address,uint32)": EventFragment;
    "MigrationInitiated(address,uint32)": EventFragment;
    "SwapCancelled(address,uint256,uint256)": EventFragment;
    "SwapOrderSubmitted(address,address,address,uint256)": EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: "Fill"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "IPOCreated"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "IPOPurchaseConsumed"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "MigrationCancelled"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "MigrationInitiated"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "SwapCancelled"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "SwapOrderSubmitted"): EventFragment;
}

export interface FillEventObject {
  inputSwap: string;
  outputSwap: string;
  ratio: BigNumber;
  outputAmount: BigNumber;
  orderFillType: number;
}
export type FillEvent = TypedEvent<
  [string, string, BigNumber, BigNumber, number],
  FillEventObject
>;

export type FillEventFilter = TypedEventFilter<FillEvent>;

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

export interface SwapCancelledEventObject {
  marketMaker: string;
  ratio: BigNumber;
  amount: BigNumber;
}
export type SwapCancelledEvent = TypedEvent<
  [string, BigNumber, BigNumber],
  SwapCancelledEventObject
>;

export type SwapCancelledEventFilter = TypedEventFilter<SwapCancelledEvent>;

export interface SwapOrderSubmittedEventObject {
  swapIntiaitor: string;
  inputSwapToken: string;
  outputSwapToken: string;
  inputSwapAmount: BigNumber;
}
export type SwapOrderSubmittedEvent = TypedEvent<
  [string, string, string, BigNumber],
  SwapOrderSubmittedEventObject
>;

export type SwapOrderSubmittedEventFilter =
  TypedEventFilter<SwapOrderSubmittedEvent>;

export interface Swap extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: SwapInterface;

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
    cancelSwapOrder(
      ratio: PromiseOrValue<BigNumberish>,
      token1: PromiseOrValue<string>,
      token2: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

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

    swap(
      inputSwap: Swap.SwapStruct,
      outputSwap: Swap.SwapStruct,
      targetOrders: PromiseOrValue<BigNumberish>[],
      _stakeId: PromiseOrValue<BigNumberish>,
      isOrder: PromiseOrValue<boolean>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    uploadIPOMerkleRoot(
      IPOid: PromiseOrValue<BigNumberish>,
      _merkleRoot: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;
  };

  cancelSwapOrder(
    ratio: PromiseOrValue<BigNumberish>,
    token1: PromiseOrValue<string>,
    token2: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

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

  swap(
    inputSwap: Swap.SwapStruct,
    outputSwap: Swap.SwapStruct,
    targetOrders: PromiseOrValue<BigNumberish>[],
    _stakeId: PromiseOrValue<BigNumberish>,
    isOrder: PromiseOrValue<boolean>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  uploadIPOMerkleRoot(
    IPOid: PromiseOrValue<BigNumberish>,
    _merkleRoot: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  callStatic: {
    cancelSwapOrder(
      ratio: PromiseOrValue<BigNumberish>,
      token1: PromiseOrValue<string>,
      token2: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<void>;

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

    swap(
      inputSwap: Swap.SwapStruct,
      outputSwap: Swap.SwapStruct,
      targetOrders: PromiseOrValue<BigNumberish>[],
      _stakeId: PromiseOrValue<BigNumberish>,
      isOrder: PromiseOrValue<boolean>,
      overrides?: CallOverrides
    ): Promise<void>;

    uploadIPOMerkleRoot(
      IPOid: PromiseOrValue<BigNumberish>,
      _merkleRoot: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<void>;
  };

  filters: {
    "Fill(address,address,uint256,uint256,uint8)"(
      inputSwap?: null,
      outputSwap?: null,
      ratio?: null,
      outputAmount?: null,
      orderFillType?: null
    ): FillEventFilter;
    Fill(
      inputSwap?: null,
      outputSwap?: null,
      ratio?: null,
      outputAmount?: null,
      orderFillType?: null
    ): FillEventFilter;

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

    "SwapCancelled(address,uint256,uint256)"(
      marketMaker?: null,
      ratio?: null,
      amount?: null
    ): SwapCancelledEventFilter;
    SwapCancelled(
      marketMaker?: null,
      ratio?: null,
      amount?: null
    ): SwapCancelledEventFilter;

    "SwapOrderSubmitted(address,address,address,uint256)"(
      swapIntiaitor?: null,
      inputSwapToken?: null,
      outputSwapToken?: null,
      inputSwapAmount?: null
    ): SwapOrderSubmittedEventFilter;
    SwapOrderSubmitted(
      swapIntiaitor?: null,
      inputSwapToken?: null,
      outputSwapToken?: null,
      inputSwapAmount?: null
    ): SwapOrderSubmittedEventFilter;
  };

  estimateGas: {
    cancelSwapOrder(
      ratio: PromiseOrValue<BigNumberish>,
      token1: PromiseOrValue<string>,
      token2: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

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

    swap(
      inputSwap: Swap.SwapStruct,
      outputSwap: Swap.SwapStruct,
      targetOrders: PromiseOrValue<BigNumberish>[],
      _stakeId: PromiseOrValue<BigNumberish>,
      isOrder: PromiseOrValue<boolean>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    uploadIPOMerkleRoot(
      IPOid: PromiseOrValue<BigNumberish>,
      _merkleRoot: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    cancelSwapOrder(
      ratio: PromiseOrValue<BigNumberish>,
      token1: PromiseOrValue<string>,
      token2: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

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

    swap(
      inputSwap: Swap.SwapStruct,
      outputSwap: Swap.SwapStruct,
      targetOrders: PromiseOrValue<BigNumberish>[],
      _stakeId: PromiseOrValue<BigNumberish>,
      isOrder: PromiseOrValue<boolean>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    uploadIPOMerkleRoot(
      IPOid: PromiseOrValue<BigNumberish>,
      _merkleRoot: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;
  };
}
