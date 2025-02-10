// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "./ReactorFusionFoldStrategy.sol";

contract ReactorFusionFoldStrategyMainnet_ETH is ReactorFusionFoldStrategy {

  constructor() {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91);
    address cToken = address(0xC5db68F30D21cBe0C9Eac7BE5eA83468d69297e6);
    address comptroller = address(0x23848c28Af1C3AA7B999fA57e6b6E8599C17F3f2);
    address zk = address(0x5A7d6b2F92C77FAD6CCaBd7EE0624E64907Eaf3E);
    ReactorFusionFoldStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      cToken,
      comptroller,
      zk,
      0,
      799,
      true
    );
    rewardTokens = [zk];
  }
}