// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "./ReactorFusionFoldStrategy.sol";

contract ReactorFusionFoldStrategyMainnet_ZK is ReactorFusionFoldStrategy {

  constructor() {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x5A7d6b2F92C77FAD6CCaBd7EE0624E64907Eaf3E);
    address cToken = address(0x0E392B6b05c112677096920aD938a0752d1451f3);
    address comptroller = address(0x23848c28Af1C3AA7B999fA57e6b6E8599C17F3f2);
    address weth = address(0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91);
    ReactorFusionFoldStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      cToken,
      comptroller,
      weth,
      580,
      599,
      true
    );
    rewardTokens = [underlying];
  }
}