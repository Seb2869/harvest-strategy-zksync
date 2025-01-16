//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "./VenusFoldStrategy.sol";

contract VenusFoldStrategyMainnet_USDT is VenusFoldStrategy {

  constructor() {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x493257fD37EDB34451f62EDf8D2a0C418852bA4C);
    address cToken = address(0x69cDA960E3b20DFD480866fFfd377Ebe40bd0A46);
    address comptroller = address(0xddE4D098D9995B659724ae6d5E3FB9681Ac941B1);
    address zk = address(0x5A7d6b2F92C77FAD6CCaBd7EE0624E64907Eaf3E);
    address xvs = address(0xD78ABD81a3D57712a3af080dc4185b698Fe9ac5A);
    VenusFoldStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      cToken,
      comptroller,
      xvs,
      750,
      769,
      1000,
      true
    );
    rewardTokens = [xvs, zk];
  }
}
