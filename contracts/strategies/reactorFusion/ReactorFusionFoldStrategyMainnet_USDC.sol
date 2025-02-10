// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "./ReactorFusionFoldStrategy.sol";

contract ReactorFusionFoldStrategyMainnet_USDC is ReactorFusionFoldStrategy {

  constructor() {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x1d17CBcF0D6D143135aE902365D2E5e2A16538D4);
    address cToken = address(0x930DA5E58f7F0D6DC417AB07e07558C78CFF1445);
    address comptroller = address(0x23848c28Af1C3AA7B999fA57e6b6E8599C17F3f2);
    address zk = address(0x5A7d6b2F92C77FAD6CCaBd7EE0624E64907Eaf3E);
    ReactorFusionFoldStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      cToken,
      comptroller,
      zk,
      830,
      849,
      true
    );
    rewardTokens = [zk];
  }
}