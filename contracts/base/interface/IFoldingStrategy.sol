// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;


interface IFoldingStrategy {
  function borrowTargetFactorNumerator() external view returns (uint256);
}
