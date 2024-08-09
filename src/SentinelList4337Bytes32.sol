// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Sentinel bytes32
bytes32 constant SENTINEL = bytes32(uint256(1));
// Zero bytes32
bytes32 constant ZERO = bytes32(0x0);

/**
 * @title SentinelListLib
 * @dev Library for managing a linked list of bytes32
 * @author Rhinestone
 */
library Linked4337Bytes32Lib {
    // Struct to hold the linked list
    struct LinkedBytes32 {
        mapping(bytes32 => mapping(address account => bytes32)) entries;
    }

    error LinkedList_AlreadyInitialized();
    error LinkedList_InvalidPage();
    error LinkedList_InvalidEntry(bytes32 entry);
    error LinkedList_EntryAlreadyInList(bytes32 entry);

    /**
     * Initialize the linked list
     *
     * @param self The linked list
     */
    function init(LinkedBytes32 storage self, address account) internal {
        if (alreadyInitialized(self, account)) revert LinkedList_AlreadyInitialized();
        self.entries[SENTINEL][account] = SENTINEL;
    }

    /**
     * Check if the linked list is already initialized
     *
     * @param self The linked list
     *
     * @return bool True if the linked list is already initialized
     */
    function alreadyInitialized(
        LinkedBytes32 storage self,
        address account
    )
        internal
        view
        returns (bool)
    {
        return self.entries[SENTINEL][account] != ZERO;
    }

    /**
     * Get the next entry in the linked list
     *
     * @param self The linked list
     * @param entry The current entry
     *
     * @return bytes32 The next entry
     */
    function getNext(
        LinkedBytes32 storage self,
        address account,
        bytes32 entry
    )
        internal
        view
        returns (bytes32)
    {
        if (entry == ZERO) {
            revert LinkedList_InvalidEntry(entry);
        }
        return self.entries[entry][account];
    }

    /**
     * Push a new entry to the linked list
     *
     * @param self The linked list
     * @param newEntry The new entry to push
     */
    function push(LinkedBytes32 storage self, address account, bytes32 newEntry) internal {
        if (newEntry == ZERO || newEntry == SENTINEL) {
            revert LinkedList_InvalidEntry(newEntry);
        }
        if (self.entries[newEntry][account] != ZERO) revert LinkedList_EntryAlreadyInList(newEntry);
        self.entries[newEntry][account] = self.entries[SENTINEL][account];
        self.entries[SENTINEL][account] = newEntry;
    }

    /**
     * Safe push a new entry to the linked list
     * @dev This ensures that the linked list is initialized and initializes it if it is not
     *
     * @param self The linked list
     * @param newEntry The new entry to push
     */
    function safePush(LinkedBytes32 storage self, address account, bytes32 newEntry) internal {
        if (!alreadyInitialized({ account: account, self: self })) {
            init({ self: self, account: account });
        }
        push({ self: self, account: account, newEntry: newEntry });
    }

    /**
     * Pop an entry from the linked list
     *
     * @param self The linked list
     * @param prevEntry The entry before the entry to pop
     * @param popEntry The entry to pop
     */
    function pop(
        LinkedBytes32 storage self,
        address account,
        bytes32 prevEntry,
        bytes32 popEntry
    )
        internal
    {
        if (popEntry == ZERO || popEntry == SENTINEL) {
            revert LinkedList_InvalidEntry(prevEntry);
        }
        if (self.entries[prevEntry][account] != popEntry) revert LinkedList_InvalidEntry(popEntry);
        self.entries[prevEntry][account] = self.entries[popEntry][account];
        self.entries[popEntry][account] = ZERO;
    }

    /**
     * Pop all entries from the linked list
     *
     * @param self The linked list
     */
    function popAll(LinkedBytes32 storage self, address account) internal {
        bytes32 next = self.entries[SENTINEL][account];
        while (next != ZERO) {
            bytes32 current = next;
            next = self.entries[next][account];
            self.entries[current][account] = ZERO;
        }
    }

    function popAll(
        LinkedBytes32 storage self,
        address account,
        function(address, bytes32) internal _callback
    )
        internal
    {
        bytes32 next = self.entries[SENTINEL][account];
        while (next != ZERO) {
            bytes32 current = next;
            next = self.entries[next][account];
            self.entries[current][account] = ZERO;
            _callback(account, current);
        }
    }

    /**
     * Check if the linked list contains an entry
     *
     * @param self The linked list
     * @param entry The entry to check for
     *
     * @return bool True if the linked list contains the entry
     */
    function contains(
        LinkedBytes32 storage self,
        address account,
        bytes32 entry
    )
        internal
        view
        returns (bool)
    {
        return SENTINEL != entry && self.entries[entry][account] != ZERO;
    }

    /**
     * Get the entries in the linked list paginated
     *
     * @param self The linked list
     * @param account The account to get the entries for
     * @param start The entry to start from
     * @param pageSize The size of the page
     *
     * @return array The entries in the page
     * @return next The next entry to start from
     */
    function getEntriesPaginated(
        LinkedBytes32 storage self,
        address account,
        bytes32 start,
        uint256 pageSize
    )
        internal
        view
        returns (bytes32[] memory array, bytes32 next)
    {
        if (start != SENTINEL && !contains(self, account, start)) {
            revert LinkedList_InvalidEntry(start);
        }
        if (pageSize == 0) revert LinkedList_InvalidPage();
        // Init array with max page size
        array = new bytes32[](pageSize);

        // Populate return array
        uint256 entryCount = 0;
        next = self.entries[start][account];
        while (next != ZERO && next != SENTINEL && entryCount < pageSize) {
            array[entryCount] = next;
            next = self.entries[next][account];
            entryCount++;
        }

        /**
         * Because of the argument validation, we can assume that the loop will always iterate over
         * the valid entry list values
         *       and the `next` variable will either be an enabled entry or a sentinel bytes32
         * (signalling the end).
         *
         *       If we haven't reached the end inside the loop, we need to set the next pointer to
         * the last element of the entry array
         *       because the `next` variable (which is a entry by itself) acting as a pointer to the
         * start of the next page is neither
         *       incSENTINELrent page, nor will it be included in the next one if you pass it as a
         * start.
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
