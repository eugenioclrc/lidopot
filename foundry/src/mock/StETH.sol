// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {IStETH} from "../ILido.sol";

contract StETH is ERC20("Staked Ether", "stETH", 18) {
    mapping(address => bool) _aidrops;

    constructor() {
        _mint(msg.sender, 200 ether);
    }

    function airdrop() external {
        require(!_aidrops[msg.sender], "ALREADY_AIRDROP");
        _aidrops[msg.sender] = true;
        _mint(msg.sender, 1 ether);
    }

    function submit(address) external payable {
        _mint(msg.sender, msg.value);
    }

    function getPooledEthByShares(uint256 shares) external view returns (uint256) {
        return shares; // 1 to 1 ratio for this mock
    }

    function getSharesByPooledEth(uint256 pooledEth) external view returns (uint256) {
        return pooledEth; // 1 to 1 ratio for this mock
    }
}
