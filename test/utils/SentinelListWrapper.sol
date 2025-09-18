// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { SentinelListLib } from "src/SentinelList.sol";

contract SentinelListWrapper {
    using SentinelListLib for SentinelListLib.SentinelList;

    SentinelListLib.SentinelList internal list;

    function init() external {
        list.init();
    }

    function alreadyInitialized() external view returns (bool) {
        return list.alreadyInitialized();
    }

    function getNext(address entry) external view returns (address) {
        return list.getNext(entry);
    }

    function push(address newEntry) external {
        list.push(newEntry);
    }

    function safePush(address newEntry) external {
        list.safePush(newEntry);
    }

    function pop(address prevEntry, address popEntry) external {
        list.pop(prevEntry, popEntry);
    }

    function popAll() external {
        list.popAll();
    }

    function contains(address entry) external view returns (bool) {
        return list.contains(entry);
    }

    function getEntriesPaginated(address start, uint256 pageSize)
        external
        view
        returns (address[] memory array, address next)
    {
        return list.getEntriesPaginated(start, pageSize);
    }
}