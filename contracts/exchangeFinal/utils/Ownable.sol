// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CustomOwnable
 * @dev Minimalist Ownable contract.
 * Functions as a replacement for OpenZeppelin's Ownable to provide direct control
 * over error messages and simplify testing.
 */
contract Ownable { // Removed 'abstract' keyword
    address private _owner;

    // Custom error for unauthorized access
    error OwnableUnauthorizedAccount(address caller);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Throws if `msg.sender` is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != msg.sender) {
            revert OwnableUnauthorizedAccount(msg.sender);
        }
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        // Add a check for zero address if you want to prevent ownership transfer to address(0)
        if (newOwner == address(0)) revert OwnableUnauthorizedAccount(address(0)); // Or a more specific error
        _transferOwnership(newOwner);
    }

    /**
     * @dev Internal function to transfer ownership, not exposed externally.
     * @param newOwner The address of the new owner.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
