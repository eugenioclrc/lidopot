// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {IStETH, IWstETH} from "../ILido.sol";

contract WStETH is ERC20("Wrapped Staked Ether", "wstETH", 18) {
    address public stETH;
    IStETH private steth;

    constructor(address _stETH) {
        stETH = _stETH;
        steth = IStETH(_stETH);
    }

    function wrap(uint256 _stETHAmount) external returns (uint256) {
        uint256 amount = getWstETHByStETH(_stETHAmount);
        steth.transferFrom(msg.sender, address(this), _stETHAmount);
        _mint(msg.sender, amount);
        return amount;
    }

    /**
     * @notice Exchanges wstETH to stETH
     * @param _wstETHAmount amount of wstETH to uwrap in exchange for stETH
     * @dev Requirements:
     *  - `_wstETHAmount` must be non-zero
     *  - msg.sender must have at least `_wstETHAmount` wstETH.
     * @return Amount of stETH user receives after unwrap
     */
    function unwrap(uint256 _wstETHAmount) external returns (uint256) {
        _burn(msg.sender, _wstETHAmount);
        uint256 amount = getStETHByWstETH(_wstETHAmount);
        steth.transfer(msg.sender, amount);
        return amount;
    }

    /**
     * @notice Get amount of wstETH for a given amount of stETH
     * @param _stETHAmount amount of stETH
     * @return Amount of wstETH for a given stETH amount
     */
    function getWstETHByStETH(uint256 _stETHAmount) public view returns (uint256) {
        if (totalSupply == 0) {
            return _stETHAmount;
        }
        uint256 amount = totalSupply * 1 ether / steth.balanceOf(address(this));

        // _stETHAmount = x wsETH
        return amount * _stETHAmount / 1 ether;
    }

    /**
     * @notice Get amount of stETH for a given amount of wstETH
     * @param _wstETHAmount amount of wstETH
     * @return Amount of stETH for a given wstETH amount
     */
    function getStETHByWstETH(uint256 _wstETHAmount) public view returns (uint256) {
        uint256 amount = steth.balanceOf(address(this)) * 1 ether / totalSupply;
        return _wstETHAmount * amount / 1 ether;
    }

    /**
     * @notice Get amount of stETH for a one wstETH
     * @return Amount of stETH for 1 wstETH
     */
    function stEthPerToken() external view returns (uint256) {
        return getStETHByWstETH(1 ether);
    }
    /**
     * @notice Get amount of wstETH for a one stETH
     * @return Amount of wstETH for a 1 stETH
     */

    function tokensPerStEth() external view returns (uint256) {
        return totalSupply * 1 ether;
    }
}
