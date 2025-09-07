// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./LibStake.sol"; // Our staking logic library
import "../facets/StakeConfig/IStakeConfig.sol"; // Interface for ecosystem's StakeConfigFacet
import "./INonfungiblePositionManager.sol"; // Uniswap V3 position manager interface
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol"; // For safe transfers

/// @title StakingContract
/// @notice This contract allows users to single stake an ecosystem token or double stake
///         by providing liquidity to Uniswap V3. It has no owner and operates as a
///         multi-tenant staking hub, interacting with different ecosystem Diamonds
///         passed as parameters.
contract StakingContract is IERC721Receiver {
    using Address for address;

    // --- Fixed External Protocol Address ---
    // The Uniswap V3 NonfungiblePositionManager is a global, fixed address.
    // Replace with the actual deployed address on your target network.
    address private constant UNISWAP_V3_POSITION_MANAGER = 0x0616e5762c1E7Dc3723c50663dF10a162D690a86;

    // --- Contract-Specific State (Multi-Ecosystem Aware) ---
    // User's staking positions: userAddress => ecosystemAddress => tokenId => StakePosition
    // For single stake, we use LibStake._getSingleStakeIdentifier() as tokenId.
    mapping(address => mapping(address => mapping(uint256 => LibStake.StakePosition))) public userStakes;

    // Total staked amounts: ecosystemAddress => tokenId => totalAmountStaked (ecosystem tokens or liquidity units)
    mapping(address => mapping(uint256 => uint256)) public totalStaked;

    // --- Events ---
    event Staked(address indexed user, address indexed ecosystem, uint256 amount, address indexed identifier, LibStake.StakingType stakeType);
    event Unstaked(address indexed user, address indexed ecosystem, uint256 amount, address indexed identifier, LibStake.StakingType stakeType);
    event RewardsClaimed(address indexed user, address indexed ecosystem, uint256 amount);

    // No constructor as per requirements. All ecosystem-specific config comes via parameters.


    // --- IERC721Receiver Implementation ---
    /// @notice Handles the receipt of an ERC721 token (specifically Uniswap V3 position NFTs).
    /// @dev This function is called by the Uniswap V3 NonfungiblePositionManager when it mints an NFT
    ///      position to this contract.
    /// @param operator The address which called `safeTransferFrom` function.
    /// @param from The address which previously owned the token.
    /// @param tokenId The NFT identifier which is being transferred.
    /// @param data Additional data with no specified format.
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        require(msg.sender == UNISWAP_V3_POSITION_MANAGER, "StakingContract: Only Uniswap V3 PM can send NFTs");

        // We assume the NFT is transferred as part of the _stakeDouble flow.
        // The `stakeDouble` function is responsible for updating the `userStakes` mapping
        // after the NFT is minted and transferred here.
        // The ecosystemAddress and user context for this NFT are handled by stakeDouble.

        return this.onERC721Received.selector;
    }

    // --- Staking Functions ---

    /// @notice Allows a user to single stake the ecosystem token for a specific ecosystem.
    /// @param _ecosystemAddress The address of the ecosystem's Diamond (also its ERC-20 token address).
    /// @param _amount The amount of ecosystem tokens to stake.
    function stakeSingle(address _ecosystemAddress, uint256 _amount) external {
        require(_amount > 0, "StakingContract: Amount must be greater than 0");
        require(_ecosystemAddress != address(0), "StakingContract: Ecosystem address cannot be zero");

        IStakeConfig stakeConfig = IStakeConfig(_ecosystemAddress);
        require(stakeConfig.canStake(msg.sender), "StakingContract: User not eligible to stake in this ecosystem");

        uint256 singleStakeId = LibStake._getSingleStakeIdentifier();

        // Claim any pending rewards first for this position (ecosystem-specific)
        claimRewards(_ecosystemAddress, singleStakeId);

        // Transfer ecosystem tokens from user to this contract
        // The _ecosystemAddress IS the ERC-20 token address for this ecosystem.
        TransferHelper.safeTransferFrom(_ecosystemAddress, msg.sender, address(this), _amount);

        // Update user's stake position (ecosystem-specific)
        LibStake.StakePosition storage position = userStakes[msg.sender][_ecosystemAddress][singleStakeId];
        position.amount += _amount;
        LibStake._updatePositionTimestamp(position);
        position.stakeType = LibStake.StakingType.Single;
        position.tokenId = singleStakeId;

        // Update total staked amount (ecosystem-specific)
        totalStaked[_ecosystemAddress][singleStakeId] += _amount;

        emit Staked(msg.sender, _ecosystemAddress, _amount, _ecosystemAddress, LibStake.StakingType.Single);
    }

    /// @notice Allows a user to double stake by providing liquidity to Uniswap V3 for a specific ecosystem.
    ///         One of the tokens (_tokenA or _tokenB) must be the ecosystem's ERC-20 token.
    /// @param _ecosystemAddress The address of the ecosystem's Diamond (also its ERC-20 token address).
    /// @param _tokenA The first token in the pair.
    /// @param _tokenB The second token in the pair.
    /// @param _amountA The amount of tokenA to add to liquidity.
    /// @param _amountB The amount of tokenB to add to liquidity.
    /// @param _fee The fee tier for the Uniswap V3 pool (e.g., 3000 for 0.3%).
    /// @param _tickLower The lower tick of the desired price range.
    /// @param _tickUpper The upper tick of the desired price range.
    /// @param _deadline The timestamp by which the transaction must be included.
    /// @return tokenId The unique NFT ID representing the Uniswap V3 position.
    function stakeDouble(
        address _ecosystemAddress,
        address _tokenA,
        address _tokenB,
        uint256 _amountA,
        uint256 _amountB,
        uint24 _fee,
        int24 _tickLower,
        int24 _tickUpper,
        uint256 _deadline
    ) external returns (uint256 tokenId) {
        require(_ecosystemAddress != address(0), "StakingContract: Ecosystem address cannot be zero");
        require(_tokenA != address(0) && _tokenB != address(0), "StakingContract: Tokens cannot be zero address");
        require(_tokenA != _tokenB, "StakingContract: Tokens must be different");
        require(_tokenA == _ecosystemAddress || _tokenB == _ecosystemAddress, "StakingContract: One token must be the ecosystem token");
        require(_deadline >= block.timestamp, "StakingContract: Deadline has passed");

        IStakeConfig stakeConfig = IStakeConfig(_ecosystemAddress);
        require(stakeConfig.canStake(msg.sender), "StakingContract: User not eligible to stake in this ecosystem");

        // Sort tokens for consistency and for Uniswap V3's requirements
        address token0 = _tokenA < _tokenB ? _tokenA : _tokenB;
        address token1 = _tokenA < _tokenB ? _tokenB : _tokenA;
        uint256 amount0Desired = _tokenA < _tokenB ? _amountA : _amountB;
        uint256 amount1Desired = _tokenA < _tokenB ? _amountB : _amountA;

        // Determine the paired token address (the one not equal to _ecosystemAddress)
        address pairedTokenAddress = (token0 == _ecosystemAddress) ? token1 : token0;

        // Transfer tokens from user to this contract
        TransferHelper.safeTransferFrom(_tokenA, msg.sender, address(this), _amountA);
        TransferHelper.safeTransferFrom(_tokenB, msg.sender, address(this), _amountB);

        // Approve the NonfungiblePositionManager to pull tokens from this contract
        TransferHelper.safeApprove(token0, UNISWAP_V3_POSITION_MANAGER, amount0Desired);
        TransferHelper.safeApprove(token1, UNISWAP_V3_POSITION_MANAGER, amount1Desired);

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: _fee,
            tickLower: _tickLower,
            tickUpper: _tickUpper,
            amount0Desired: amount0Desired,
            amount1Desired: amount1Desired,
            amount0Min: 0, // IMPORTANT: Add slippage protection in production!
            amount1Min: 0, // IMPORTANT: Add slippage protection in production!
            recipient: address(this), // The NFT will be minted to this contract
            deadline: _deadline
        });

        uint128 liquidity;
        uint256 amount0Actual;
        uint256 amount1Actual;

        // Mint a new position NFT
        (tokenId, liquidity, amount0Actual, amount1Actual) = INonfungiblePositionManager(UNISWAP_V3_POSITION_MANAGER).mint(params);

        // If actual amounts used are less than desired, refund the user
        if (amount0Actual < amount0Desired) {
            TransferHelper.safeTransfer(token0, msg.sender, amount0Desired - amount0Actual);
        }
        if (amount1Actual < amount1Desired) {
            TransferHelper.safeTransfer(token1, msg.sender, amount1Desired - amount1Actual);
        }

        // Claim any pending rewards first for this position (ecosystem-specific)
        claimRewards(_ecosystemAddress, tokenId);

        // Update user's stake position (ecosystem-specific)
        LibStake.StakePosition storage position = userStakes[msg.sender][_ecosystemAddress][tokenId];
        position.amount += liquidity; // Store liquidity units
        LibStake._updatePositionTimestamp(position);
        position.stakeType = LibStake.StakingType.Double;
        position.tokenId = tokenId; // Store the NFT tokenId

        // Update total staked amount (ecosystem-specific)
        totalStaked[_ecosystemAddress][tokenId] += liquidity;

        emit Staked(msg.sender, _ecosystemAddress, liquidity, pairedTokenAddress, LibStake.StakingType.Double);
        return tokenId;
    }

    /// @notice Allows a user to unstake their single staked ecosystem tokens for a specific ecosystem.
    /// @param _ecosystemAddress The address of the ecosystem's Diamond (also its ERC-20 token address).
    /// @param _amount The amount of ecosystem tokens to unstake.
    function unstakeSingle(address _ecosystemAddress, uint256 _amount) external {
        uint256 singleStakeId = LibStake._getSingleStakeIdentifier();
        LibStake.StakePosition storage position = userStakes[msg.sender][_ecosystemAddress][singleStakeId];

        require(_amount > 0, "StakingContract: Amount must be greater than 0");
        require(position.amount >= _amount, "StakingContract: Insufficient staked amount");
        require(position.stakeType == LibStake.StakingType.Single, "StakingContract: Not a single stake position");

        // Claim any pending rewards first (ecosystem-specific)
        claimRewards(_ecosystemAddress, singleStakeId);

        // Update user's stake position (ecosystem-specific)
        position.amount -= _amount;
        LibStake._updatePositionTimestamp(position);

        // Update total staked amount (ecosystem-specific)
        totalStaked[_ecosystemAddress][singleStakeId] -= _amount;

        // Transfer ecosystem tokens back to user
        // The _ecosystemAddress IS the ERC-20 token address for this ecosystem.
        TransferHelper.safeTransfer(_ecosystemAddress, msg.sender, _amount);

        emit Unstaked(msg.sender, _ecosystemAddress, _amount, _ecosystemAddress, LibStake.StakingType.Single);
    }

    /// @notice Allows a user to unstake their double staked liquidity from a Uniswap V3 pool for a specific ecosystem.
    /// @param _ecosystemAddress The address of the ecosystem's Diamond (also its ERC-20 token address).
    /// @param _tokenId The unique NFT ID of the Uniswap V3 position.
    /// @param _liquidityToBurn The amount of liquidity units to unstake.
    /// @param _deadline The timestamp by which the transaction must be included.
    /// @return amount0Received The amount of token0 received.
    /// @return amount1Received The amount of token1 received.
    function unstakeDouble(
        address _ecosystemAddress,
        uint256 _tokenId,
        uint128 _liquidityToBurn,
        uint256 _deadline
    ) external returns (uint256 amount0Received, uint256 amount1Received) {
        LibStake.StakePosition storage position = userStakes[msg.sender][_ecosystemAddress][_tokenId];

        require(_liquidityToBurn > 0, "StakingContract: Liquidity amount must be greater than 0");
        require(position.amount >= _liquidityToBurn, "StakingContract: Insufficient staked liquidity");
        require(position.stakeType == LibStake.StakingType.Double, "StakingContract: Not a double stake position");
        require(position.tokenId == _tokenId, "StakingContract: TokenId mismatch");
        require(_deadline >= block.timestamp, "StakingContract: Deadline has passed");

        // Claim any pending rewards first (ecosystem-specific)
        claimRewards(_ecosystemAddress, _tokenId);

        INonfungiblePositionManager positionManager = INonfungiblePositionManager(UNISWAP_V3_POSITION_MANAGER);

        // Decrease liquidity
        INonfungiblePositionManager.DecreaseLiquidityParams memory decreaseParams = INonfungiblePositionManager.DecreaseLiquidityParams({
            tokenId: _tokenId,
            liquidity: _liquidityToBurn,
            amount0Min: 0, // IMPORTANT: Add slippage protection in production!
            amount1Min: 0, // IMPORTANT: Add slippage protection in production!
            deadline: _deadline
        });

        (amount0Received, amount1Received) = positionManager.decreaseLiquidity(decreaseParams);

        // Update user's stake position (ecosystem-specific)
        position.amount -= _liquidityToBurn;
        LibStake._updatePositionTimestamp(position);

        // Update total staked amount (ecosystem-specific)
        totalStaked[_ecosystemAddress][_tokenId] -= _liquidityToBurn;

        // Transfer received tokens back to user
        (,,address token0, address token1,,,,,,,,) = positionManager.positions(_tokenId); // Get token info from the position NFT
        TransferHelper.safeTransfer(token0, msg.sender, amount0Received);
        TransferHelper.safeTransfer(token1, msg.sender, amount1Received);

        // If liquidity is now zero, burn the NFT
        if (position.amount == 0) {
            positionManager.burn(_tokenId);
            // Delete the position completely from storage
            delete userStakes[msg.sender][_ecosystemAddress][_tokenId];
            delete totalStaked[_ecosystemAddress][_tokenId];
        }

        emit Unstaked(msg.sender, _ecosystemAddress, _liquidityToBurn, token0, LibStake.StakingType.Double); // Emitting token0 as identifier
        return (amount0Received, amount1Received);
    }

    /// @notice Allows a user to claim their accrued rewards for a specific staked position in a specific ecosystem.
    /// @param _ecosystemAddress The address of the ecosystem's Diamond (also its ERC-20 token address).
    /// @param _id The identifier of the staked position (NFT tokenId for double, special ID for single).
    function claimRewards(address _ecosystemAddress, uint256 _id) public {
        LibStake.StakePosition storage position = userStakes[msg.sender][_ecosystemAddress][_id];
        require(position.amount > 0, "StakingContract: No active stake position to claim from");

        IStakeConfig stakeConfig = IStakeConfig(_ecosystemAddress);

        bool isSingleStake = (_id == LibStake._getSingleStakeIdentifier());
        address pairedTokenAddress = address(0);

        if (!isSingleStake) {
            // For double stake, need to get the actual paired token from the NFT position
            INonfungiblePositionManager positionManager = INonfungiblePositionManager(UNISWAP_V3_POSITION_MANAGER);
            (,,address token0, address token1,,,,,,,,) = positionManager.positions(_id);
            require(token0 != address(0), "StakingContract: Invalid Uniswap V3 position NFT");

            // Determine the paired token: it's the one not equal to the ecosystem's ERC-20 token
            pairedTokenAddress = (token0 == _ecosystemAddress) ? token1 : token0;

            // Collect fees from Uniswap V3 position to this contract
            INonfungiblePositionManager.CollectParams memory collectParams = INonfungiblePositionManager.CollectParams({
                tokenId: _id,
                recipient: address(this), // Fees collected to this contract
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });
            (uint256 collected0, uint256 collected1) = positionManager.collect(collectParams);

            // Send collected Uniswap V3 fees to the user.
            if (collected0 > 0) {
                TransferHelper.safeTransfer(token0, msg.sender, collected0);
            }
            if (collected1 > 0) {
                TransferHelper.safeTransfer(token1, msg.sender, collected1);
            }
        }

        // Calculate rewards based on the rate provided by the ecosystem's StakeConfigFacet
        uint256 pendingRewards = LibStake._calculatePendingRewards(stakeConfig, position, msg.sender, pairedTokenAddress);

        if (pendingRewards > 0) {
            // Transfer rewards to the user (assumed to be the ecosystem's ERC-20 token)
            TransferHelper.safeTransfer(_ecosystemAddress, msg.sender, pendingRewards);
            LibStake._updatePositionTimestamp(position); // Update timestamp after claiming
            emit RewardsClaimed(msg.sender, _ecosystemAddress, pendingRewards);
        }
    }

    // --- View Functions (Ecosystem-specific) ---

    /// @notice Returns if a user can stake in a given ecosystem.
    /// @param _ecosystemAddress The ecosystem's Diamond address.
    /// @param _user The user's address.
    function canStakeInEcosystem(address _ecosystemAddress, address _user) external view returns (bool) {
        IStakeConfig stakeConfig = IStakeConfig(_ecosystemAddress);
        return stakeConfig.canStake(_user);
    }

    /// @notice Returns the earning rate for a user in a given ecosystem.
    /// @param _ecosystemAddress The ecosystem's Diamond address.
    /// @param _user The user's address.
    /// @param _pairedToken The paired token for double stake (address(0) for single stake).
    function getEarningRate(address _ecosystemAddress, address _user, address _pairedToken) external view returns (uint16) {
        IStakeConfig stakeConfig = IStakeConfig(_ecosystemAddress);
        return stakeConfig.getStakeRate(_user, _pairedToken);
    }

    /// @notice Returns a user's current staked amount for a specific position identified by ID in a specific ecosystem.
    /// @param _user The address of the user.
    /// @param _ecosystemAddress The ecosystem's Diamond address.
    /// @param _id The identifier of the staked position (NFT tokenId for double, special ID for single).
    /// @return The staked amount (ecosystem tokens or liquidity units).
    function getStakedAmount(address _user, address _ecosystemAddress, uint256 _id) external view returns (uint256) {
        return userStakes[_user][_ecosystemAddress][_id].amount;
    }

    /// @notice Returns a user's pending rewards for a specific staked position in a specific ecosystem.
    /// @param _user The address of the user.
    /// @param _ecosystemAddress The ecosystem's Diamond address.
    /// @param _id The identifier of the staked position (NFT tokenId for double, special ID for single).
    /// @return The pending rewards amount.
    function getPendingRewards(address _user, address _ecosystemAddress, uint256 _id) external view returns (uint256) {
        LibStake.StakePosition storage position = userStakes[_user][_ecosystemAddress][_id];
        if (position.amount == 0) { // No active stake
            return 0;
        }

        IStakeConfig stakeConfig = IStakeConfig(_ecosystemAddress);
        bool isSingleStake = (_id == LibStake._getSingleStakeIdentifier());
        address pairedTokenAddress = address(0);

        if (!isSingleStake) {
            INonfungiblePositionManager positionManager = INonfungiblePositionManager(UNISWAP_V3_POSITION_MANAGER);
            (,,address token0, address token1,,,,,,,,) = positionManager.positions(_id);
            if (token0 != address(0)) { // Check if position exists
                pairedTokenAddress = (token0 == _ecosystemAddress) ? token1 : token0;
            }
        }
        return LibStake._calculatePendingRewards(stakeConfig, position, _user, pairedTokenAddress);
    }
}