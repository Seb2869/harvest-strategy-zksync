//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "./VelocoreStrategy.sol";

contract VelocoreStrategyMainnet_WBTC_ETH is VelocoreStrategy {

  constructor() {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xf47430Bbbe7474eC024e66deE2470b4d05B48804);
    address vc = address(0x99bBE51be7cCe6C8b84883148fD3D12aCe5787F2);
    address wbtc = address(0xBBeB516fb02a01611cBBE0453Fe3c580D7281011);
    VelocoreStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      vc,
      wbtc
    );
    rewardTokens = [vc];
  }
}
