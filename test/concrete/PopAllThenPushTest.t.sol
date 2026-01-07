// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import { SentinelListLib, SENTINEL, ZERO_ADDRESS } from "src/SentinelList.sol";

contract PopAllThenPushTest is Test {
    using SentinelListLib for SentinelListLib.SentinelList;

    SentinelListLib.SentinelList list;

    function setUp() public {
        list.init();
    }

    function test_PopAllThenPushWorks() external {
        address addr1 = makeAddr("addr1");
        address addr2 = makeAddr("addr2");
        address addr3 = makeAddr("addr3");

        // Push some entries
        list.push(addr1);
        list.push(addr2);

        // Verify they're in the list
        assertTrue(list.contains(addr1));
        assertTrue(list.contains(addr2));

        // PopAll should remove everything
        list.popAll();

        // Verify list is empty
        assertFalse(list.contains(addr1));
        assertFalse(list.contains(addr2));

        // After popAll, SENTINEL should point to SENTINEL
        address next = list.getNext(SENTINEL);
        assertEq(next, SENTINEL, "After popAll, SENTINEL should point to SENTINEL");

        // List should still be initialized
        assertTrue(list.alreadyInitialized(), "List should remain initialized after popAll");

        // Now push should work correctly
        list.push(addr3);

        // Verify the new entry is in the list
        assertTrue(list.contains(addr3));
        assertFalse(list.contains(addr1)); // old entries should still be gone
        assertFalse(list.contains(addr2));

        // Verify list structure is correct
        address nextAfterPush = list.getNext(SENTINEL);
        assertEq(nextAfterPush, addr3, "SENTINEL should point to newly pushed entry");

        address nextAfterAddr3 = list.getNext(addr3);
        assertEq(nextAfterAddr3, SENTINEL, "New entry should point back to SENTINEL");
    }

    function test_MultiplePopAllThenPushCycles() external {
        address addr1 = makeAddr("addr1");
        address addr2 = makeAddr("addr2");

        // Cycle 1: push → popAll → push
        list.push(addr1);
        assertTrue(list.contains(addr1));

        list.popAll();
        assertFalse(list.contains(addr1));

        list.push(addr2);
        assertTrue(list.contains(addr2));
        assertFalse(list.contains(addr1));

        // Cycle 2: popAll → push again
        list.popAll();
        assertFalse(list.contains(addr2));

        list.push(addr1); // reuse addr1
        assertTrue(list.contains(addr1));
        assertFalse(list.contains(addr2));

        // Verify list is still properly structured
        address next = list.getNext(SENTINEL);
        assertEq(next, addr1);

        next = list.getNext(addr1);
        assertEq(next, SENTINEL);
    }
}
