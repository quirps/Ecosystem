pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

import "../Tokens/ERC1155/ERC1155Transfer.sol";
import "./_Members.sol";   
import "../../libraries/merkleVerify/MembersVerify.sol"; 
import "./IMembers.sol";
  
contract Members is IMembers, iMembers { 

    /**
     * @dev Verifies Merkle proof and sets user's level
     * @param _leaf Level to assign to the user
     * @param _merkleProof Array of hashed data to verify proof
     */
    function verifyAndSetLevel(LibMemberLevel.Leaf memory _leaf, bytes32[] calldata _merkleProof) external {
        _verifyAndSetLevel(_leaf, _merkleProof);
    }

    /**
     * @dev Batch set levels for multiple addresses (permissioned function)
     * @param _leaves user resource denoting their membership status
     */
    function batchSetLevels(LibMemberLevel.Leaf[] calldata _leaves) external {
        _batchSetLevels(_leaves);
    }


     /**
     * @dev Batch set levels for multiple addresses (permissioned function)
     * @param user  user address 
     * @param level user's new level
     */
    function setMemberLevel( address user, uint32 level) external { 
        _setMemberLevel(user, level);  
    }


    /**
     * @dev Returns the level info for a given address
     * @param _user Address to query
     * @return level and timestamp of the user
     */
    function getMemberLevelStruct(address _user) external view returns (uint32 level, uint32 timestamp) {
        return _getMemberLevelStruct(_user);
    }

  

    /**
     * @dev Returns the level info for a given address
     * @param _user Address to query
     */
    function getMemberLevel(address _user) external view returns (uint32 memberLevel_) {
        return _getMemberLevel(_user);
    }



    /**
     * @dev Bans a user by setting their level to 0
     * @param _user Address of the user to ban
     */
    function banMember(address _user) external onlyOwner {
        _banMember(_user);
    }


 


}

