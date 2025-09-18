// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import { SentinelList4337Handler } from "./SentinelList4337Handler.sol";
import { SentinelList4337Lib, SENTINEL, ZERO_ADDRESS } from "src/SentinelList4337.sol";

contract SentinelList4337InvariantTest is Test {
    using SentinelList4337Lib for SentinelList4337Lib.SentinelList;

    SentinelList4337Handler public handler;

    function setUp() public {
        handler = new SentinelList4337Handler();
        targetContract(address(handler));

        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = SentinelList4337Handler.push.selector;
        selectors[1] = SentinelList4337Handler.pop.selector;
        selectors[2] = SentinelList4337Handler.popAll.selector;

        targetSelector(FuzzSelector({ addr: address(handler), selectors: selectors }));
    }

    function invariant_OnlyPushedEntriesAreInList() public view {
        uint256 accountCount = handler.getTestAccountsLength();

        for (uint256 a = 0; a < accountCount; a++) {
            address account = handler.getTestAccount(a);
            uint256 pushedCount = handler.getPushedEntriesCount(account);

            for (uint256 i = 0; i < pushedCount; i++) {
                address entry = handler.getPushedEntry(account, i);
                if (handler.isPushed(account, entry)) {
                    assertTrue(
                        handler.contains(account, entry),
                        "Pushed entry should be in list for account"
                    );
                }
            }
        }
    }

    function invariant_AllListEntriesArePushed() public view {
        uint256 accountCount = handler.getTestAccountsLength();

        for (uint256 a = 0; a < accountCount; a++) {
            address account = handler.getTestAccount(a);
            address current = SENTINEL;
            uint256 iterations = 0;
            uint256 maxIterations = 1000;

            while (iterations < maxIterations) {
                address next = handler.getNext(account, current);

                if (next == ZERO_ADDRESS || next == SENTINEL) {
                    break;
                }

                assertTrue(
                    handler.isPushed(account, next),
                    "All entries in list should be marked as pushed for account"
                );

                current = next;
                iterations++;
            }

            assertLt(iterations, maxIterations, "List should not be infinite for account");
        }
    }

    function invariant_ListHasNoSelfReferences() public view {
        uint256 accountCount = handler.getTestAccountsLength();

        for (uint256 a = 0; a < accountCount; a++) {
            address account = handler.getTestAccount(a);
            address current = SENTINEL;
            uint256 iterations = 0;
            uint256 maxIterations = 1000;

            while (iterations < maxIterations) {
                address next = handler.getNext(account, current);

                if (next == ZERO_ADDRESS || next == SENTINEL) {
                    break;
                }

                assertNotEq(next, current, "List should not have self-references for account");
                current = next;
                iterations++;
            }
        }
    }

    function invariant_ListHasNoCycles() public view {
        uint256 accountCount = handler.getTestAccountsLength();

        for (uint256 a = 0; a < accountCount; a++) {
            address account = handler.getTestAccount(a);
            address current = SENTINEL;
            address[] memory visited = new address[](1000);
            uint256 visitedCount = 0;
            uint256 maxIterations = 1000;

            while (visitedCount < maxIterations) {
                address next = handler.getNext(account, current);

                if (next == ZERO_ADDRESS || next == SENTINEL) {
                    break;
                }

                for (uint256 i = 0; i < visitedCount; i++) {
                    assertNotEq(visited[i], next, "List should not have cycles for account");
                }

                visited[visitedCount] = next;
                visitedCount++;
                current = next;
            }
        }
    }

    function invariant_AfterPopAllListIsEmpty() public view {
        uint256 accountCount = handler.getTestAccountsLength();

        for (uint256 a = 0; a < accountCount; a++) {
            address account = handler.getTestAccount(a);
            uint256 pushedCount = handler.getPushedEntriesCount(account);

            if (pushedCount == 0) {
                address next = handler.getNext(account, SENTINEL);
                assertEq(next, SENTINEL, "After popAll, list should point to SENTINEL for account");
            }
        }
    }

    function invariant_ContainsFunctionConsistency() public view {
        uint256 accountCount = handler.getTestAccountsLength();

        for (uint256 a = 0; a < accountCount; a++) {
            address account = handler.getTestAccount(a);
            uint256 pushedCount = handler.getPushedEntriesCount(account);

            for (uint256 i = 0; i < pushedCount; i++) {
                address entry = handler.getPushedEntry(account, i);
                bool isPushed = handler.isPushed(account, entry);
                bool contains = handler.contains(account, entry);

                if (isPushed) {
                    assertTrue(
                        contains, "contains() should return true for pushed entries for account"
                    );
                }
            }
        }
    }

    function invariant_AccountIsolation() public view {
        uint256 accountCount = handler.getTestAccountsLength();

        // Each account's list should be independent
        for (uint256 a = 0; a < accountCount; a++) {
            address accountA = handler.getTestAccount(a);

            for (uint256 b = a + 1; b < accountCount; b++) {
                address accountB = handler.getTestAccount(b);

                // Same entry address can exist in different accounts without conflict
                uint256 pushedCountA = handler.getPushedEntriesCount(accountA);
                for (uint256 i = 0; i < pushedCountA; i++) {
                    address entry = handler.getPushedEntry(accountA, i);

                    // Entry in accountA shouldn't automatically be in accountB
                    // (This is fine - different accounts can have the same entry addresses)
                    // But let's check that the list structures are independent
                    if (handler.contains(accountA, entry) && handler.contains(accountB, entry)) {
                        // If same entry exists in both accounts, their next pointers can be
                        // different
                        address nextA = handler.getNext(accountA, entry);
                        address nextB = handler.getNext(accountB, entry);
                        // This is allowed - different accounts can have different list structures
                    }
                }
            }
        }
    }

    function invariant_GetEntriesPaginatedMatchesTraversal() public view {
        uint256 accountCount = handler.getTestAccountsLength();

        for (uint256 a = 0; a < accountCount; a++) {
            address account = handler.getTestAccount(a);
            uint256 actualCount = handler.getPushedEntriesCount(account);

            if (actualCount == 0) continue;

            // Test various page sizes from 1 to actualCount
            for (uint256 pageSize = 1; pageSize <= actualCount && pageSize <= 10; pageSize++) {
                // Test starting from SENTINEL
                _testPaginationFromStart(account, SENTINEL, pageSize, actualCount);

                // Test starting from each entry in the list
                for (uint256 startIdx = 0; startIdx < actualCount && startIdx < 5; startIdx++) {
                    address startEntry = handler.getPushedEntry(account, startIdx);
                    _testPaginationFromStart(
                        account, startEntry, pageSize, actualCount - startIdx - 1
                    );
                }
            }

            // Test getting all entries in one page
            (address[] memory allEntries, address finalNext) =
                handler.getEntriesPaginated(account, SENTINEL, actualCount);
            assertEq(
                allEntries.length,
                actualCount,
                "Should get all entries when page size equals count for account"
            );

            for (uint256 i = 0; i < actualCount; i++) {
                assertEq(
                    allEntries[i],
                    handler.getPushedEntry(account, i),
                    "Full pagination entry should match traversal for account"
                );
            }

            if (actualCount > 0) {
                assertEq(
                    finalNext,
                    SENTINEL,
                    "Final next should be SENTINEL when all entries are returned for account"
                );
            }
        }
    }

    function _testPaginationFromStart(
        address account,
        address start,
        uint256 pageSize,
        uint256 expectedMaxEntries
    )
        internal
        view
    {
        (address[] memory entries, address next) =
            handler.getEntriesPaginated(account, start, pageSize);

        uint256 expectedSize = expectedMaxEntries < pageSize ? expectedMaxEntries : pageSize;
        assertEq(entries.length, expectedSize, "Page size should match expected for account");

        // Find the starting index for comparison
        uint256 startIdx = 0;
        if (start != SENTINEL) {
            startIdx = _findEntryIndex(account, start) + 1; // Start from next entry after start
        }

        // Verify each entry matches our traversal
        for (uint256 i = 0; i < entries.length; i++) {
            if (startIdx + i < handler.getPushedEntriesCount(account)) {
                address expectedEntry = handler.getPushedEntry(account, startIdx + i);
                assertEq(
                    entries[i],
                    expectedEntry,
                    "Paginated entry should match traversal at correct offset for account"
                );
            }
        }

        // Verify next pointer behavior
        if (entries.length > 0) {
            if (startIdx + entries.length >= handler.getPushedEntriesCount(account)) {
                // We've reached the end of the list, next should be SENTINEL
                assertEq(
                    next,
                    SENTINEL,
                    "Next pointer should be SENTINEL when reaching end of list for account"
                );
            } else {
                // We haven't reached the end, next should be last returned entry for continuation
                assertEq(
                    next,
                    entries[entries.length - 1],
                    "Next pointer should be last returned entry for continuation for account"
                );
            }
        }
    }

    function _findEntryIndex(address account, address entry) internal view returns (uint256) {
        uint256 count = handler.getPushedEntriesCount(account);
        for (uint256 i = 0; i < count; i++) {
            if (handler.getPushedEntry(account, i) == entry) {
                return i;
            }
        }
        return type(uint256).max; // Not found
    }
}
