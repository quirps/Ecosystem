pragma solidity ^0.8.28;

import { iMemberRegistry } from "./_MemberRegistry.sol";
import { LibMemberRegistry } from "./LibMemberRegistry.sol";  

contract MemberRegistry is iMemberRegistry{
    
    function verifyAndUsername(LibMemberRegistry.Leaf memory _leaf, bytes32[] calldata _merkleProof) external  {
        _verifyAndUsername(_leaf, _merkleProof);
    } 

    function setUsernamePair(string memory username) external  {
        _setUsernamePair(username);
    }

    function usernameRecovery(string memory username) external  {
        _usernameRecovery(username);
    }

    function finalizeRecovery(string memory username) external  {
        _finalizeRecovery(username);
    }

    function cancelVerify(string memory username) external {
        _cancelVerify(username);
    }

    function setUsernameAddressPair(string memory username) external  {
        _setUsernameAddressPair(username);
    }

    function setUsernameOwner(string[] memory username, address[] memory userAddress) external  {
        _setUsernameOwner(username, userAddress);
    }

}