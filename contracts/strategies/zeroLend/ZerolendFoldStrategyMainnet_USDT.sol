//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "../aave/AaveFoldStrategy.sol";

contract ZerolendFoldStrategyMainnet_USDT is AaveFoldStrategy {

  constructor() {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x493257fD37EDB34451f62EDf8D2a0C418852bA4C);
    address aToken = address(0x9ca4806fa54984Bf5dA4E280b7AA8bB821D21505);
    address debtToken = address(0xa333c6FF89525939271E796FbDe2a2D9A970F831);
    address zk = address(0x5A7d6b2F92C77FAD6CCaBd7EE0624E64907Eaf3E);
    address weth = address(0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91);
    AaveFoldStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      aToken,
      debtToken,
      weth,
      0,
      749,
      1000,
      false
    );
    rewardTokens = [zk];
  }
}
