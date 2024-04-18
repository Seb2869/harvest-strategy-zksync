// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface ILiquidityDex {
    function doSwap(
        uint256 _sellAmount,
        uint256 _minBuyAmount,
        address _receiver,
        address[] memory _path
    ) external returns (uint256);
}
