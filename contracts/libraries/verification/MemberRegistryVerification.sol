pragma solidity ^0.8.0;

import "../LibMemberRegistry.sol";

library MemberRegistryVerification {
    

    

    function executeMyFunctionFromSignature(
        uint8 v,
        bytes32 r,
        bytes32 s,
        address owner,
        bytes32 merkleRoot,
        uint256 nonce,
        uint256 deadline
    ) external {
        LibMemberRegistry.MemberRegistry_Storage storage ls = LibMemberRegistry.MemberRegistryStorage();
        require(nonce > ls.nonces[owner],"Nonce is less than or equal to current nonce value associated with this address." );
        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("Ether Mail"),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );

        bytes32 hashStruct = keccak256(
            abi.encode(
                keccak256("Member(address owner,bytes32 merkleRoot,uint256 nonce,uint256 deadline)"),
                owner,
                merkleRoot,
                nonce,
                deadline
            )
        );
        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct));
        address signer = ecrecover(hash, v, r, s);
        require(signer == owner, "MyFunction: invalid signature");
        require(signer != address(0), "ECDSA: invalid signature");
        require(block.timestamp < deadline, "MyFunction: signed transaction expired");
        ls.nonces[owner]++;
    }
}
