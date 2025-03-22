pragma solidity ^0.8.0;

import {iOwnership} from "../Ownership/_Ownership.sol";
import "./LibMemberRegistry.sol"; 
 

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
        /**
     * @dev Verifies Merkle proof and sets user's level
     * @param _leaf Level to assign to the user
     * @param _merkleProof Array of hashed data to verify proof
     */  
    function verifyAndUsername(LibMemberRegistry.Leaf memory _leaf, bytes32[] calldata _merkleProof) external {
        // Create leaf from msg.sender and level
        LibMemberRegistry.MemberRegistryStorage storage mrs = LibMemberRegistry.memberRegistryStorage(); 

        bytes32 leaf = keccak256(abi.encodePacked( _leaf.username, _leaf.userAddress));
        
        require(_verifyMerkleProof(_merkleProof, mrs.registryMerkleRoot, leaf), "Invalid Merkle proof");
          
        //set username address relation 
        mrs.addressToUsername[ _leaf.userAddress ] = _leaf.username; 
        mrs.usernameToAddress[ _leaf.username ] = _leaf.userAddress;

        emit UserRegistered( _leaf.username, _leaf.userAddress);
    }

       /**
     * @dev Helper function to verify Merkle proofs
     */
    function _verifyMerkleProof(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;
        
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        
        // Check if the computed hash equals the root of the Merkle tree
        return computedHash == root;
    }
 

    function _setUsernamePair(string memory username) internal {
        _setUsernameAddressPair(username);
    }

    function _usernameRecovery(string memory username) internal {
        LibMemberRegistry.MemberRegistryStorage storage ls = LibMemberRegistry.memberRegistryStorage(); 

        LibMemberRegistry.Recovery memory _userVerification = ls.usernameToRecoveryAddress[username];
        if (msgSender() != _userVerification.userNewAddress) {
            ls.usernameToRecoveryAddress[username] = LibMemberRegistry.Recovery(msgSender(), uint96(block.timestamp) + verificationTime);
            emit RecoveryAction(username, msgSender(), LibMemberRegistry.RecoveryStatus.Initiated);
        }
    }

    function _finalizeRecovery(string memory username) internal {
        LibMemberRegistry.MemberRegistryStorage storage ls = LibMemberRegistry.memberRegistryStorage();
        LibMemberRegistry.Recovery memory _userVerification = ls.usernameToRecoveryAddress[username];
        if (_userVerification.recoveryTimestamp < uint96(block.timestamp) && msgSender() == _userVerification.userNewAddress) {
            _setUsernameAddressPair(username);
            emit RecoveryAction(username, msgSender(), LibMemberRegistry.RecoveryStatus.Finalized);
        }
    }

    function _cancelVerify(string memory username) internal {
        LibMemberRegistry.MemberRegistryStorage storage ls = LibMemberRegistry.memberRegistryStorage();
        address registeredAddress = ls.usernameToAddress[username];
        if (msgSender() == registeredAddress) {
            ls.usernameToRecoveryAddress[username] = LibMemberRegistry.Recovery(address(0), 0);
            emit RecoveryAction(username, msgSender(), LibMemberRegistry.RecoveryStatus.Cancelled);
        }
    } 

    function _setUsernameAddressPair(string memory username) internal {
        LibMemberRegistry.MemberRegistryStorage storage ls = LibMemberRegistry.memberRegistryStorage();

        ls.usernameToAddress[username] = msgSender();
        ls.addressToUsername[msgSender()] = username; 
        emit UserRegistered(username, msgSender());
    }

    function _setUsernameOwner( string[] memory username, address[] memory userAddress ) internal {
        LibMemberRegistry.MemberRegistryStorage storage ls = LibMemberRegistry.memberRegistryStorage();
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
