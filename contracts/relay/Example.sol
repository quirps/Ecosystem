pragma solidity ^0.8.9;

 contract ExampleVerify{
    mapping(address => uint256) userNonce;

       struct Message {
        address signer;
        address target;
        bytes paymasterData;
        bytes targetData;
        uint256 gasLimit;
        uint256 nonce;
        uint32 deadline;
    }
function executeSetIfSignatureMatch(
    Message calldata message,  
    uint8 v,
    bytes32 r,
    bytes32 s 
  ) external returns (bool){
    require(block.timestamp < message.deadline, "Signed transaction expired");
 
    uint256 chainId = block.chainid;

    bytes32 eip712DomainHash = keccak256(
        abi.encode(
            keccak256(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
            ),
            keccak256(bytes("MassDX")),
            keccak256(bytes("1.0.0")),
            chainId,
            address(this)
        )
    );  

    bytes32 hashStruct = keccak256(
      abi.encode(
          keccak256("Message(address signer,address target,bytes paymasterData,bytes targetData,uint256 gasLimit,uint256 nonce,uint32 deadline)"),
          message.signer,
          message.target,
          keccak256(message.paymasterData),
          keccak256(message.targetData),
          message.gasLimit,
          message.nonce,
          message.deadline
        )
    );

    bytes32 hash = keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct));
    address signer = ecrecover(hash, v, r, s);
    require(signer == message.signer, "MyFunction: invalid signature");
    require(signer != address(0), "ECDSA: invalid signature");
    require(message.nonce > userNonce[ signer ],"Message must have a nonce greater than the current nonce.");

    return true;
    }
 }