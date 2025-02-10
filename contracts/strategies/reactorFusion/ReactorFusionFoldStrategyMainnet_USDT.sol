// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "./ReactorFusionFoldStrategy.sol";

contract ReactorFusionFoldStrategyMainnet_USDT is ReactorFusionFoldStrategy {

  constructor() {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x493257fD37EDB34451f62EDf8D2a0C418852bA4C);
    address cToken = address(0x894cccB9908A0319381c305f947aD0EF44838591);
    address comptroller = address(0x23848c28Af1C3AA7B999fA57e6b6E8599C17F3f2);
    address zk = address(0x5A7d6b2F92C77FAD6CCaBd7EE0624E64907Eaf3E);
    ReactorFusionFoldStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      cToken,
      comptroller,
      zk,
      0,
      849,
      false
    );
    rewardTokens = [zk];
  }
}