//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "../aave/AaveFoldStrategy.sol";

contract ZerolendFoldStrategyMainnet_USDC is AaveFoldStrategy {

  constructor() {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x1d17CBcF0D6D143135aE902365D2E5e2A16538D4);
    address aToken = address(0x9E20e83d636870A887CE7C85CeCfB8b3e95c9Db2);
    address debtToken = address(0x5C9fa0a3EE84cbc892AB9968d7c5086CC506432d);
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
      799,
      1000,
      false
    );
    rewardTokens = [zk];
  }
}
