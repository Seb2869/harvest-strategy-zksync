// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.24;

interface IRouter {
    struct TokenInput {
        address token;
        uint amount;
        bool useVault;
    }

    function addLiquidity2(
        address pool,
        TokenInput[] calldata inputs,
        bytes calldata data,
        uint minLiquidity,
        address callback,
        bytes calldata callbackData,
        address staking
    ) external payable returns (uint liquidity);
}