//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "./AaveFoldStrategy.sol";

contract AaveFoldStrategyMainnet_USDC is AaveFoldStrategy {

  constructor() {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x1d17CBcF0D6D143135aE902365D2E5e2A16538D4);
    address aToken = address(0xE977F9B2a5ccf0457870a67231F23BE4DaecfbDb);
    address debtToken = address(0x0049250D15A8550c5a14Baa5AF5B662a93a525B9);
    address zk = address(0x5A7d6b2F92C77FAD6CCaBd7EE0624E64907Eaf3E);
    address weth = address(0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91);
    AaveFoldStrategy.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      aToken,
      debtToken,
      weth,
      730,
      749,
      1000,
      true
    );
    rewardTokens = [zk];
  }
}
