// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { SentinelListLib, SENTINEL, ZERO_ADDRESS } from "src/SentinelList.sol";

contract SentinelListHandler {
    using SentinelListLib for SentinelListLib.SentinelList;

    SentinelListLib.SentinelList internal list;
    address[] internal pushedEntries;
    mapping(address => bool) internal isPushedMap;
    mapping(address => uint256) internal indexMap;

    constructor() {
        list.init();
    }

    function contains(address entry) external view returns (bool) {
        return list.contains(entry);
    }

    function getNext(address entry) external view returns (address) {
        return list.getNext(entry);
    }

    function alreadyInitialized() external view returns (bool) {
        return list.alreadyInitialized();
    }

    function push(address entry) external {
        if (entry == ZERO_ADDRESS || entry == SENTINEL || isPushedMap[entry]) {
            return;
        }

        if (list.contains(entry)) {
            return;
        }

        list.push(entry);
        pushedEntries.push(entry);
        isPushedMap[entry] = true;
        indexMap[entry] = pushedEntries.length - 1;
    }

    function pop(uint256 prevIndex, uint256 popIndex) external {
        if (pushedEntries.length == 0 || popIndex >= pushedEntries.length) {
            return;
        }

        address popEntry = pushedEntries[popIndex];
        if (!isPushedMap[popEntry] || !list.contains(popEntry)) {
            return;
        }

        address prevEntry;
        if (prevIndex == 0) {
            prevEntry = SENTINEL;
        } else if (prevIndex <= pushedEntries.length) {
            prevEntry = pushedEntries[prevIndex - 1];
            if (!isPushedMap[prevEntry] || !list.contains(prevEntry)) {
                return;
            }
        } else {
            return;
        }

        if (list.getNext(prevEntry) != popEntry) {
            return;
        }

        list.pop(prevEntry, popEntry);
        _removeFromPushedEntries(popEntry);
    }

    function popAll() external {
        if (pushedEntries.length == 0) {
            return;
        }

        list.popAll();

        for (uint256 i = 0; i < pushedEntries.length; i++) {
            isPushedMap[pushedEntries[i]] = false;
            delete indexMap[pushedEntries[i]];
        }
        delete pushedEntries;
    }

    function _removeFromPushedEntries(address entry) internal {
        uint256 index = indexMap[entry];
        uint256 lastIndex = pushedEntries.length - 1;

        if (index != lastIndex) {
            address lastEntry = pushedEntries[lastIndex];
            pushedEntries[index] = lastEntry;
            indexMap[lastEntry] = index;
        }

        pushedEntries.pop();
        isPushedMap[entry] = false;
        delete indexMap[entry];
    }

    function getPushedEntriesCount() external view returns (uint256) {
        return _getActualListLength();
    }

    function getPushedEntry(uint256 index) external view returns (address) {
        return _getEntryAtIndex(index);
    }

    function _getActualListLength() internal view returns (uint256) {
        uint256 count = 0;
        address current = list.getNext(SENTINEL);

        while (current != ZERO_ADDRESS && current != SENTINEL && count < 1000) {
            count++;
            current = list.getNext(current);
        }

        return count;
    }

    function _getEntryAtIndex(uint256 index) internal view returns (address) {
        uint256 currentIndex = 0;
        address current = list.getNext(SENTINEL);

        while (current != ZERO_ADDRESS && current != SENTINEL && currentIndex < 1000) {
            if (currentIndex == index) {
                return current;
            }
            currentIndex++;
            current = list.getNext(current);
        }

        return ZERO_ADDRESS; // Index out of bounds
    }

    function isPushed(address entry) external view returns (bool) {
        return isPushedMap[entry];
    }

    function getEntriesPaginated(
        address start,
        uint256 pageSize
    )
        external
        view
        returns (address[] memory, address)
    {
        return list.getEntriesPaginated(start, pageSize);
    }
}
