// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import { LinkedListLib } from "../src/LinkedListLib.sol";

/// @title LinkedListTest
/// @author zeroknots
contract LinkedListTest is Test {
    using LinkedListLib for LinkedListLib.LinkedList;

    LinkedListLib.LinkedList list;

    function setUp() public {
        list.init();
    }

    function testAdd() public {
        address addr1 = makeAddr("1");
        address addr2 = makeAddr("2");
        list.push(addr2);
        assertFalse(list.contains(addr1));
        assertTrue(list.contains(addr2));
    }

    function testRemove() public {
        address addr1 = makeAddr("1");
        address addr2 = makeAddr("2");
        address addr3 = makeAddr("3");
        address addr4 = makeAddr("4");

        list.push(addr1);
        list.push(addr2);
        list.push(addr3);
        list.push(addr4);

        list.pop(addr3, addr2);

        assertTrue(list.contains(addr1));
        assertFalse(list.contains(addr2));
        assertTrue(list.contains(addr3));
        assertTrue(list.contains(addr4));

        list.push(addr2);

        assertTrue(list.contains(addr1));
        assertTrue(list.contains(addr2));
        assertTrue(list.contains(addr3));
        assertTrue(list.contains(addr4));
    }
}
