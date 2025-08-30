// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {StETH} from "../src/mock/StETH.sol";
import {WStETH} from "../src/mock/WStETH.sol";
import {TicketsLidoPot} from "../src/TicketsLidoPot.sol";

// @dev want to make sure mocks work as expected
contract LidoMockTest is Test {
    StETH steth;
    WStETH wsteth;

    address user = makeAddr("user");
    address admin = makeAddr("admin");

    function setUp() public {
        vm.prank(admin);
        steth = new StETH();

        wsteth = new WStETH(address(steth));
    }

    function test_basic() public {
        deal(address(steth), user, 1 ether);
        vm.prank(admin);
        TicketsLidoPot tickets = new TicketsLidoPot(0.1 ether, address(wsteth));

        assertEq(tickets.ticketPriceInSteth(), 0.1 ether);

        vm.startPrank(user);
        steth.approve(address(tickets), type(uint256).max);

        tickets.mint(10);
        assertEq(steth.balanceOf(user), 0);

        // burn n5
        tickets.burn(5);
        assertEq(steth.balanceOf(user), 0.1 ether);
        vm.expectRevert("NOT_MINTED");
        tickets.ownerOf(5);

        vm.stopPrank();

        address bob = makeAddr("bob");
        deal(address(steth), bob, 0.2 ether);

        vm.startPrank(bob);
        steth.approve(address(tickets), type(uint256).max);

        tickets.mint(2);
        vm.stopPrank();
        assertEq(steth.balanceOf(bob), 0);

        assertEq(tickets.ownerOf(5), bob);
        assertEq(tickets.ownerOf(11), bob);
    }
}
