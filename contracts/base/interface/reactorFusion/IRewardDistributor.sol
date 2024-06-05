// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.10;

interface IRewardDistributor {
    function harvest(bytes32[] memory ledgerIds) external returns (uint256);
    function borrowSlot(address cToken) external pure returns (bytes32);
    function supplySlot(address cToken) external pure returns (bytes32);
}
