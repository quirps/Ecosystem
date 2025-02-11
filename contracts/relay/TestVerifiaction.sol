pragma solidity ^0.8.9;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "./MessageHashUtils.sol"; 

import "hardhat/console.sol";

contract SigVerify{
    using ECDSA for bytes32;
    struct DomainSeperator{
        string name ;
        string version ;
        uint256 chainId;
        address verifyingContract;
    }

    struct Message {
        address signer;
        address target;
        bytes paymasterData;
        bytes targetData;
        uint256 gasLimit;
        uint256 nonce;
        uint32 deadline;
    }

    // function domain() public returns ( DomainSeperator memory domain_ ) {
    //     DomainSeperator("MassDX","1.0.0", block.chainid, address(this));
    // }



    function fullVerify(DomainSeperator memory _domain, Message memory message,
                    uint8 v,
                    bytes32 r,
                    bytes32 s) external returns (bytes32, address) {
        //domain hash
        bytes32 domainHash = keccak256( abi.encode( _domain ) );
        bytes32 messageHash = keccak256( abi.encode( message ) );
        bytes32 hash = MessageHashUtils.toTypedDataHash( domainHash, messageHash);
        return (hash, verify(hash, v, r, s));
    }
    function fullVerifyDomain(DomainSeperator memory _domain, 
                    uint8 v,
                    bytes32 r,
                    bytes32 s) external returns (bool) {
        //domain hash
        bytes32 domainHash = keccak256( abi.encode( _domain ) );
       
        return true;
    }
    
    function fullVerifyMessage(Message memory _message, 
                    uint8 v,
                    bytes32 r,
                    bytes32 s) external returns (bool) {
        //domain hash
        bytes32 _messageHash = keccak256( abi.encode( _message ) );
       
        return true;
    }
    function verify(bytes32 hash,
                    uint8 v,
                    bytes32 r,
                    bytes32 s ) public view returns (address isVerified_){

                    
            (address verifiedAddress, ECDSA.RecoverError recoverError) = ECDSA.tryRecover(hash, v, r, s);
            isVerified_ = verifiedAddress;
        }
}