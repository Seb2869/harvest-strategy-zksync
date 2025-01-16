//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

interface IDistributor {
    function toggleOperator(address user, address operator) external;
    function claim(address[] calldata users, address[] calldata tokens, uint256[] calldata amounts, bytes32[][] calldata proofs) external;
}