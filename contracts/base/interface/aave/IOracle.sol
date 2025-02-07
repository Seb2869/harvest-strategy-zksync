// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

interface IOracle {
  function getAssetPrice(address _asset) external view returns (uint256);
}