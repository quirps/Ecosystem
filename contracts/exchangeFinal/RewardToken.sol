// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IRewardToken.sol";
/**
 * @title RewardToken Contract v2.1 (OZ v5 Compatible)
 * @dev ERC1155 token handling reward tokens and enhancement NFTs.
 * Uses _update hook (OZ v5+) for supply tracking and NFT lock enforcement.
 * Implements IRewardToken interface.
 */
contract RewardToken is ERC1155, Ownable, IRewardToken {
    // --- State Variables ---
    // (Unchanged: exchangeRewardsContract, NFT_ID_THRESHOLD, _totalSupply, enhancementNFTLocked)
    address public exchangeRewardsContract;
    uint160 internal constant NFT_ID_THRESHOLD = type(uint160).max;
    mapping(uint256 => uint256) private _totalSupply;
    mapping(uint256 => bool) public enhancementNFTLocked;
    // --- Errors ---
    // (Unchanged)
    error NotExchangeRewardsContract();
    error CannotTransferLockedNFT();
    error IDNotInEnhancementRange();
    error IDIsInEnhancementRange();
    error ZeroAddress();
    // --- Modifiers ---
    // (Unchanged)
    modifier onlyExchangeRewards() {
        if (msg.sender != exchangeRewardsContract) revert NotExchangeRewardsContract();
        _;
    }
    // --- Constructor ---
    // (Unchanged)
    constructor(
        string memory uri_,
        address _owner
    ) ERC1155(uri_) Ownable(_owner) {
    }
    // --- Configuration Functions (Owner Controlled) ---
    // (Unchanged: setURI, setExchangeRewardsContract)
    function setURI(string memory newuri) public  onlyOwner {
        _setURI(newuri);
    }
    function setExchangeRewardsContract(address _newAddress) public onlyOwner {
        if (_newAddress == address(0)) revert ZeroAddress();
        exchangeRewardsContract = _newAddress;
    }
    // --- Core ERC1155 Overrides ---
    /**
     * @dev See {ERC1155-_update}.
     * Overridden for OpenZeppelin v5+ to:
     * 1. Enforce lock on enhancement NFTs during transfers (before main logic).
     * 2. Update total supply tracking (after main logic).
     */
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override {
        // --- NFT Lock Check (Perform *before* calling super._update) ---
        // Check lock status only for actual transfers (not minting or burning)
        if (from != address(0) && to != address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                // Check if it's an NFT ID and if it's locked
                if (id >= NFT_ID_THRESHOLD && enhancementNFTLocked[id]) {
                    revert CannotTransferLockedNFT();
                }
            }
        }
        // --- End NFT Lock Check ---
        // Call the original Oz implementation AFTER our check
        // This handles balance updates and event emissions.
        super._update(from, to, ids, amounts);
        // --- Total Supply Update (Perform *after* calling super._update) ---
        // This logic remains the same as before.
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            if (from == address(0)) {
                // Mint
                _totalSupply[id] += amount;
            } else if (to == address(0)) {
                // Burn
                _totalSupply[id] -= amount;
            }
            // If it's a regular transfer, total supply doesn't change.
        }
        // --- End Total Supply Update ---
    }
    // Remove the old _beforeTokenTransfer override completely:
    // function _beforeTokenTransfer(...) internal virtual override { ... } // DELETE THIS FUNCTION
    // --- IRewardToken Implementation ---
    // (Unchanged: mint, burnFrom, totalSupply, isEnhancementNFT, setNFTLocked)
     /** @inheritdoc IRewardToken*/
    function mint(address to, uint256 id, uint256 amount, bytes calldata data) public virtual override onlyExchangeRewards {
        _mint(to, id, amount, data);
    }
    /** @inheritdoc IRewardToken*/
    function burnFrom(address from, uint256 id, uint256 amount) public virtual override onlyExchangeRewards {
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
    function setNFTLocked(uint256 nftId, bool locked) external virtual override onlyExchangeRewards {
        if (!isEnhancementNFT(nftId)) revert IDNotInEnhancementRange();
        enhancementNFTLocked[nftId] = locked;
        emit NFTLockedStatusChanged(nftId, locked);
    }
    // --- Owner Functions for Initial Minting ---
    // (Unchanged: ownerMintEnhancementNFT, ownerMintRewardToken)
    function ownerMintEnhancementNFT(address to, uint256 id, uint256 amount, bytes calldata data) public onlyOwner {
        if (!isEnhancementNFT(id)) revert IDNotInEnhancementRange();
        _mint(to, id, amount, data);
        emit EnhancementNftMinted(msg.sender, to, id, amount, data);
    }
    function ownerMintRewardToken(address to, uint256 id, uint256 amount, bytes calldata data) public onlyOwner {
        if (isEnhancementNFT(id)) revert IDIsInEnhancementRange();
        _mint(to, id, amount, data);
    }
    // --- Supports Interface ---
    // (Unchanged)
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, IERC165) returns (bool) {
        return interfaceId == type(IRewardToken).interfaceId
            || interfaceId == type(IERC1155).interfaceId
            || super.supportsInterface(interfaceId);
    }
} 