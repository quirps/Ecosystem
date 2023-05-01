pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SignatureVerifier {
    using ECDSA for bytes32;

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    struct Message  {
    address from;
    address to;
    uint256 value;
    uint256 nonce;
}
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(bytes("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"));
    bytes32 private constant MESSAGE_TYPEHASH = keccak256(bytes("Your custom message type hash goes here"));

    EIP712Domain private _domain;

    constructor(
        string memory name,
        string memory version,
        uint256 chainId,
        address verifyingContract
    ) {
        _domain = EIP712Domain(name, version, chainId, verifyingContract);
    }

    function verify(
        bytes memory signature,
        address signer,
        bytes32 hash,
        bytes memory data
    ) public view returns (bool) {
        bytes32 digest = _hashTypedDataV4(hash, data);
        address recoveredSigner = digest.recover(signature);
        return recoveredSigner == signer;
    }

 function _hashTypedDataV4(bytes32 hash, bytes memory data) private view returns (bytes32) {
    bytes32 domainSeparator = _hashDomain();
    return keccak256(
        abi.encodePacked(
            bytes1(0x19), bytes1(0x01),
            domainSeparator,
            hash,
            keccak256(data)
        )
    );
}

    function _hashDomain() private view returns (bytes32) {
        return keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(_domain.name)),
                keccak256(bytes(_domain.version)),
                _domain.chainId,
                _domain.verifyingContract
            )
        );
    }
}
