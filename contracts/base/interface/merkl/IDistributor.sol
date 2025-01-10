//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

interface IDistributor {
    function toggleOperator(address user, address operator) external;
}