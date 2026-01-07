// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { LinkedBytes32Lib, SENTINEL, ZERO } from "src/SentinelListBytes32.sol";

contract SentinelListBytes32Handler {
    using LinkedBytes32Lib for LinkedBytes32Lib.LinkedBytes32;

    LinkedBytes32Lib.LinkedBytes32 internal list;
    bytes32[] internal pushedEntries;
    mapping(bytes32 => bool) internal isPushedMap;
    mapping(bytes32 => uint256) internal indexMap;

    constructor() {
        list.init();
    }

    function contains(bytes32 entry) external view returns (bool) {
        return list.contains(entry);
    }

    function getNext(bytes32 entry) external view returns (bytes32) {
        return list.getNext(entry);
    }

    function alreadyInitialized() external view returns (bool) {
        return list.alreadyInitialized();
    }

    function push(bytes32 entry) external {
        if (entry == ZERO || entry == SENTINEL || isPushedMap[entry]) {
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

        bytes32 popEntry = pushedEntries[popIndex];
        if (!isPushedMap[popEntry] || !list.contains(popEntry)) {
            return;
        }

        bytes32 prevEntry;
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

    function _removeFromPushedEntries(bytes32 entry) internal {
        uint256 index = indexMap[entry];
        uint256 lastIndex = pushedEntries.length - 1;

        if (index != lastIndex) {
            bytes32 lastEntry = pushedEntries[lastIndex];
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

    function getPushedEntry(uint256 index) external view returns (bytes32) {
        return _getEntryAtIndex(index);
    }

    function _getActualListLength() internal view returns (uint256) {
        uint256 count = 0;
        bytes32 current = list.getNext(SENTINEL);

        while (current != ZERO && current != SENTINEL && count < 1000) {
            count++;
            current = list.getNext(current);
        }

        return count;
    }

    function _getEntryAtIndex(uint256 index) internal view returns (bytes32) {
        uint256 currentIndex = 0;
        bytes32 current = list.getNext(SENTINEL);

        while (current != ZERO && current != SENTINEL && currentIndex < 1000) {
            if (currentIndex == index) {
                return current;
            }
            currentIndex++;
            current = list.getNext(current);
        }

        return ZERO; // Index out of bounds
    }

    function isPushed(bytes32 entry) external view returns (bool) {
        return isPushedMap[entry];
    }

    function getEntriesPaginated(
        bytes32 start,
        uint256 pageSize
    )
        external
        view
        returns (bytes32[] memory, bytes32)
    {
        return list.getEntriesPaginated(start, pageSize);
    }

    // Helper function to generate bytes32 values for testing
    function generateBytes32(uint256 seed) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(seed));
    }
}
