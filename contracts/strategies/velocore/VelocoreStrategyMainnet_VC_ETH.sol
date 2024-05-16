//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "./VelocoreStrategy.sol";

contract VelocoreStrategyMainnet_VC_ETH is VelocoreStrategy {

  constructor() {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xd0e8EeE2CB04F8474453d9a8a5D960788C0a3ADa);
    address vc = address(0x99bBE51be7cCe6C8b84883148fD3D12aCe5787F2);
    VelocoreStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      vc,
      vc
    );
    rewardTokens = [vc];
  }
}
