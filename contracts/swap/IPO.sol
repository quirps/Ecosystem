pragma solidity ^0.8.9;

import { MerkleProof } from "../libraries/utils/MerkleProof.sol";
import { iOwnership } from "../facets/Ownership/_Ownership.sol";
import { IOwnership } from "../facets/Ownership/IOwnership.sol";
import { IERC20 } from "../facets/Tokens/ERC20/interfaces/IERC20.sol";
import { ERC1155ReceiverEcosystem } from "../facets/Tokens/ERC1155/ERC1155Receiver.sol";

/**
 * A contract that enables community members to acquire a creator's token directly
 * via a set ratio between the creator's token and a stable token.
 *
 * Another feature allows community members to pay the creator off-chain. The creator
 * then collects these payments and creates a Merkle root with leaves containing
 * information on user payments and addresses. Users can then use the `claimOffchainPurchase`
 * method to claim their allocated tokens, which are then transferred from the
 * community fund address to their address.
 */
// This contract will be hosted on the exchange and will be separate from the core ecosystem.
contract CommunityOffering is iOwnership, ERC1155ReceiverEcosystem {
    struct CommunityOfferings {
        Ecosystem ecosystem;
        bytes32 merkleRoot; // Merkle root for off-chain purchases, can be updated.
        uint256 ratio; // Ratio of input token to creator token (e.g., how much input token for 1 creator token)
        address inputTokenAddress; // Address of the token used for purchasing the creator's token
        uint32 deadline; // Timestamp when the offering ends
        uint256 maxAmountPerUser; // Maximum amount of creator tokens an individual user can purchase on-chain
        uint256 totalAvailableAmount; // Total amount of creator tokens available for purchase in this offering (on-chain and off-chain)
        mapping(address => UserAllocation) userAllocations;
    }

    struct Ecosystem {
        address payable creatorAddress; // Address of the community creator (receives input tokens from on-chain purchases)
        address ecosystemAddress; // Address of the core ecosystem contract (for ownership verification and creator token source)
        address CommunityFundAddress; // Address holding the creator tokens allocated for this offering
    }

    struct UserAllocation {
        mapping(uint256 => OffChainPurchase) offChainPurchases; // Records off-chain purchases by ID
        uint256 onChainPurchasedAmount; // Total amount of creator tokens purchased on-chain by this user
    }

    struct OffChainPurchase {
        address user;
        uint256 purchaseId;
        uint256 amount; // Amount of creator tokens allocated to the user for this off-chain purchase
        bool isClaimed; // True if the off-chain purchase has been claimed by the user
    }

    mapping(uint256 => CommunityOfferings) public communityOfferings;

    event CommunityOfferingCreated(uint256 indexed offeringId, uint256 totalAvailableAmount, uint256 maxAmountPerUser, uint256 ratio);
    event OfferingPurchaseCompleted(address indexed tokenReceiver, uint256 amount, bool isOnChainPurchase);
    event MerkleRootUpdated(uint256 indexed offeringId, bytes32 newMerkleRoot);

  
    function createCommunityOffering(
        uint256 offeringId,
        bytes32 _merkleRoot, // Can be zero bytes initially if no off-chain presales
        uint256 _totalAvailableAmount,
        uint256 _maxAmountPerUser,
        uint256 _ratio,
        uint32 _deadline,
        Ecosystem memory _ecosystem,
        address _inputTokenAddress
    ) external {
        CommunityOfferings storage offering = communityOfferings[offeringId];
        require(offering.deadline == uint32(0), "A community offering already exists for this ID.");
        require(_deadline > block.timestamp, "Deadline must be set in the future.");
        // Consider adding a check to ensure _ecosystem.creatorAddress is a valid address
        // Consider adding a check to ensure _ecosystem.CommunityFundAddress holds sufficient tokens for _totalAvailableAmount

        offering.ecosystem = _ecosystem;
        offering.merkleRoot = _merkleRoot;
        offering.ratio = _ratio;
        offering.inputTokenAddress = _inputTokenAddress;
        offering.deadline = _deadline;
        offering.maxAmountPerUser = _maxAmountPerUser;
        offering.totalAvailableAmount = _totalAvailableAmount;

        emit CommunityOfferingCreated(offeringId, _totalAvailableAmount, _maxAmountPerUser, _ratio);
    }

    // This function allows the creator to fulfill multiple off-chain purchases directly.
    // It is assumed that the creator has already received the off-chain payments.
    // The creator uses this function to distribute the creator's tokens from the CommunityFundAddress.
    function collectOffchainPurchaseCreator(
        uint256 offeringId,
        address[] memory fundedUsers,
        uint256[] memory offChainPurchaseIds,
        uint256[] memory amounts
    ) external {
        CommunityOfferings storage offering = communityOfferings[offeringId];
        address communityFundAddress = offering.ecosystem.CommunityFundAddress;
        address ecosystemAddress = offering.ecosystem.ecosystemAddress;

        // Verify that the caller is an ecosystem owner, ensuring only authorized entities can distribute.
        IOwnership(ecosystemAddress).isEcosystemOwnerVerify(msgSender());

        require(fundedUsers.length == offChainPurchaseIds.length && fundedUsers.length == amounts.length, "Array length mismatch");

        for (uint256 i = 0; i < fundedUsers.length; i++) {
            address currentUser = fundedUsers[i];
            uint256 offChainPurchaseId = offChainPurchaseIds[i];
            uint256 amount = amounts[i];

            OffChainPurchase storage offChainPurchase = offering.userAllocations[currentUser].offChainPurchases[offChainPurchaseId];

            // Prevent claiming already claimed purchases or claiming with incorrect amounts.
            require(!offChainPurchase.isClaimed, "Off-chain purchase already claimed.");
            // If you want to strictly enforce the amount previously recorded in a Merkle tree (if any),
            // you'd need to retrieve it and compare. For this direct distribution, we rely on the input `amounts`.
            // Keeping it for now as per original intent but flagging the potential for dual logic.

            offChainPurchase.user = currentUser; // Ensure the user is correctly set if not already
            offChainPurchase.purchaseId = offChainPurchaseId;
            offChainPurchase.amount = amount;
            offChainPurchase.isClaimed = true;

            // Transfer creator tokens from the CommunityFundAddress to the user.
            IERC20(ecosystemAddress).transferFrom(communityFundAddress, currentUser, amount);
            emit OfferingPurchaseCompleted(currentUser, amount, false); // false indicates off-chain
        }
    }

    // Allows a user to claim their off-chain purchase using a Merkle proof.
    function claimOffchainPurchase(uint256 offeringId, bytes32[] memory proof, OffChainPurchase memory leaf) external {
        CommunityOfferings storage offering = communityOfferings[offeringId];
        bytes32 merkleRoot = offering.merkleRoot;

        // Ensure the offering is still active (not past its deadline) if desired, or if off-chain claims can happen anytime.
        // require(block.timestamp <= offering.deadline, "Community offering has ended.");

        bytes32 encodedLeaf = keccak256(abi.encodePacked(leaf.user, leaf.purchaseId, leaf.amount));

        require(leaf.user == msg.sender, "Leaf user address doesn't match the sender address.");
        require(MerkleProof.verify(proof, merkleRoot, encodedLeaf), "Invalid Merkle proof.");

        // Check if this specific off-chain purchase has already been claimed.
        require(!offering.userAllocations[msg.sender].offChainPurchases[leaf.purchaseId].isClaimed, "Off-chain purchase already claimed.");

        address ecosystemAddress = offering.ecosystem.ecosystemAddress;
        address communityFundAddress = offering.ecosystem.CommunityFundAddress;

        // Transfer creator tokens from the CommunityFundAddress to the user.
        IERC20(ecosystemAddress).transferFrom(communityFundAddress, msg.sender, leaf.amount);

        // Mark the off-chain purchase as claimed.
        offering.userAllocations[msg.sender].offChainPurchases[leaf.purchaseId].isClaimed = true;
        emit OfferingPurchaseCompleted(msg.sender, leaf.amount, false);
    }

    // Allows a user to purchase creator tokens directly on-chain.
    ///@param amount The amount of creator tokens desired by the user.
    function purchaseOnChain(uint256 amount, uint256 offeringId) external {
        CommunityOfferings storage offering = communityOfferings[offeringId];

        require(block.timestamp <= offering.deadline, "Community offering has ended.");
        require(amount > 0, "Purchase amount must be greater than zero.");

        // Calculate the total amount of input tokens to be spent by the user.
        uint256 totalSpend = amount * offering.ratio;

        // Transfer the input tokens from the user to the creator's address.
        // This assumes the input token contract has been approved by msg.sender for this contract to spend.
        IERC20(offering.inputTokenAddress).transferFrom(msg.sender, offering.ecosystem.creatorAddress, totalSpend);

        uint256 currentUserTotal = offering.userAllocations[msg.sender].onChainPurchasedAmount;
        require(offering.maxAmountPerUser >= currentUserTotal + amount, "Cannot exceed the maximum amount of tokens permitted per user.");

        // Ensure there are enough creator tokens available in the fund.
        require(offering.totalAvailableAmount >= amount, "Not enough creator tokens available for this purchase.");
        
        address ecosystemAddress = offering.ecosystem.ecosystemAddress;
        address communityFundAddress = offering.ecosystem.CommunityFundAddress;

        // Transfer creator tokens from the CommunityFundAddress to the user.
        IERC20(ecosystemAddress).transferFrom(communityFundAddress, msg.sender, amount);
        
        // Update the user's total on-chain purchased amount and the total available amount for the offering.
        offering.userAllocations[msg.sender].onChainPurchasedAmount += amount;
        offering.totalAvailableAmount -= amount; // Deduct from the total available supply

        emit OfferingPurchaseCompleted(msg.sender, amount, true);
    }

    // Allows the ecosystem owner to update the Merkle root for off-chain purchases.
    // This is useful for distributing tokens for new sets of off-chain payments.
    function uploadCommunityMerkleRoot(uint256 offeringId, bytes32 _merkleRoot) external{
        CommunityOfferings storage offering = communityOfferings[offeringId];
        address ecosystemAddress = offering.ecosystem.ecosystemAddress;

        // Only an ecosystem owner should be able to update the Merkle root.
        IOwnership(ecosystemAddress).isEcosystemOwnerVerify( msgSender() );

        offering.merkleRoot = _merkleRoot;
        emit MerkleRootUpdated(offeringId, _merkleRoot);
    }

}