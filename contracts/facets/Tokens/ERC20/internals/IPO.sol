pragma solidity ^0.8.9;

import {MerkleProof} from  "../../../../libraries/utils/MerkleProof.sol";
/**
    A contract that enables users to purchase the owner's token directly via some set ratio between
    owner token and a stable token of sorts. 
    
    Another feature is allowing users to pay the owner off-chain, the owner then collects these payments
    and creates a merkle root with leaves containing information on user payment and address. User then 
    uses the getFunds method which extracts all funds for their given payment and transfers the owner token
    to their 
 */
 
contract IPO {

    mapping(uint256 => IPO) ipo;

    struct IPO{
        uint256 id;
        bytes32 root;
        uint16 ratio;
        uint32 deadline;
        mapping(address => UserReward ) userReward;
    }

    struct UserReward{
        mapping( uint256 => Purchase) purchase;
        uint256 totalAmount;
    }

    struct Purchase{
        uint256 amount;
        bool isCollected;
    }
    
    event IPOCreated(uint256 totalAmount, uint256 maxAmountPerUser, uint256 ratio);
    function setIPO(uint256 totalAmount, uint256 maxAmountPerUser, uint256 ratio ) external {
        
        emit IPOCreated(totalAmount, maxAmountPerUser, ratio); 
    }
    function getFunds(MerkleProof[] memory proof, Purchase memory leaf ) external {
        bytes32 encodedLeaf = keccak256(abi.encode(leaf));
        require( MerkleProof.verify(proof, root, encodedLeaf) , "Invalid Proof");


    }
    function uploadIPOMerkleRoot( bytes32 _merkleRoot) external{
        ipo
    }
}