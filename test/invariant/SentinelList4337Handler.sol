// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { SentinelList4337Lib, SENTINEL, ZERO_ADDRESS } from "src/SentinelList4337.sol";

contract SentinelList4337Handler {
    using SentinelList4337Lib for SentinelList4337Lib.SentinelList;

    SentinelList4337Lib.SentinelList internal list;

    // Track entries per account
    mapping(address => address[]) internal pushedEntriesPerAccount;
    mapping(address => mapping(address => bool)) internal isPushedMapPerAccount;
    mapping(address => mapping(address => uint256)) internal indexMapPerAccount;

    address[] internal testAccounts;
    mapping(address => bool) internal accountExists;

    constructor() {
        // Create some test accounts
        testAccounts.push(makeAddr("account1"));
        testAccounts.push(makeAddr("account2"));
        testAccounts.push(makeAddr("account3"));

        for (uint256 i = 0; i < testAccounts.length; i++) {
            accountExists[testAccounts[i]] = true;
            list.init(testAccounts[i]);
        }
    }

    function makeAddr(string memory name) internal pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(name)))));
    }

    function contains(address account, address entry) external view returns (bool) {
        return list.contains(account, entry);
    }

    function getNext(address account, address entry) external view returns (address) {
        return list.getNext(account, entry);
    }

    function alreadyInitialized(address account) external view returns (bool) {
        return list.alreadyInitialized(account);
    }

    function getTestAccount(uint256 index) external view returns (address) {
        return testAccounts[index % testAccounts.length];
    }

    function getTestAccountsLength() external view returns (uint256) {
        return testAccounts.length;
    }

    function push(uint256 accountIndex, address entry) external {
        address account = testAccounts[accountIndex % testAccounts.length];

        if (entry == ZERO_ADDRESS || entry == SENTINEL || isPushedMapPerAccount[account][entry]) {
            return;
        }

        if (list.contains(account, entry)) {
            return;
        }

        list.push(account, entry);
        pushedEntriesPerAccount[account].push(entry);
        isPushedMapPerAccount[account][entry] = true;
        indexMapPerAccount[account][entry] = pushedEntriesPerAccount[account].length - 1;
    }

    function pop(uint256 accountIndex, uint256 prevIndex, uint256 popIndex) external {
        address account = testAccounts[accountIndex % testAccounts.length];
        address[] storage accountEntries = pushedEntriesPerAccount[account];

        if (accountEntries.length == 0 || popIndex >= accountEntries.length) {
            return;
        }

        address popEntry = accountEntries[popIndex];
        if (!isPushedMapPerAccount[account][popEntry] || !list.contains(account, popEntry)) {
            return;
        }

        address prevEntry;
        if (prevIndex == 0) {
            prevEntry = SENTINEL;
        } else if (prevIndex <= accountEntries.length) {
            prevEntry = accountEntries[prevIndex - 1];
            if (!isPushedMapPerAccount[account][prevEntry] || !list.contains(account, prevEntry)) {
                return;
            }
        } else {
            return;
        }

        if (list.getNext(account, prevEntry) != popEntry) {
            return;
        }

        list.pop(account, prevEntry, popEntry);
        _removeFromPushedEntries(account, popEntry);
    }

    function popAll(uint256 accountIndex) external {
        address account = testAccounts[accountIndex % testAccounts.length];
        address[] storage accountEntries = pushedEntriesPerAccount[account];

        if (accountEntries.length == 0) {
            return;
        }

        list.popAll(account);

        for (uint256 i = 0; i < accountEntries.length; i++) {
            isPushedMapPerAccount[account][accountEntries[i]] = false;
            delete indexMapPerAccount[account][accountEntries[i]];
        }
        delete pushedEntriesPerAccount[account];
    }

    function _removeFromPushedEntries(address account, address entry) internal {
        uint256 index = indexMapPerAccount[account][entry];
        address[] storage accountEntries = pushedEntriesPerAccount[account];
        uint256 lastIndex = accountEntries.length - 1;

        if (index != lastIndex) {
            address lastEntry = accountEntries[lastIndex];
            accountEntries[index] = lastEntry;
            indexMapPerAccount[account][lastEntry] = index;
        }

        accountEntries.pop();
        isPushedMapPerAccount[account][entry] = false;
        delete indexMapPerAccount[account][entry];
    }

    function getPushedEntriesCount(address account) external view returns (uint256) {
        return _getActualListLength(account);
    }

    function getPushedEntry(address account, uint256 index) external view returns (address) {
        return _getEntryAtIndex(account, index);
    }

    function _getActualListLength(address account) internal view returns (uint256) {
        uint256 count = 0;
        address current = list.getNext(account, SENTINEL);

        while (current != ZERO_ADDRESS && current != SENTINEL && count < 1000) {
            count++;
            current = list.getNext(account, current);
        }

        return count;
    }

    function _getEntryAtIndex(address account, uint256 index) internal view returns (address) {
        uint256 currentIndex = 0;
        address current = list.getNext(account, SENTINEL);

        while (current != ZERO_ADDRESS && current != SENTINEL && currentIndex < 1000) {
            if (currentIndex == index) {
                return current;
            }
            currentIndex++;
            current = list.getNext(account, current);
        }

        return ZERO_ADDRESS; // Index out of bounds
    }

    function isPushed(address account, address entry) external view returns (bool) {
        return isPushedMapPerAccount[account][entry];
    }

    function getEntriesPaginated(
        address account,
        address start,
        uint256 pageSize
    )
        external
        view
        returns (address[] memory, address)
    {
        return list.getEntriesPaginated(account, start, pageSize);
    }

    function getTotalPushedEntriesAcrossAllAccounts() external view returns (uint256 total) {
        for (uint256 i = 0; i < testAccounts.length; i++) {
            total += pushedEntriesPerAccount[testAccounts[i]].length;
        }
    }
}
