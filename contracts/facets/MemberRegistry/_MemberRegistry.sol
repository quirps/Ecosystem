pragma solidity ^0.8.0;

import {iOwnership} from "../Ownership/_Ownership.sol";
import "./LibMemberRegistry.sol"; 
import "./verification/MemberRegistryVerification.sol"; 
 

contract iMemberRegistry is iOwnership { 
    uint32 public constant verificationTime = 1209600; //2 weeks
   
    /// @dev Emitted when a recovery action is initiated or finalized
    /// @param username The username associated with the action
    /// @param userAddress The user's address
    /// @param recoveryStatus The status of the recovery action
    event RecoveryAction(string username, address userAddress, LibMemberRegistry.RecoveryStatus recoveryStatus);

    /// @dev Emitted when a user is successfully registered
    /// @param username The registered username
    /// @param userAddress The user's address
    event UserRegistered(string username, address userAddress);


    event UsersRegistered(string[] username, address[] userAddress);

    //delete userAddress parameter and replace with msgSender() function
    function _verifyUsername(
        string memory username,
        uint8 v,
        bytes32 r,
        bytes32 s,
        address owner,
        bytes32 merkleRoot,
        uint256 nonce,
        uint256 deadline
    ) internal {
        MemberRegistryVerification.executeMyFunctionFromSignature(v, r, s, owner, merkleRoot, nonce, deadline);
        LibMemberRegistry.MemberRegistry_Storage storage ls = LibMemberRegistry.MemberRegistryStorage();

        ls.usernameToAddress[username] == address(0) ? _setUsernamePair(username) : _usernameRecovery(username);
    }

    function _setUsernamePair(string memory username) internal {
        _setUsernameAddressPair(username);
    }

    function _usernameRecovery(string memory username) internal {
        LibMemberRegistry.MemberRegistry_Storage storage ls = LibMemberRegistry.MemberRegistryStorage();

        LibMemberRegistry.Recovery memory _userVerification = ls.usernameToRecoveryAddress[username];
        if (msgSender() != _userVerification.userNewAddress) {
            ls.usernameToRecoveryAddress[username] = LibMemberRegistry.Recovery(msgSender(), uint96(block.timestamp) + verificationTime);
            emit RecoveryAction(username, msgSender(), LibMemberRegistry.RecoveryStatus.Initiated);
        }
    }

    function _finalizeRecovery(string memory username) internal {
        LibMemberRegistry.MemberRegistry_Storage storage ls = LibMemberRegistry.MemberRegistryStorage();
        LibMemberRegistry.Recovery memory _userVerification = ls.usernameToRecoveryAddress[username];
        if (_userVerification.recoveryTimestamp < uint96(block.timestamp) && msgSender() == _userVerification.userNewAddress) {
            _setUsernameAddressPair(username);
            emit RecoveryAction(username, msgSender(), LibMemberRegistry.RecoveryStatus.Finalized);
        }
    }

    function _cancelVerify(string memory username) internal {
        LibMemberRegistry.MemberRegistry_Storage storage ls = LibMemberRegistry.MemberRegistryStorage();
        address registeredAddress = ls.usernameToAddress[username];
        if (msgSender() == registeredAddress) {
            ls.usernameToRecoveryAddress[username] = LibMemberRegistry.Recovery(address(0), 0);
            emit RecoveryAction(username, msgSender(), LibMemberRegistry.RecoveryStatus.Cancelled);
        }
    }

    function _setUsernameAddressPair(string memory username) internal {
        LibMemberRegistry.MemberRegistry_Storage storage ls = LibMemberRegistry.MemberRegistryStorage();

        ls.usernameToAddress[username] = msgSender();
        ls.addressToUsername[msgSender()] = username;
        emit UserRegistered(username, msgSender());
    }

    function _setUsernameOwner( string[] memory username, address[] memory userAddress ) internal {
        LibMemberRegistry.MemberRegistry_Storage storage ls = LibMemberRegistry.MemberRegistryStorage();
        uint256 length = username.length;
        require(length == userAddress.length,"Parameters must be of same length.");

        for( uint256 userIndex; userIndex < length; userIndex ++ ){
            string memory _username = username[ userIndex ];
            address _userAddress = userAddress[ userIndex ];

            ls.usernameToAddress[ _username ] = _userAddress; 
            ls.addressToUsername[ _userAddress ]= _username;  
        }
        
        emit UsersRegistered( username, userAddress);  
    }
    // need a case in which account is in recovery but current user wants to cancel
}
