//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "../aave/AaveFoldStrategy.sol";

contract ZerolendFoldStrategyMainnet_MBTC is AaveFoldStrategy {

  constructor() {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xE757355edba7ced7B8c0271BBA4eFDa184aD75Ab);
    address aToken = address(0xafe91971600af83D23AB691B0a1A566d5F8E42c0);
    address debtToken = address(0x8450646d1ea5F4FeF8Ab6aF95CFfbb29664Af011);
    address zk = address(0x5A7d6b2F92C77FAD6CCaBd7EE0624E64907Eaf3E);
    address weth = address(0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91);
    AaveFoldStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      aToken,
      debtToken,
      weth,
      480,
      499,
      1000,
      true
    );
    rewardTokens = [zk];
  }
}
