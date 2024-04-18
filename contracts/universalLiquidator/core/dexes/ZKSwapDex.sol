// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// imported contracts and libraries
import "./UniBasedDex.sol";

// libraries
import "../../libraries/Addresses.sol";

contract ZKSwapDex is UniBasedDex(Addresses.zkSwapRouter) {}
