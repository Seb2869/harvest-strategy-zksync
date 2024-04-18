// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

library Errors {
    // UniversalLiquidatorRegistry errors
    error InvalidLength();
    error DexExists();
    error DexDoesNotExist();
    error PathsNotExist();
    // UniversalLiquidator errors
    error InvalidAddress();
}
