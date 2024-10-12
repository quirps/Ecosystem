
import "../../MemberRankings/LibMembers.sol";


pragma solidity ^0.8.0;

library MemberRecover{
    
function executeMyFunctionFromSignature(
    uint8 v,
    bytes32 r,
    bytes32 s,
    address owner,
    uint256 nonce,
    LibMembers.Leaf memory data

) internal {
    bytes32 eip712DomainHash = keccak256(
        abi.encode(
            keccak256(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
            ),
            keccak256("Ether Mail"),
            keccak256("1"),
            block.chainid,
            address(this)
        )
    );

    bytes32 hashStruct = keccak256(
        abi.encode(
            keccak256("Member(address owner,uint256 nonce,bytes32 data)"),
            owner,
            nonce,
            keccak256( abi.encode( data ) )
        )
    );

    bytes32 hash = keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct));
    address signer = ecrecover(hash, v, r, s);
    require(signer == owner, "Member: invalid signature");
    require(signer != address(0), "ECDSA: invalid signature");

   //nonce handler
    LibMembers.MembersStorage storage ls = LibMembers.memberStorage();
    uint256 recoveryNonce = ls.recoveryNonce;
    require(nonce >= recoveryNonce,"EN : Nonce has expired");
    if ( nonce > recoveryNonce){
        ls.recoveryNonce = nonce;
    }
    //_myFunction(owner, myParam);
}
}