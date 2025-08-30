// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {StETH} from "../src/mock/StETH.sol";
import {WStETH} from "../src/mock/WStETH.sol";

// @dev want to make sure mocks work as expected
contract LidoMockTest is Test {
    StETH steth;
    WStETH wsteth;

    address user = makeAddr("user");

    function setUp() public {
        steth = new StETH();
        wsteth = new WStETH(address(steth));
    }

    function test_initialbalance() public {
        // deployer starts with 200 ether
        assertEq(steth.balanceOf(address(this)), 200 ether);
    }

    function test_airdrop() public {
        assertEq(steth.balanceOf(user), 0 ether);

        vm.prank(user);
        steth.airdrop();

        assertEq(steth.balanceOf(user), 1 ether);

        vm.prank(user);
        vm.expectRevert("ALREADY_AIRDROP");
        steth.airdrop();
    }

    function testSubmit(uint256 value) public {
        value = bound(value, 0, 50 ether);
        vm.deal(user, value);
        vm.prank(user);
        steth.submit{value: value}(address(0));

        assertEq(steth.balanceOf(user), value);
    }

    function testFoo(uint256 value) public {
        assertEq(steth.getPooledEthByShares(value), value);
        assertEq(steth.getPooledEthByShares(value), value);
    }
}
