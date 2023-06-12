pragma solidity ^0.8.0;

import "../libraries/utils/Context.sol";
contract MemberRegistry{
    uint96 constant WEEK = 604800;
    mapping(address => string) addressToUsername;
    mapping(string => address) usernameToAddress;
    mapping(string => Recovery) usernameToVerification;

    struct Recovery{
        address userNewAddress;
        uint96 recoveryTimestamp; //times after this timestamp allow for the user to
                                //permenantely change. 
    }
    struct SignatureVerfication{
        uint256 domain;
        uint256 nonce;
    }
    //delete userAddress parameter and replace with msgSender() function
    function verifyUsername(string memory username, SignatureVerfication memory _signature ) external {
        // verifies signature of user

         usernameToAddress[ username ] == address(0) ? setUsernamePair(username)
                                                     : usernameRecovery(username);
    }
    function setUsernamePair(string memory username) internal {
        setUsernameAddressPair( username );
        usernameToVerification[ username ] = Recovery(msgSender(), 0);
    }
    function usernameRecovery(string memory username) internal{
        Recovery memory _userVerification = usernameToVerification[ username ];
        if( msgSender() != _userVerification.userNewAddress ){
            usernameToVerification[ username ] = Recovery(msgSender(), uint96(block.timestamp) + WEEK );
        }
        else if( _userVerification.recoveryTimestamp < uint96( block.timestamp ) ){
            setUsernameAddressPair( username );
        }
    }
    function setUsernameAddressPair(string memory username) internal{
        usernameToAddress[ username ] = msgSender();
        addressToUsername[ msgSender() ] = username;
    }
    // need a case in which account is in recovery but current user wants to cancel
}