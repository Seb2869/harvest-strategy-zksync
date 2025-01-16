//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "./AaveFoldStrategy.sol";

contract AaveFoldStrategyMainnet_ETH is AaveFoldStrategy {

  constructor() {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91);
    address aToken = address(0xb7b93bCf82519bB757Fd18b23A389245Dbd8ca64);
    address debtToken = address(0x98dC737eA0E9bCb254c3F98510a71c5E11F74238);
    address zk = address(0x5A7d6b2F92C77FAD6CCaBd7EE0624E64907Eaf3E);
    address usdce = address(0x3355df6D4c9C3035724Fd0e3914dE96A5a83aaf4);
    AaveFoldStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      aToken,
      debtToken,
      usdce,
      730,
      749,
      1000,
      true
    );
    rewardTokens = [zk];
  }
}
