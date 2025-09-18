// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { SentinelList4337Lib } from "src/SentinelList4337.sol";

contract SentinelList4337Wrapper {
    using SentinelList4337Lib for SentinelList4337Lib.SentinelList;

    SentinelList4337Lib.SentinelList internal list;

    function init(address account) external {
        list.init(account);
    }

    function alreadyInitialized(address account) external view returns (bool) {
        return list.alreadyInitialized(account);
    }

    function getNext(address account, address entry) external view returns (address) {
        return list.getNext(account, entry);
    }

    function push(address account, address newEntry) external {
        list.push(account, newEntry);
    }

    function safePush(address account, address newEntry) external {
        list.safePush(account, newEntry);
    }

    function pop(address account, address prevEntry, address popEntry) external {
        list.pop(account, prevEntry, popEntry);
    }

    function popAll(address account) external {
        list.popAll(account);
    }

    function contains(address account, address entry) external view returns (bool) {
        return list.contains(account, entry);
    }

    function getEntriesPaginated(address account, address start, uint256 pageSize)
        external
        view
        returns (address[] memory array, address next)
    {
        return list.getEntriesPaginated(account, start, pageSize);
    }
}