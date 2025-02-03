//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "./AaveFoldStrategy.sol";

contract AaveFoldStrategyMainnet_USDT is AaveFoldStrategy {

  constructor() {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x493257fD37EDB34451f62EDf8D2a0C418852bA4C);
    address aToken = address(0xC48574bc5358c967d9447e7Df70230Fdb469e4E7);
    address debtToken = address(0x8992DB58077fe8C7B80c1B3a738eAe8A7BdDbA34);
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
