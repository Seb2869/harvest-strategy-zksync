// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

abstract contract UniV3DexStorage {
    mapping(address => mapping(address => uint24)) internal _pairFee;
}
