//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "./AaveFoldStrategy.sol";

contract AaveFoldStrategyMainnet_wstETH is AaveFoldStrategy {

  constructor() {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x703b52F2b28fEbcB60E1372858AF5b18849FE867);
    address aToken = address(0xd4e607633F3d984633E946aEA4eb71f92564c1c9);
    address debtToken = address(0x6aD279F6523f6421fD5B0324a97D8F62eeCD80c8);
    address zk = address(0x5A7d6b2F92C77FAD6CCaBd7EE0624E64907Eaf3E);
    address weth = address(0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91);
    AaveFoldStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      aToken,
      debtToken,
      weth,
      690,
      709,
      1000,
      true
    );
    rewardTokens = [zk];
  }
}
