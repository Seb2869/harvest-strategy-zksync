//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "../aave/AaveFoldStrategy.sol";

contract ZerolendFoldStrategyMainnet_USDCe is AaveFoldStrategy {

  constructor() {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x3355df6D4c9C3035724Fd0e3914dE96A5a83aaf4);
    address aToken = address(0x016341e6Da8da66b33Fd32189328c102f32Da7CC);
    address debtToken = address(0xE60E1953aF56Db378184997cab20731d17c65004);
    address zk = address(0x5A7d6b2F92C77FAD6CCaBd7EE0624E64907Eaf3E);
    address weth = address(0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91);
    AaveFoldStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      aToken,
      debtToken,
      weth,
      780,
      799,
      1000,
      true
    );
    rewardTokens = [zk];
  }
}
