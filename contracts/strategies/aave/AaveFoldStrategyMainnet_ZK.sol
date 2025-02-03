//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "./AaveFoldStrategy.sol";

contract AaveFoldStrategyMainnet_ZK is AaveFoldStrategy {

  constructor() {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x5A7d6b2F92C77FAD6CCaBd7EE0624E64907Eaf3E);
    address aToken = address(0xd6cD2c0fC55936498726CacC497832052A9B2D1B);
    address debtToken = address(0x6450fd7F877B5bB726F7Bc6Bf0e6ffAbd48d72ad);
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
      399,
      1000,
      false
    );
    rewardTokens = [zk];
  }
}
