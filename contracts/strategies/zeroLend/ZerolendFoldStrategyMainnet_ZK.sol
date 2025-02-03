//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "../aave/AaveFoldStrategy.sol";

contract ZerolendFoldStrategyMainnet_ZK is AaveFoldStrategy {

  constructor() {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x5A7d6b2F92C77FAD6CCaBd7EE0624E64907Eaf3E);
    address aToken = address(0x072416442a0e40135E75C0EEfB4BE708b74B6c8a);
    address debtToken = address(0x863CD5f43a50E1141574b796D412F73232CbA60C);
    address zk = address(0x5A7d6b2F92C77FAD6CCaBd7EE0624E64907Eaf3E);
    address weth = address(0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91);
    AaveFoldStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      aToken,
      debtToken,
      weth,
      780,
      799,
      1000,
      true
    );
    rewardTokens = [zk];
  }
}
