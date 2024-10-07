// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.24;

interface IStakingPool {
    function stake(uint amount, address onBehalf) external;
    function claimRewards(address account, uint8 mode, bytes calldata claimData) external;
    function withdraw(uint256 amount, address receiver) external;
    function userStaked(address user) external view returns(uint256);
    function shareToken() external view returns(address);
}