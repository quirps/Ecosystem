// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IRewardToken.sol"; 

/**
 * @title RewardToken Contract
 * @dev ERC1155 token handling both reward tokens (ID < threshold) and
 * enhancement NFTs (ID >= threshold). Minting/burning controlled
 * by the ExchangeRewards contract. Includes NFT locking mechanism.
 */
contract RewardToken is ERC1155, Ownable, IRewardToken {
    address public exchangeRewardsContract;
    uint160 internal constant NFT_ID_THRESHOLD = type(uint160).max;

    // Track total supply per ID for passive rewards calculation
    mapping(uint256 => uint256) private _totalSupply;

    // Track locked status for enhancement NFTs
    mapping(uint256 => bool) public enhancementNFTLocked;

    // --- Errors ---
    error NotExchangeRewardsContract();
    error CannotTransferLockedNFT();
    error IDNotInEnhancementRange();
    error IDIsInEnhancementRange();

    // --- Modifiers ---
    modifier onlyExchangeRewards() {
        if (msg.sender != exchangeRewardsContract) revert NotExchangeRewardsContract();
        _;
    }

    // --- Constructor ---
    constructor(
        string memory uri_,
        address initialOwner,
        address _exchangeRewardsContract
    ) ERC1155(uri_) Ownable() { 
        exchangeRewardsContract = _exchangeRewardsContract;
    }

    // --- Configuration ---
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function setExchangeRewardsContract(address _newAddress) public onlyOwner {
        // Ensure new address is valid? E.g., non-zero?
        require(_newAddress != address(0), "Zero address");
        exchangeRewardsContract = _newAddress;
    }

    // --- Core ERC1155 Overrides ---

    /**
     * @dev See {IERC1155-_update}.
     * Overridden to update total supply tracking.
     */
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._update(from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            if (from == address(0)) {
                // Mint
                _totalSupply[id] += amount;
            } else if (to == address(0)) {
                // Burn
                _totalSupply[id] -= amount;
            } else {
                // Transfer - No change in total supply
            }
        }
    }

     /**
     * @dev See {IERC1155-_beforeTokenTransfer}.
     * Overridden to prevent transfers of locked enhancement NFTs.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        // Only check for transfers, not minting/burning
        if (from != address(0) && to != address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                if (isEnhancementNFT(ids[i])) {
                    if (enhancementNFTLocked[ids[i]]) {
                        revert CannotTransferLockedNFT();
                    }
                }
            }
        }
    }

    // --- IRewardToken Implementation ---

    /** @inheritdoc IRewardToken*/
    function mint(address to, uint256 id, uint256 amount, bytes calldata data) public override onlyExchangeRewards {
        _mint(to, id, amount, data);
    }

    /** @inheritdoc IRewardToken*/
    function burnFrom(address from, uint256 id, uint256 amount) public override onlyExchangeRewards {
        // ExchangeRewards contract is responsible for ensuring the 'from' account
        // has sufficient balance and has authorized the burn (e.g., during discount claim).
        _burn(from, id, amount);
    }

    /** @inheritdoc IRewardToken*/
    function totalSupply(uint256 id) external view override returns (uint256) {
        return _totalSupply[id];
    }

    /** @inheritdoc IRewardToken*/
    function isEnhancementNFT(uint256 id) public pure override returns (bool) {
        return id >= NFT_ID_THRESHOLD;
    }

    /** @inheritdoc IRewardToken*/
    function setNFTLocked(uint256 nftId, bool locked) external override onlyExchangeRewards {
        if (!isEnhancementNFT(nftId)) revert IDNotInEnhancementRange();
        enhancementNFTLocked[nftId] = locked;
        emit NFTLockedStatusChanged(nftId, locked);
    }

    // --- Owner Functions ---
    /**
     * @notice Allows the owner to mint initial enhancement NFTs.
     */
    function ownerMintEnhancementNFT(address to, uint256 id, uint256 amount, bytes calldata data) public onlyOwner {
        if (!isEnhancementNFT(id)) revert IDNotInEnhancementRange();
        _mint(to, id, amount, data);
        emit OwnerMintedEnhancementNFT(to, id, amount);
    }

     /**
     * @notice Allows the owner to mint initial reward tokens (e.g., for promotions, testing).
     */
    function ownerMintRewardToken(address to, uint256 id, uint256 amount, bytes calldata data) public onlyOwner {
        if (isEnhancementNFT(id)) revert IDIsInEnhancementRange();
         _mint(to, id, amount, data);
    }

}