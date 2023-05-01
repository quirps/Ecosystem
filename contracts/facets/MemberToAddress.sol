pragma solidity ^0.8.6;

import "@opengsn/contracts/src/ERC2771Recipient.sol";

/**
 * Role of this facet is to associate a username from a given value producing
 * platform to a public address
 * 
 * Methods must be in place for initally setting a username, changing a username,
 * and recovering a username. 
 */
contract UserVerifcation is ERC2771Recipient  {
    // would need to verify ecosystem owner or moderator signed this message
    // msgSender() will 
    mapping(string => address) usernameToAddress;
    mapping(string => AddressEdit) userEditAddress;
    mapping(string => UsernameFinalization) userRecoveryInitiation;



    uint96 recoverProcessFinalizationDuration = 3600 * 24 * 7;
     enum UsernameFinalizationStatus  {Null, Initialization, Recovery}

     struct UsernameFinalization{
          address newAddress;
          uint96  finalizationTimestamp;
          UsernameFinalizationStatus status;
     }

    struct AddressEdit{
        uint24 delay;
        uint32 editTimestamp;
        bool canEdit;
    }
    event EditRequest(address initiator, string username);
    event RecoveryInitiation(address userNewAddress, uint96 finalizationTimestamp);

   function getUserAddress(string calldata username) external view returns (address userAddress_){
        userAddress_ = usernameToAddress[ username ];
   } 

   function setUserAddress(string calldata username) external {
        //verify this message was signed via moderator of sufficient privelge
        _verifyUser(username);
        //check to see if there's a delay on change
        //   if delay, start countdown
        //   else store 
        AddressEdit memory addressEdit =  userEditAddress[ username ];
        if( !addressEdit.canEdit ){
            addressEdit.editTimestamp = uint32(block.timestamp) + addressEdit.delay;
            addressEdit.canEdit = true;
            userEditAddress [ username ] = addressEdit;
            emit EditRequest(_msgSender(), username);
            return;
        }
        else{
            
        }
   }
   // moderation signature verification check 
   function initialUsernameCreation(string calldata username) internal {
          // set UsernameFinalization object
          //UsernameFinalization storage
   }
   function setAddressEdit(AddressEdit memory _addressEdit) external {
        //
   }
   function _verifyUser(string calldata username) internal view {
        
   }




     //starts the process of changing the address with the respective username
     //moderators can begin this process to help a member recover their account
     //associated with this ecosystem


     // Need user to send signed message
     
     //need ECSDA recovery 
   function recoverUsernameInitiate(string calldata username, address userNewAddress) external {
          //moderator check
          //change recoevery object
          //
     //emit RecoveryProcessInitiation()
   }

   function recoverFinalize(string calldata username) external {
          //
   }

   //must be signed message from moderator
   function recoverUsernameCancel(string calldata username ) external {
     _verifyUser(username);
     //check signed message via moderator
   }
}