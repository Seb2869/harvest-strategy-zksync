//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "./ZKSwapStrategy.sol";

contract ZKSwapStrategyMainnet_LONG_ETH is ZKSwapStrategy {

  constructor() {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xD32b34bc9690322c609c1cc15f88E440e73cE2dB);
    address masterChef = address(0x9F9D043fB77A194b4216784Eb5985c471b979D67);
    address zf = address(0x31C2c031fDc9d33e974f327Ab0d9883Eae06cA4A);
    address router = address(0x18381c0f738146Fb694DE18D1106BdE2BE040Fa4);
    ZKSwapStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      masterChef,
      zf,
      router,
      21        // Pool id
    );
    rewardTokens = [zf];
  }
}
