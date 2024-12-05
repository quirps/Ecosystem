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

export declare namespace LibEventFactory {
  export type TicketDetailStruct = {
    minAmount: PromiseOrValue<BigNumberish>;
    maxAmount: PromiseOrValue<BigNumberish>;
  };

  export type TicketDetailStructOutput = [BigNumber, BigNumber] & {
    minAmount: BigNumber;
    maxAmount: BigNumber;
  };
}

export interface IEventFactoryInterface extends utils.Interface {
  functions: {
    "createEvent(uint32,uint32,uint256,uint256,string,uint256[],(uint256,uint256)[])": FunctionFragment;
    "deactivateEvent(uint256,bytes32)": FunctionFragment;
    "extendEvent(uint256,uint32)": FunctionFragment;
    "redeemTickets(uint256,uint256[],uint256[])": FunctionFragment;
    "refundTicketsWithProof(uint256,uint256[],address,address,bytes32[])": FunctionFragment;
    "setImageUri(uint256,string)": FunctionFragment;
    "setMerkleRoot(uint256,bytes32)": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "createEvent"
      | "deactivateEvent"
      | "extendEvent"
      | "redeemTickets"
      | "refundTicketsWithProof"
      | "setImageUri"
      | "setMerkleRoot"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "createEvent",
    values: [
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<string>,
      PromiseOrValue<BigNumberish>[],
      LibEventFactory.TicketDetailStruct[]
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "deactivateEvent",
    values: [PromiseOrValue<BigNumberish>, PromiseOrValue<BytesLike>]
  ): string;
  encodeFunctionData(
    functionFragment: "extendEvent",
    values: [PromiseOrValue<BigNumberish>, PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "redeemTickets",
    values: [
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>[],
      PromiseOrValue<BigNumberish>[]
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "refundTicketsWithProof",
    values: [
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>[],
      PromiseOrValue<string>,
      PromiseOrValue<string>,
      PromiseOrValue<BytesLike>[]
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "setImageUri",
    values: [PromiseOrValue<BigNumberish>, PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "setMerkleRoot",
    values: [PromiseOrValue<BigNumberish>, PromiseOrValue<BytesLike>]
  ): string;

  decodeFunctionResult(
    functionFragment: "createEvent",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "deactivateEvent",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "extendEvent",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "redeemTickets",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "refundTicketsWithProof",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "setImageUri",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "setMerkleRoot",
    data: BytesLike
  ): Result;

  events: {};
}

export interface IEventFactory extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: IEventFactoryInterface;

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
    createEvent(
      _startTime: PromiseOrValue<BigNumberish>,
      _endTime: PromiseOrValue<BigNumberish>,
      _minEntries: PromiseOrValue<BigNumberish>,
      _maxEntries: PromiseOrValue<BigNumberish>,
      _imageUri: PromiseOrValue<string>,
      _ticketIds: PromiseOrValue<BigNumberish>[],
      _ticketDetails: LibEventFactory.TicketDetailStruct[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    deactivateEvent(
      eventId: PromiseOrValue<BigNumberish>,
      root: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    extendEvent(
      eventId: PromiseOrValue<BigNumberish>,
      addedTime: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    redeemTickets(
      eventId: PromiseOrValue<BigNumberish>,
      ticketIds: PromiseOrValue<BigNumberish>[],
      amounts: PromiseOrValue<BigNumberish>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    refundTicketsWithProof(
      eventId: PromiseOrValue<BigNumberish>,
      ticketIds: PromiseOrValue<BigNumberish>[],
      lowerBound: PromiseOrValue<string>,
      upperBound: PromiseOrValue<string>,
      merkleProof: PromiseOrValue<BytesLike>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    setImageUri(
      eventId: PromiseOrValue<BigNumberish>,
      imageUri: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    setMerkleRoot(
      eventId: PromiseOrValue<BigNumberish>,
      merkleRoot: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;
  };

  createEvent(
    _startTime: PromiseOrValue<BigNumberish>,
    _endTime: PromiseOrValue<BigNumberish>,
    _minEntries: PromiseOrValue<BigNumberish>,
    _maxEntries: PromiseOrValue<BigNumberish>,
    _imageUri: PromiseOrValue<string>,
    _ticketIds: PromiseOrValue<BigNumberish>[],
    _ticketDetails: LibEventFactory.TicketDetailStruct[],
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  deactivateEvent(
    eventId: PromiseOrValue<BigNumberish>,
    root: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  extendEvent(
    eventId: PromiseOrValue<BigNumberish>,
    addedTime: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  redeemTickets(
    eventId: PromiseOrValue<BigNumberish>,
    ticketIds: PromiseOrValue<BigNumberish>[],
    amounts: PromiseOrValue<BigNumberish>[],
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  refundTicketsWithProof(
    eventId: PromiseOrValue<BigNumberish>,
    ticketIds: PromiseOrValue<BigNumberish>[],
    lowerBound: PromiseOrValue<string>,
    upperBound: PromiseOrValue<string>,
    merkleProof: PromiseOrValue<BytesLike>[],
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  setImageUri(
    eventId: PromiseOrValue<BigNumberish>,
    imageUri: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  setMerkleRoot(
    eventId: PromiseOrValue<BigNumberish>,
    merkleRoot: PromiseOrValue<BytesLike>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  callStatic: {
    createEvent(
      _startTime: PromiseOrValue<BigNumberish>,
      _endTime: PromiseOrValue<BigNumberish>,
      _minEntries: PromiseOrValue<BigNumberish>,
      _maxEntries: PromiseOrValue<BigNumberish>,
      _imageUri: PromiseOrValue<string>,
      _ticketIds: PromiseOrValue<BigNumberish>[],
      _ticketDetails: LibEventFactory.TicketDetailStruct[],
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    deactivateEvent(
      eventId: PromiseOrValue<BigNumberish>,
      root: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<void>;

    extendEvent(
      eventId: PromiseOrValue<BigNumberish>,
      addedTime: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    redeemTickets(
      eventId: PromiseOrValue<BigNumberish>,
      ticketIds: PromiseOrValue<BigNumberish>[],
      amounts: PromiseOrValue<BigNumberish>[],
      overrides?: CallOverrides
    ): Promise<void>;

    refundTicketsWithProof(
      eventId: PromiseOrValue<BigNumberish>,
      ticketIds: PromiseOrValue<BigNumberish>[],
      lowerBound: PromiseOrValue<string>,
      upperBound: PromiseOrValue<string>,
      merkleProof: PromiseOrValue<BytesLike>[],
      overrides?: CallOverrides
    ): Promise<void>;

    setImageUri(
      eventId: PromiseOrValue<BigNumberish>,
      imageUri: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<void>;

    setMerkleRoot(
      eventId: PromiseOrValue<BigNumberish>,
      merkleRoot: PromiseOrValue<BytesLike>,
      overrides?: CallOverrides
    ): Promise<void>;
  };

  filters: {};

  estimateGas: {
    createEvent(
      _startTime: PromiseOrValue<BigNumberish>,
      _endTime: PromiseOrValue<BigNumberish>,
      _minEntries: PromiseOrValue<BigNumberish>,
      _maxEntries: PromiseOrValue<BigNumberish>,
      _imageUri: PromiseOrValue<string>,
      _ticketIds: PromiseOrValue<BigNumberish>[],
      _ticketDetails: LibEventFactory.TicketDetailStruct[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    deactivateEvent(
      eventId: PromiseOrValue<BigNumberish>,
      root: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    extendEvent(
      eventId: PromiseOrValue<BigNumberish>,
      addedTime: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    redeemTickets(
      eventId: PromiseOrValue<BigNumberish>,
      ticketIds: PromiseOrValue<BigNumberish>[],
      amounts: PromiseOrValue<BigNumberish>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    refundTicketsWithProof(
      eventId: PromiseOrValue<BigNumberish>,
      ticketIds: PromiseOrValue<BigNumberish>[],
      lowerBound: PromiseOrValue<string>,
      upperBound: PromiseOrValue<string>,
      merkleProof: PromiseOrValue<BytesLike>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    setImageUri(
      eventId: PromiseOrValue<BigNumberish>,
      imageUri: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    setMerkleRoot(
      eventId: PromiseOrValue<BigNumberish>,
      merkleRoot: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    createEvent(
      _startTime: PromiseOrValue<BigNumberish>,
      _endTime: PromiseOrValue<BigNumberish>,
      _minEntries: PromiseOrValue<BigNumberish>,
      _maxEntries: PromiseOrValue<BigNumberish>,
      _imageUri: PromiseOrValue<string>,
      _ticketIds: PromiseOrValue<BigNumberish>[],
      _ticketDetails: LibEventFactory.TicketDetailStruct[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    deactivateEvent(
      eventId: PromiseOrValue<BigNumberish>,
      root: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    extendEvent(
      eventId: PromiseOrValue<BigNumberish>,
      addedTime: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    redeemTickets(
      eventId: PromiseOrValue<BigNumberish>,
      ticketIds: PromiseOrValue<BigNumberish>[],
      amounts: PromiseOrValue<BigNumberish>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    refundTicketsWithProof(
      eventId: PromiseOrValue<BigNumberish>,
      ticketIds: PromiseOrValue<BigNumberish>[],
      lowerBound: PromiseOrValue<string>,
      upperBound: PromiseOrValue<string>,
      merkleProof: PromiseOrValue<BytesLike>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    setImageUri(
      eventId: PromiseOrValue<BigNumberish>,
      imageUri: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    setMerkleRoot(
      eventId: PromiseOrValue<BigNumberish>,
      merkleRoot: PromiseOrValue<BytesLike>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;
  };
}
