// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

address constant SENTINEL = address(0x1);
address constant ZERO_ADDRESS = address(0x0);

import "EIP7702Storage/RDataLib.sol";

library SentinelListLib {
    using RData for RData.Address;

    struct SentinelList {
        mapping(address => RData.Address) entries;
    }

    error LinkedList_AlreadyInitialized();
    error LinkedList_InvalidPage();
    error LinkedList_InvalidEntry(address entry);
    error LinkedList_EntryAlreadyInList(address entry);

    function init(SentinelList storage self) internal {
        if (alreadyInitialized(self)) revert LinkedList_AlreadyInitialized();
        self.entries[SENTINEL].store(SENTINEL);
    }

    function alreadyInitialized(SentinelList storage self) internal view returns (bool) {
        return self.entries[SENTINEL].load() != ZERO_ADDRESS;
    }

    function getNext(SentinelList storage self, address entry) internal view returns (address) {
        if (entry == ZERO_ADDRESS) {
            revert LinkedList_InvalidEntry(entry);
        }
        return self.entries[entry].load();
    }

    function push(SentinelList storage self, address newEntry) internal {
        if (newEntry == ZERO_ADDRESS || newEntry == SENTINEL) {
            revert LinkedList_InvalidEntry(newEntry);
        }
        if (self.entries[newEntry].load() != ZERO_ADDRESS) {
            revert LinkedList_EntryAlreadyInList(newEntry);
        }
        self.entries[newEntry].store(self.entries[SENTINEL].load());
        self.entries[SENTINEL].store(newEntry);
    }

    function pop(SentinelList storage self, address prevEntry, address popEntry) internal {
        if (popEntry == ZERO_ADDRESS || popEntry == SENTINEL) {
            revert LinkedList_InvalidEntry(prevEntry);
        }
        if (self.entries[prevEntry].load() != popEntry) revert LinkedList_InvalidEntry(popEntry);
        self.entries[prevEntry].store(self.entries[popEntry].load());
        self.entries[popEntry].store(ZERO_ADDRESS);
    }

    function popAll(SentinelList storage self) internal {
        address next = self.entries[SENTINEL].load();
        while (next != ZERO_ADDRESS) {
            address current = next;
            next = self.entries[next].load();
            self.entries[current].store(ZERO_ADDRESS);
        }
        self.entries[SENTINEL].store(ZERO_ADDRESS);
    }

    function contains(SentinelList storage self, address entry) internal view returns (bool) {
        return SENTINEL != entry && self.entries[entry].load() != ZERO_ADDRESS;
    }

    function getEntriesPaginated(
        SentinelList storage self,
        address start,
        uint256 pageSize
    )
        internal
        view
        returns (address[] memory array, address next)
    {
        if (start != SENTINEL && !contains(self, start)) revert LinkedList_InvalidEntry(start);
        if (pageSize == 0) revert LinkedList_InvalidPage();
        // Init array with max page size
        array = new address[](pageSize);

        // Populate return array
        uint256 entryCount = 0;
        next = self.entries[start].load();
        while (next != ZERO_ADDRESS && next != SENTINEL && entryCount < pageSize) {
            array[entryCount] = next;
            next = self.entries[next].load();
            entryCount++;
        }

        /**
         * Because of the argument validation, we can assume that the loop will always iterate over the valid entry list values
         *       and the `next` variable will either be an enabled entry or a sentinel address (signalling the end).
         *
         *       If we haven't reached the end inside the loop, we need to set the next pointer to the last element of the entry array
         *       because the `next` variable (which is a entry by itself) acting as a pointer to the start of the next page is neither
         *       incSENTINELrent page, nor will it be included in the next one if you pass it as a start.
         */
        if (next != SENTINEL && entryCount > 0) {
            next = array[entryCount - 1];
        }
        // Set correct size of returned array
        // solhint-disable-next-line no-inline-assembly
        /// @solidity memory-safe-assembly
        assembly {
            mstore(array, entryCount)
        }
    }
}
