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

/**
 * Register username with address. 
 * How to do this properly? An issue is first time fault.
 * If someone gains access to the account and registers with a bad
 * address, how would user get their account back? 
 * Assume Twitch Access is main source of truth.
 * 
 * Create zksnark, can be settled after some time?
 * Something needs total control, otherwise these failsafes are useless
 * in the wrong scenario. 
 * 
 * User external account
 * 
 * Owner should be authority username-address. Twitch should be authority of username.
 * 
 * Another issue is when one account gets hacked on twitch, and bad actor
 * initiates verification across a large number of ecosystems. How is this handled?
 * 
 * Is this where a global user registry could come in handy? User could simply 
 * lock their profile and start reinitiating their address as the true user. Only 
 * other option would be for batch call to all effected eco systems. Seems better
 * to have a user registry which others reference too. 
 * 
 * What would the flow be? Ecosystems would need to reference this user registry.
 * 1. Ecosystem stores on decentralized server the usernames, rank, and purported
 *    address. 
 * 2. User can then initiate a verification on-chain
 *   2a. each
 *   ** Pause **
 *   So if we do merkle root for user history, for all users, then we'd need to
 *  upload merkle root anytime we wanted a user to update. Could also have signature
 *  service, or both? (Signature service being on demand signing of current membership
 *   status). Is there a way to make these both consistent with each other? Do we need
 *  them too? One issue is service method could be reverted by an old root. 
 *   Doesn't seem there's a trivial way to converge these too methods. What about signing
 * the root? 
 * So here's the protocol:
 * 1. Everytime membership rankings change, or something in the leafs change, then
 *   owner signs the merkle root with a timestamp. 
 * 2. Then at ANY point a user can upload this signature to the ecosystem, and will
 * set the new root so long as signature matches and timestamp is greater than 
 * the previous. 
 * 3. User can then perform a batch update as well, so as to include bounties. 
 * 
 * 
 * 
 * So now we have a much better member updating protocol, we can resume the issue
 * over member validation and member-address pair recovery. 
 * 
 * DApp would have a function that takes in all .... issue with mass transaction
 * by a user is triggering malicious ecosystems. 
 * 
 * There's no way to automate the security of ecosystems, user's must trust the 
 * ecosystem owners to not act maliciously. 
 * 
 * If EVERYTHING goes through registry, can we detect if something strays from the
 * versioning protocol. If this is true, can assuredly mark ecosystems as deviating 
 * from the ecosystem versioning.  
 * 
 * How do we implement receovery across large amount of accounts? 
 * Right now no user transacting with ecosystem?
 * What is user simply submits different address? Then if already initialized
 * a 7 day process would initiate, and if not changed, would create a new 
 * username-address pair on-chain. 
 */