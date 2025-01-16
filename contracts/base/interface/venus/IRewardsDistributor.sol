//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

interface IRewardsDistributor {
    function claimRewardToken(address holder) external;
}