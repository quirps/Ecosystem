pragma solidity ^0.8.6;

import "../internals/ERC1155/iERC1155.sol";
import "../internals/ERC1155/iERC1155Transfer.sol";

import "../interfaces/IERC1155Transfer.sol";

import "../libraries/LibERC20.sol";
import "../libraries/utils/Context.sol";
import "../libraries/LibERC1155.sol";

contract iERC20 is iERC1155, iERC1155Transfer {
    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);



    function _balanceOf(address account) internal view returns (uint256 balance_) {}

    function _transfer(address to, uint256 amount) internal virtual returns (bool) {
        //require to != address(0) in iERC1155Transfer

        _safeTransferFrom(_msgSender(), to, 0, amount, "");
        emit Transfer(_msgSender(), to, amount);

        return true;
    }

    function _transferFrom(address from, address to, uint256 amount) internal virtual returns (bool) {
        //require to != address(0) in iERC1155Transfer

        _safeTransferFrom(from, to, 0, amount, "");
        emit Transfer(from, to, amount);

        return true;
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address _spender, uint256 _value) internal virtual returns (bool) {
        require(_spender != address(0), "ERC20: approve to the zero address");

        _setApprovalForAll(msgSender(),_spender, _value != 0);

        emit Approval(msgSender(), _spender, _value != 0 ? type(uint256).max : type(uint256).min);

        return true;
    }

    function _allowance(address owner, address spender) internal view returns (uint256 allowance_) {
        allowance_ = LibERC1155.getOperatorApproval(owner, spender) ? type(uint256).max : type(uint256).min;
    }


}
/**
 * This should be a fairly static facet
 * The only part we need to detail is how the address is handled. Going back through every time
 * the diamond is expensive (using the Diamond Interface). We can simply use the current erc1155transfer
 * address and interact directly with it. Likely cheaper to simply re-deploy this contract so we can
 * hardcode address. Solution. In deployment sequence set in constructor as a constant, DONE!
 */

/**
 * How to deal with changes in main currency?
 * Symbol, Decimals, Name, ERC1155 Token ID
 * For another time
 */

/**
 * Combine facets? No, just utilize internals of others. Give its own facet
 */
