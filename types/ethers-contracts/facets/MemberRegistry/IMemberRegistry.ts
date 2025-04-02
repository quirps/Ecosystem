/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BigNumber,
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

export declare namespace LibMemberRegistry {
  export type LeafStruct = {
    username: PromiseOrValue<string>;
    userAddress: PromiseOrValue<string>;
  };

  export type LeafStructOutput = [string, string] & {
    username: string;
    userAddress: string;
  };
}

export interface IMemberRegistryInterface extends utils.Interface {
  functions: {
    "cancelVerify(string)": FunctionFragment;
    "finalizeRecovery(string)": FunctionFragment;
    "setUsernameAddressPair(string)": FunctionFragment;
    "setUsernameOwner(string[],address[])": FunctionFragment;
    "setUsernamePair(string)": FunctionFragment;
    "usernameRecovery(string)": FunctionFragment;
    "verifyAndUsername((string,address),bytes32[])": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "cancelVerify"
      | "finalizeRecovery"
      | "setUsernameAddressPair"
      | "setUsernameOwner"
      | "setUsernamePair"
      | "usernameRecovery"
      | "verifyAndUsername"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "cancelVerify",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "finalizeRecovery",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "setUsernameAddressPair",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "setUsernameOwner",
    values: [PromiseOrValue<string>[], PromiseOrValue<string>[]]
  ): string;
  encodeFunctionData(
    functionFragment: "setUsernamePair",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "usernameRecovery",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "verifyAndUsername",
    values: [LibMemberRegistry.LeafStruct, PromiseOrValue<BytesLike>[]]
  ): string;

  decodeFunctionResult(
    functionFragment: "cancelVerify",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "finalizeRecovery",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "setUsernameAddressPair",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "setUsernameOwner",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "setUsernamePair",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "usernameRecovery",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "verifyAndUsername",
    data: BytesLike
  ): Result;

  events: {};
}

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
    cancelVerify(
      username: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    finalizeRecovery(
      username: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    setUsernameAddressPair(
      username: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    setUsernameOwner(
      username: PromiseOrValue<string>[],
      userAddress: PromiseOrValue<string>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    setUsernamePair(
      username: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    usernameRecovery(
      username: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    verifyAndUsername(
      _leaf: LibMemberRegistry.LeafStruct,
      _merkleProof: PromiseOrValue<BytesLike>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;
  };

  cancelVerify(
    username: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  finalizeRecovery(
    username: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  setUsernameAddressPair(
    username: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  setUsernameOwner(
    username: PromiseOrValue<string>[],
    userAddress: PromiseOrValue<string>[],
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  setUsernamePair(
    username: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  usernameRecovery(
    username: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  verifyAndUsername(
    _leaf: LibMemberRegistry.LeafStruct,
    _merkleProof: PromiseOrValue<BytesLike>[],
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  callStatic: {
    cancelVerify(
      username: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<void>;

    finalizeRecovery(
      username: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<void>;

    setUsernameAddressPair(
      username: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<void>;

    setUsernameOwner(
      username: PromiseOrValue<string>[],
      userAddress: PromiseOrValue<string>[],
      overrides?: CallOverrides
    ): Promise<void>;

    setUsernamePair(
      username: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<void>;

    usernameRecovery(
      username: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<void>;

    verifyAndUsername(
      _leaf: LibMemberRegistry.LeafStruct,
      _merkleProof: PromiseOrValue<BytesLike>[],
      overrides?: CallOverrides
    ): Promise<void>;
  };

  filters: {};

  estimateGas: {
    cancelVerify(
      username: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    finalizeRecovery(
      username: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    setUsernameAddressPair(
      username: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    setUsernameOwner(
      username: PromiseOrValue<string>[],
      userAddress: PromiseOrValue<string>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    setUsernamePair(
      username: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    usernameRecovery(
      username: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    verifyAndUsername(
      _leaf: LibMemberRegistry.LeafStruct,
      _merkleProof: PromiseOrValue<BytesLike>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    cancelVerify(
      username: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    finalizeRecovery(
      username: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    setUsernameAddressPair(
      username: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    setUsernameOwner(
      username: PromiseOrValue<string>[],
      userAddress: PromiseOrValue<string>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    setUsernamePair(
      username: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    usernameRecovery(
      username: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    verifyAndUsername(
      _leaf: LibMemberRegistry.LeafStruct,
      _merkleProof: PromiseOrValue<BytesLike>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;
  };
}
