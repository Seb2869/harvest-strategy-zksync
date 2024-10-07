//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "./SyncSwapStrategy.sol";

contract SyncSwapStrategyMainnet_USDCe_USDT_stable is SyncSwapStrategy {

  constructor() {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x0E595bfcAfb552F83E25d24e8a383F88c1Ab48A4);
    address stakingPool = address(0xA8E14510eb6FC00b979e0C72fF9580ed62b6851d);
    address zk = address(0x5A7d6b2F92C77FAD6CCaBd7EE0624E64907Eaf3E);
    address usdce = address(0x3355df6D4c9C3035724Fd0e3914dE96A5a83aaf4);
    address router = address(0x9B5def958d0f3b6955cBEa4D5B7809b2fb26b059);
    SyncSwapStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      stakingPool,
      zk,
      usdce,
      router,
      true
    );
    rewardTokens = [zk];
  }
}
