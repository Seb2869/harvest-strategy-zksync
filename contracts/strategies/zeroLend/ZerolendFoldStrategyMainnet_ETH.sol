//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "../aave/AaveFoldStrategy.sol";

contract ZerolendFoldStrategyMainnet_ETH is AaveFoldStrategy {

  constructor() {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91);
    address aToken = address(0x9002ecb8a06060e3b56669c6B8F18E1c3b119914);
    address debtToken = address(0x56f58d9BE10929CdA709c4134eF7343D73B080Cf);
    address zk = address(0x5A7d6b2F92C77FAD6CCaBd7EE0624E64907Eaf3E);
    address usdce = address(0x3355df6D4c9C3035724Fd0e3914dE96A5a83aaf4);
    AaveFoldStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      aToken,
      debtToken,
      usdce,
      780,
      799,
      1000,
      true
    );
    rewardTokens = [zk];
  }
}
