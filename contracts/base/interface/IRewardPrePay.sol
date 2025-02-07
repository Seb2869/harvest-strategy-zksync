// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;


interface IRewardPrePay {
    function ZK() external view returns (address);
    function strategyInitialized(address _strategy) external view returns (bool);
    function claimable(address _strategy) external view returns (uint256);
    function claim() external;
    function updateReward(address _strategy, uint256 _amount) external;
    function batchUpdateReward(address[] memory _strategies, uint256[] memory _amounts) external;
    function merklClaim(
        address strategy,
        uint256 newAmount,
        address merklDistr,
        address[] calldata users,
        address[] calldata tokens,
        uint256[] calldata amounts,
        bytes32[][] calldata proofs
    ) external;
    function batchMerklClaim(
        address[] calldata strategies,
        uint256[] calldata newAmounts,
        address[] calldata merklDistrs,
        address[][] calldata users,
        address[][] calldata tokens,
        uint256[][] calldata amounts,
        bytes32[][][] calldata proofs
    ) external;
}
