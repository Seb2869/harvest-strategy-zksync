//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "../aave/AaveFoldStrategy.sol";

contract ZerolendFoldStrategyMainnet_LUSD is AaveFoldStrategy {

  constructor() {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x503234F203fC7Eb888EEC8513210612a43Cf6115);
    address aToken = address(0xd97Ac0ce99329EE19b97d03E099eB42D7Aa19ddB);
    address debtToken = address(0x41c618CCE58Fb27cAF4EEb1dd25de1d03A0DAAc6);
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
      1,
      1000,
      false
    );
    rewardTokens = [zk];
  }
}
