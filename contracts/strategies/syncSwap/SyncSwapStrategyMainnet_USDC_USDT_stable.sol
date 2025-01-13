//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "./SyncSwapStrategy.sol";

contract SyncSwapStrategyMainnet_USDC_USDT_stable is SyncSwapStrategy {

  constructor() {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x0259d9Dfb638775858B1D072222237E2Ce7111C0);
    address zk = address(0x5A7d6b2F92C77FAD6CCaBd7EE0624E64907Eaf3E);
    address weth = address(0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91);
    address usdc = address(0x1d17CBcF0D6D143135aE902365D2E5e2A16538D4);
    address router = address(0x9B5def958d0f3b6955cBEa4D5B7809b2fb26b059);
    SyncSwapStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      address(0),
      weth,
      usdc,
      router,
      false
    );
    rewardTokens = [zk];
    setBoolean(_STAKE, false);
  }
}
