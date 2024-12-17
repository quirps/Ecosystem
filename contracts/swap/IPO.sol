pragma solidity ^0.8.9;

import { MerkleProof } from  "../libraries/utils/MerkleProof.sol";
import { iOwnership } from "../facets/Ownership/_Ownership.sol";
import {IOwnership} from "../facets/Ownership/IOwnership.sol";
import {IERC20} from "../facets/Tokens/ERC20/interfaces/IERC20.sol";
import {ERC1155Receiver} from "../facets/Tokens/ERC1155/ERC1155Receiver.sol"; 
/**
    A contract that enables users to purchase the owner's token directly via some set ratio between
    owner token and a stable token of sorts. 
    
    Another feature is allowing users to pay the owner off-chain, the owner then collects these payments
    and creates a merkle root with leaves containing information on user payment and address. User then 
    uses the getFunds method which extracts all funds for their given payment and transfers the owner token
    to their 
 */
 
 /**
 This must be in an external contract from the ecosystem, so we'll host on the exchange.
 Also need to seperate out what needs to be linked together on the exchange.
  */ 
contract IPOCreate is iOwnership, ERC1155Receiver {
 
    struct IPO{
        Ecosystem ecosystem;
        bytes32 merkleRoot;
        uint256 ratio;
        OutputCurrency outputCurrency;
        uint32 deadline;
        uint256 maxAmountPerUser; // on-chain purchases
        uint256 totalAmount; //total amount for purchase on chain
        mapping(address => UserReward ) userReward;
    }

    struct OutputCurrency{
        bool isBaseCurrency;
        address tokenAddress;
    }
    struct Ecosystem{
        address payable ownerAddress;
        address ecosystemAddress;
        address IPOFundAddress;
    }
    struct UserReward{  
        mapping( uint256 => OffChainPurchase) offChainPurchase;
        uint256 userTotalAmount; //this is only deducted from on-chain swaps
    }

    struct OffChainPurchase{ 
        address user;
        uint256 purchaseId;
        uint256 amount;
        bool isCollected;
    }
    
    mapping( uint256 => IPO) ipo;

    event IPOCreated(uint256 totalAmount, uint256 maxAmountPerUser, uint256 ratio);
    event IPOPurchaseConsumed( address tokenReceiver, uint256 amount, bool isOnChainPurchase);

    function setIPO(uint256 IPOid, bytes32 _merkleRoot, uint256 _totalAmount, uint256 _maxAmountPerUser, uint256 _ratio, uint32 _deadline, Ecosystem memory _ecosystem, OutputCurrency memory _outputCurrency) external {
        IPO storage _ipo = ipo[ IPOid ];

        require( _ipo.deadline != uint32(0), "An IPO already exists for this id.");
        require( _deadline > uint32(block.timestamp),"Deadline must be set in the future");

        _ipo.ecosystem = _ecosystem;
        _ipo.merkleRoot = _merkleRoot;
        _ipo.ratio = _ratio;
        _ipo.outputCurrency = _outputCurrency;
        _ipo.deadline = _deadline;
        _ipo.maxAmountPerUser = _maxAmountPerUser;
        _ipo.totalAmount = _totalAmount;

        emit IPOCreated(_totalAmount, _maxAmountPerUser, _ratio); 
    }

    function getOffchainPurchaseOwner(uint256 IPOid, address[] memory fundedUsers, uint256[] memory offChainPurchaseId) external {
        IPO storage _ipo = ipo[ IPOid ];
        address _ipoFundAddress = _ipo.ecosystem.IPOFundAddress;
        address _ecosystemAddress = _ipo.ecosystem.ecosystemAddress;
        //assert 
        IOwnership( _ecosystemAddress ).isEcosystemOwnerVerify( msgSender() );

        for( uint256 fundUserIndex; fundUserIndex < fundedUsers.length - 1; fundUserIndex ++ ){
            address _currentUser = fundedUsers[ fundUserIndex ];
            uint256 _offChainPurchaseId = offChainPurchaseId[ fundUserIndex ];
            OffChainPurchase storage _offChainPurchase = _ipo.userReward[ _currentUser ].offChainPurchase[ _offChainPurchaseId ];
            uint256 _amount =  _offChainPurchase.amount;
            _offChainPurchase.isCollected = true;
            //assert user is registered?
            IERC20( _ecosystemAddress ).transferFrom(_ipoFundAddress, _currentUser, _amount);
            emit IPOPurchaseConsumed(_currentUser , _amount, false);
        }
    }

    function getOffchainPurchase(uint256  IPOid, bytes32[] memory proof, OffChainPurchase memory leaf ) external {
        IPO storage _ipo = ipo[ IPOid ];
        bytes32 _merkleRoot = _ipo.merkleRoot;
        bytes32 encodedLeaf = keccak256(abi.encode(leaf));

        require(leaf.user == msgSender(), "Leaf user address doesn't match the sender address");
        require( MerkleProof.verify(proof, _merkleRoot, encodedLeaf) , "Invalid Proof");

        //transfer to user
        address _ecosystemAddress = _ipo.ecosystem.ecosystemAddress; 
        address _IPOFundAddress = _ipo.ecosystem.IPOFundAddress;
        IERC20(_ecosystemAddress).transferFrom(_IPOFundAddress, msgSender(), leaf.amount);
        
        //clear user reward for that 
        _ipo.userReward[ msgSender() ].offChainPurchase[ leaf.purchaseId ].isCollected = true;
        emit IPOPurchaseConsumed(msgSender(), leaf.amount, false);
    }

    ///@param amount amount of target currency desired. 
    function getOnChainPurchase(uint256 amount, uint256 IPOid) external {
        IPO storage _ipo = ipo[ IPOid ];
        
        //convert to IPO's currency of choice
        uint256 totalSpend = amount * _ipo.ratio;
        //transfer totalSpend to ecosystem owner
        address payable _ownerAddress = _ipo.ecosystem.ownerAddress; 
        if(_ipo.outputCurrency.isBaseCurrency){
            _ownerAddress.transfer(totalSpend); 
        }
        else {
            IERC20(_ipo.outputCurrency.tokenAddress).transferFrom(msgSender(), _ownerAddress, totalSpend);
        }

        uint256 currentUserTotal = _ipo.userReward[ msgSender() ].userTotalAmount;
        require( _ipo.maxAmountPerUser >= currentUserTotal + amount,"Cannot exceed the max amount of tokens permitted per user.");
        
        address _ecosystemAddress = _ipo.ecosystem.ecosystemAddress; 
        address _IPOFundAddress = _ipo.ecosystem.IPOFundAddress;

        //transfer tokens to user and update
        IERC20(_ecosystemAddress).transferFrom(_IPOFundAddress, msgSender(), amount);
        _ipo.userReward[ msgSender() ].userTotalAmount += amount; 

        emit IPOPurchaseConsumed(msgSender(), amount, false);
    }
    function uploadIPOMerkleRoot( uint256 IPOid, bytes32 _merkleRoot) external{
        //isEcosystemOwner
        IPO storage _ipo = ipo[ IPOid ];
        _ipo.merkleRoot = _merkleRoot;
    }

    
}