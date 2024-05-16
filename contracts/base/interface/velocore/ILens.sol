// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Token.sol";
import "./IGauge.sol";

interface ILens {
    struct BribeData {
        Token[] tokens;
        uint256[] rates;
        uint256[] userClaimable;
        uint256[] userRates;
    }
    struct GaugeData {
        address gauge;
        PoolData poolData;
        bool killed;
        uint256 totalVotes;
        uint256 userVotes;
        uint256 userClaimable;
        uint256 emissionRate;
        uint256 userEmissionRate;
        uint256 stakedValueInHubToken;
        uint256 userStakedValueInHubToken;
        uint256 averageInterestRatePerSecond;
        uint256 userInterestRatePerSecond;
        Token[] stakeableTokens;
        uint256[] stakedAmounts;
        uint256[] userStakedAmounts;
        Token[] underlyingTokens;
        uint256[] stakedUnderlying;
        uint256[] userUnderlying;
        BribeData[] bribes;
    }
    struct PoolData {
        address pool;
        string poolType;
        // lp tokens
        Token[] lpTokens;
        uint256[] mintedLPTokens;
        // tokens constituting the lp token
        Token[] listedTokens;
        uint256[] reserves;
        bytes poolParams;
    }
    //type 'Token' here is byte32. look 'How to interact with Velocore' for the details
    function spotPrice(address swap, Token base, Token quote, uint256 baseAmount) external view returns (uint256);
    function spotPrice(Token base, Token quote, uint256 amount) external view returns (uint256);
    function spotPrice(Token quote, Token[] memory tok, uint256[] memory amount) external view returns (uint256);
    function userBalances(address user, Token[] calldata ts) external view returns (uint256[] memory balances);
    function wombatGauges(address user) external view returns (GaugeData[] memory gaugeDataArray);
    function canonicalPools(address user, uint256 begin, uint256 maxLength) external view returns (GaugeData[] memory gaugeDataArray);
    function canonicalPoolLength() external view returns (uint256);
    function queryGauge(address gauge, address user) external view returns (GaugeData memory poolData);
    function getPoolBalance(address pool, Token t) external view returns (uint256);
    function queryPool(address pool) external view returns (PoolData memory ret);
    function emissionRate(IGauge gauge) external view returns (uint256);

    //additional price query function added on Linea
    function wombatPrice(address wombatPool, Token asset, Token unit, uint256 amount) external view returns (uint256);
}