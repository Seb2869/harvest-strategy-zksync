// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

interface IPoolFactory {
  function deploy(address _storage, address _vault) external returns (address);
}
