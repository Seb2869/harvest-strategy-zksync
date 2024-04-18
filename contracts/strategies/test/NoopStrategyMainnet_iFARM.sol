//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "../../base/noop/NoopStrategyUpgradeable.sol";

contract NoopStrategyMainnet_iFARM is NoopStrategyUpgradeable {

  constructor() {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x659EF1727551b0c9Dd78CB2c231A5d13d42216d0);
    NoopStrategyUpgradeable.initializeBaseStrategy(
      _storage,
      underlying,
      _vault
    );
  }
}
