//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

interface IDex {
    function setFee(address token0, address token1, uint24 fee) external;
}