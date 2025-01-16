//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "../aave/AaveFoldStrategy.sol";

contract ZerolendFoldStrategyMainnet_DAI is AaveFoldStrategy {

  constructor() {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x4B9eb6c0b6ea15176BBF62841C6B2A8a398cb656);
    address aToken = address(0x15b362768465F966F1E5983b7AE87f4C5Bf75C55);
    address debtToken = address(0x0325F21eB0A16802E2bACD931964434929985548);
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
