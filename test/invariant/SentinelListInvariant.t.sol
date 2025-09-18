// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import { SentinelListHandler } from "./SentinelListHandler.sol";
import { SentinelListLib, SENTINEL, ZERO_ADDRESS } from "src/SentinelList.sol";

contract SentinelListInvariantTest is Test {
    using SentinelListLib for SentinelListLib.SentinelList;

    SentinelListHandler public handler;

    function setUp() public {
        handler = new SentinelListHandler();
        targetContract(address(handler));

        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = SentinelListHandler.push.selector;
        selectors[1] = SentinelListHandler.pop.selector;
        selectors[2] = SentinelListHandler.popAll.selector;

        targetSelector(FuzzSelector({ addr: address(handler), selectors: selectors }));
    }

    function invariant_OnlyPushedEntriesAreInList() public view {
        uint256 pushedCount = handler.getPushedEntriesCount();

        for (uint256 i = 0; i < pushedCount; i++) {
            address entry = handler.getPushedEntry(i);
            if (handler.isPushed(entry)) {
                assertTrue(handler.contains(entry), "Pushed entry should be in list");
            }
        }
    }

    function invariant_AllListEntriesArePushed() public view {
        address current = SENTINEL;
        uint256 iterations = 0;
        uint256 maxIterations = 1000;

        while (iterations < maxIterations) {
            address next = handler.getNext(current);

            if (next == ZERO_ADDRESS || next == SENTINEL) {
                break;
            }

            assertTrue(handler.isPushed(next), "All entries in list should be marked as pushed");

            current = next;
            iterations++;
        }

        assertLt(iterations, maxIterations, "List should not be infinite");
    }

    function invariant_ListHasNoSelfReferences() public view {
        address current = SENTINEL;
        uint256 iterations = 0;
        uint256 maxIterations = 1000;

        while (iterations < maxIterations) {
            address next = handler.getNext(current);

            if (next == ZERO_ADDRESS || next == SENTINEL) {
                break;
            }

            assertNotEq(next, current, "List should not have self-references");
            current = next;
            iterations++;
        }
    }

    function invariant_ListHasNoCycles() public view {
        address current = SENTINEL;
        address[] memory visited = new address[](1000);
        uint256 visitedCount = 0;
        uint256 maxIterations = 1000;

        while (visitedCount < maxIterations) {
            address next = handler.getNext(current);

            if (next == ZERO_ADDRESS || next == SENTINEL) {
                break;
            }

            for (uint256 i = 0; i < visitedCount; i++) {
                assertNotEq(visited[i], next, "List should not have cycles");
            }

            visited[visitedCount] = next;
            visitedCount++;
            current = next;
        }
    }

    function invariant_AfterPopAllListIsEmpty() public view {
        uint256 pushedCount = handler.getPushedEntriesCount();

        if (pushedCount == 0) {
            address next = handler.getNext(SENTINEL);
            assertEq(next, SENTINEL, "After popAll, list should point to SENTINEL");
        }
    }

    function invariant_ContainsFunctionConsistency() public view {
        uint256 pushedCount = handler.getPushedEntriesCount();

        for (uint256 i = 0; i < pushedCount; i++) {
            address entry = handler.getPushedEntry(i);
            bool isPushed = handler.isPushed(entry);
            bool contains = handler.contains(entry);

            if (isPushed) {
                assertTrue(contains, "contains() should return true for pushed entries");
            }
        }
    }

    function invariant_GetEntriesPaginatedMatchesTraversal() public view {
        uint256 actualCount = handler.getPushedEntriesCount();

        if (actualCount == 0) return;

        // Test various page sizes from 1 to actualCount
        for (uint256 pageSize = 1; pageSize <= actualCount && pageSize <= 10; pageSize++) {
            // Test starting from SENTINEL
            _testPaginationFromStart(SENTINEL, pageSize, actualCount);

            // Test starting from each entry in the list
            for (uint256 startIdx = 0; startIdx < actualCount && startIdx < 5; startIdx++) {
                address startEntry = handler.getPushedEntry(startIdx);
                _testPaginationFromStart(startEntry, pageSize, actualCount - startIdx - 1);
            }
        }

        // Test getting all entries in one page
        (address[] memory allEntries, address finalNext) =
            handler.getEntriesPaginated(SENTINEL, actualCount);
        assertEq(
            allEntries.length, actualCount, "Should get all entries when page size equals count"
        );

        for (uint256 i = 0; i < actualCount; i++) {
            assertEq(
                allEntries[i],
                handler.getPushedEntry(i),
                "Full pagination entry should match traversal"
            );
        }

        // When we get all entries, next should be SENTINEL (end of list)
        if (actualCount > 0) {
            assertEq(
                finalNext, SENTINEL, "Final next should be SENTINEL when all entries are returned"
            );
        }
    }

    function _testPaginationFromStart(
        address start,
        uint256 pageSize,
        uint256 expectedMaxEntries
    )
        internal
        view
    {
        (address[] memory entries, address next) = handler.getEntriesPaginated(start, pageSize);

        uint256 expectedSize = expectedMaxEntries < pageSize ? expectedMaxEntries : pageSize;
        assertEq(entries.length, expectedSize, "Page size should match expected");

        // Find the starting index for comparison
        uint256 startIdx = 0;
        if (start != SENTINEL) {
            startIdx = _findEntryIndex(start) + 1; // Start from next entry after start
        }

        // Verify each entry matches our traversal
        for (uint256 i = 0; i < entries.length; i++) {
            if (startIdx + i < handler.getPushedEntriesCount()) {
                address expectedEntry = handler.getPushedEntry(startIdx + i);
                assertEq(
                    entries[i],
                    expectedEntry,
                    "Paginated entry should match traversal at correct offset"
                );
            }
        }

        // Verify next pointer behavior
        if (entries.length > 0) {
            if (startIdx + entries.length >= handler.getPushedEntriesCount()) {
                // We've reached the end of the list, next should be SENTINEL
                assertEq(
                    next, SENTINEL, "Next pointer should be SENTINEL when reaching end of list"
                );
            } else {
                // We haven't reached the end, next should be last returned entry for continuation
                assertEq(
                    next,
                    entries[entries.length - 1],
                    "Next pointer should be last returned entry for continuation"
                );
            }
        }
    }

    function _findEntryIndex(address entry) internal view returns (uint256) {
        uint256 count = handler.getPushedEntriesCount();
        for (uint256 i = 0; i < count; i++) {
            if (handler.getPushedEntry(i) == entry) {
                return i;
            }
        }
        return type(uint256).max; // Not found
    }
}
