// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import "./DataTypes.sol";

interface IPool {
  function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf) external;
  function repay(address asset, uint256 amount, uint256 interestRateMode, address onBehalfOf) external;
  function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
  function withdraw(address asset, uint256 amount, address to) external;
  function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);
  function getUserAccountData(address user) external view returns (uint256 totalCollateralBase, uint256 totalDebtBase, uint256 availableBorrowsBase, uint256 currentLiquidationThreshold, uint256 ltv, uint256 healthFactor);
  function ADDRESSES_PROVIDER() external view returns (address);
}