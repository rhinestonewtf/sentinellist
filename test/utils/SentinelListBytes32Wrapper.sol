// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { LinkedBytes32Lib } from "src/SentinelListBytes32.sol";

contract SentinelListBytes32Wrapper {
    using LinkedBytes32Lib for LinkedBytes32Lib.LinkedBytes32;

    LinkedBytes32Lib.LinkedBytes32 internal list;

    function init() external {
        list.init();
    }

    function alreadyInitialized() external view returns (bool) {
        return list.alreadyInitialized();
    }

    function getNext(bytes32 entry) external view returns (bytes32) {
        return list.getNext(entry);
    }

    function push(bytes32 newEntry) external {
        list.push(newEntry);
    }

    function safePush(bytes32 newEntry) external {
        list.safePush(newEntry);
    }

    function pop(bytes32 prevEntry, bytes32 popEntry) external {
        list.pop(prevEntry, popEntry);
    }

    function popAll() external {
        list.popAll();
    }

    function contains(bytes32 entry) external view returns (bool) {
        return list.contains(entry);
    }

    function getEntriesPaginated(bytes32 start, uint256 pageSize)
        external
        view
        returns (bytes32[] memory array, bytes32 next)
    {
        return list.getEntriesPaginated(start, pageSize);
    }
}