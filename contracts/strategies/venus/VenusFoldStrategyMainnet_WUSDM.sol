//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "./VenusFoldStrategy.sol";

contract VenusFoldStrategyMainnet_WUSDM is VenusFoldStrategy {

  constructor() {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0xA900cbE7739c96D2B153a273953620A701d5442b);
    address cToken = address(0x183dE3C349fCf546aAe925E1c7F364EA6FB4033c);
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
      730,
      749,
      1000,
      true
    );
    rewardTokens = [xvs, zk];
  }
}
