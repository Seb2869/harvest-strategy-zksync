//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "../aave/AaveFoldStrategy.sol";

contract ZerolendFoldStrategyMainnet_WBTC is AaveFoldStrategy {

  constructor() {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xBBeB516fb02a01611cBBE0453Fe3c580D7281011);
    address aToken = address(0x7c65E6eC6fECeb333092e6FE69672a3475C591fB);
    address debtToken = address(0xaBd3C4E4AC6e0d81FCfa5C41a76e9583a8f81909);
    address zk = address(0x5A7d6b2F92C77FAD6CCaBd7EE0624E64907Eaf3E);
    address weth = address(0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91);
    AaveFoldStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      aToken,
      debtToken,
      weth,
      680,
      699,
      1000,
      true
    );
    rewardTokens = [zk];
  }
}
