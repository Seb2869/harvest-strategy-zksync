// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "./ReactorFusionFoldStrategy.sol";

contract ReactorFusionFoldStrategyMainnet_USDCe is ReactorFusionFoldStrategy {

  constructor() {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x3355df6D4c9C3035724Fd0e3914dE96A5a83aaf4);
    address cToken = address(0x04e9Db37d8EA0760072e1aCE3F2A219988Fdac29);
    address comptroller = address(0x23848c28Af1C3AA7B999fA57e6b6E8599C17F3f2);
    address rewards = address(0x53C0DE201cab0b3f74EA7C1D95bD76F76EfD12A9);
    address rf = address(0x5f7CBcb391d33988DAD74D6Fd683AadDA1123E4D);
    ReactorFusionFoldStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      cToken,
      comptroller,
      rewards,
      rf,
      0,
      850,
      false
    );
    rewardTokens = [rf];
  }
}