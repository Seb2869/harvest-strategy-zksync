// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "./ReactorFusionFoldStrategy.sol";

contract ReactorFusionFoldStrategyMainnet_ZK is ReactorFusionFoldStrategy {

  constructor() {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x5A7d6b2F92C77FAD6CCaBd7EE0624E64907Eaf3E);
    address cToken = address(0x0E392B6b05c112677096920aD938a0752d1451f3);
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
      380,
      399,
      true
    );
    rewardTokens = [rf];
  }
}