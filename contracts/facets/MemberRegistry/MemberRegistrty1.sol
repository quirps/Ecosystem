pragma solidity ^0.8.0;


import "./_MemberRegistry.sol";  
import "./verification/MemberRegistryVerification.sol";

contract MemberRegistry is  iMemberRegistry { 
    
    //delete userAddress parameter and replace with msgSender() function
    function verifyUsername(
        string memory username,
        uint8 v,
        bytes32 r,
        bytes32 s,
        address owner,
        bytes32 merkleRoot,
        uint256 nonce,
        uint256 deadline
    ) external {
        _verifyUsername(username, v, r, s, owner, merkleRoot, nonce, deadline);
    }

    function setUsernamePair(string memory username) internal {
        _setUsernamePair(username);
    }

    function setUsernameOwner(string memory username) external {
        
    }
    function usernameRecovery(string memory username) internal {
        _usernameRecovery(username);
    }

    function finalizeRecovery(string memory username) external {
        _finalizeRecovery(username);
    }

    function cancelVerify(string memory username) external {
        _cancelVerify(username);
    }

    // need a case in which account is in recovery but current user wants to cancel
}
