//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "./VelocoreStrategy.sol";

contract VelocoreStrategyMainnet_ETH_USDCe is VelocoreStrategy {

  constructor() {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x42D106c4A1d0Bc5C482c11853A3868d807A3781d);
    address vc = address(0x99bBE51be7cCe6C8b84883148fD3D12aCe5787F2);
    address usdce = address(0x3355df6D4c9C3035724Fd0e3914dE96A5a83aaf4);
    VelocoreStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      vc,
      usdce
    );
    rewardTokens = [vc];
  }
}
