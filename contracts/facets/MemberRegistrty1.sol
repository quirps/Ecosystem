pragma solidity ^0.8.0;

import "../libraries/utils/Context.sol";
import "../internals/iMemberRegistry.sol";
import "../libraries/verification/MemberRegistryVerification.sol";

contract MemberRegistry is Context, iMemberRegistry {
    constructor (uint32 _recoveryTime) iMemberRegistry(_recoveryTime) {    }
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
