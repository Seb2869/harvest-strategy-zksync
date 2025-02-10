// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "./ReactorFusionFoldStrategy.sol";

contract ReactorFusionFoldStrategyMainnet_WBTC is ReactorFusionFoldStrategy {

  constructor() {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xBBeB516fb02a01611cBBE0453Fe3c580D7281011);
    address cToken = address(0x0a976E1E7D3052bEb46085AcBE1e0DAccF4A19CF);
    address comptroller = address(0x23848c28Af1C3AA7B999fA57e6b6E8599C17F3f2);
    address zk = address(0x5A7d6b2F92C77FAD6CCaBd7EE0624E64907Eaf3E);
    ReactorFusionFoldStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      cToken,
      comptroller,
      zk,
      624,
      799,
      false
    );
    rewardTokens = [zk];
  }
}