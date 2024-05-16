//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "./VelocoreStrategy.sol";

contract VelocoreStrategyMainnet_ETH_USDT is VelocoreStrategy {

  constructor() {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xF0e86a60Ae7e9bC0F1e59cAf3CC56f434b3024c0);
    address vc = address(0x99bBE51be7cCe6C8b84883148fD3D12aCe5787F2);
    address usdt = address(0x493257fD37EDB34451f62EDf8D2a0C418852bA4C);
    VelocoreStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      vc,
      usdt
    );
    rewardTokens = [vc];
  }
}
