// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract DelegateVoter is EIP712 {
  constructor() EIP712("DelegateVoter", "0.0.1") {}

  struct QuorumConfig {
    uint256 minQuorum;
    uint256 minAcceptanceQuorum;
  }

  struct ProposalConfig {
    string name;
    QuorumConfig quorumConfig;
  }

  bytes32 public constant QUORUM_TYPE_HASH = keccak256("QuorumConfig(uint256 minQuorum,uint256 minAcceptanceQuorum)");

  // typehash for proposal must also include the quorum typehash
  bytes32 public constant PROPOSAL_TYPE_HASH =
    keccak256("ProposalConfig(string name,QuorumConfig quorumConfig)QuorumConfig(uint256 minQuorum,uint256 minAcceptanceQuorum)");

  function hashString(string calldata source) private pure returns (bytes32) {
    return keccak256(bytes(source));
  }

  function hashQuorumConfig(QuorumConfig calldata quorumConfig) private pure returns (bytes32) {
    return keccak256(abi.encode(QUORUM_TYPE_HASH, quorumConfig.minQuorum, quorumConfig.minAcceptanceQuorum));
  }

  function hashProposal(ProposalConfig calldata proposalConfig) private pure returns (bytes32) {
    return keccak256(abi.encode(PROPOSAL_TYPE_HASH, hashString(proposalConfig.name), hashQuorumConfig(proposalConfig.quorumConfig)));
  }

  function delegateProposeHashData(ProposalConfig calldata proposalConfig) public view returns (bytes32) {
    bytes32 encoded = hashProposal(proposalConfig);

    // build the struct hash to be signed using eip712 library
    return _hashTypedDataV4(encoded);
  }

  function recoverAddress(ProposalConfig calldata proposalConfig, bytes calldata signature) public view returns (address) {
    // encode the data and recover the signature
    bytes32 encoded = delegateProposeHashData(proposalConfig);

    return ECDSA.recover(encoded, signature);
  }
}