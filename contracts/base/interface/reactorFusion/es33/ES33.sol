// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IRouter.sol";
import "../interfaces/IPair.sol";
import "../../weth/IWETH.sol";
import "../lib/RPow.sol";
import "../lib/Ledger.sol";

import "../../velocore/IVault.sol";

interface IRewardDistributor {
    function reap() external;
    function migrate() external returns (address);

    function emissionRates() external returns (uint256, uint256);
}

struct ES33Parameters {
    uint256 initialSupply;
    uint256 maxSupply;
    uint256 decay;
    uint256 unstakingTime;
    uint256 protocolFeeRate;
    uint256 tradeStart;
    uint256 emissionStart;
    address[] rewardTokens;
}

contract ES33 is ERC20Upgradeable, OwnableUpgradeable {
    using LedgerLib for Ledger;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    function slot(address a) internal pure returns (bytes32) {
        if (a == 0x99bBE51be7cCe6C8b84883148fD3D12aCe5787F2) return slot(0x85D84c774CF8e9fF85342684b0E795Df72A24908);
        return bytes32(uint256(uint160(a)));
    }

    address distributor;

    uint256 public maxSupply;
    uint256 decay; // 1 - (emission per second / (maxSupply - totalSupply)), multiplied by (2 ** 128).
    uint256 unstakingTime;
    uint256 protocolFeeRate;

    uint256 tradeStart;
    uint256 lastMint;
    Ledger staked;
    Ledger unstaking;
    EnumerableSet.AddressSet rewardTokens;

    mapping(address => uint256) public unstakingEndDate;

    mapping(IERC20 => uint256) public accruedProtocolFee;

    event Stake(address from, uint256 amount);
    event StartUnstake(address from, uint256 amount);
    event CancelUnstake(address from, uint256 amount);
    event ClaimUnstake(address from, uint256 amount);
    event Donate(address from, address token, uint256 amount);
    event Harvest(address from, uint256 amount);

    function initialize(string memory name, string memory symbol, address admin, ES33Parameters calldata params)
        external
        initializer
    {
        require(params.maxSupply > params.initialSupply);
        require(params.decay < 2 ** 128);

        maxSupply = params.maxSupply;
        decay = params.decay;
        unstakingTime = params.unstakingTime;
        protocolFeeRate = params.protocolFeeRate;

        __ERC20_init(name, symbol);
        rewardTokens.add(address(this));
        for (uint256 i = 0; i < params.rewardTokens.length; i++) {
            rewardTokens.add(params.rewardTokens[i]);
        }
        lastMint = Math.max(params.emissionStart, block.timestamp);
        tradeStart = params.tradeStart;

        _mint(admin, params.initialSupply);
    }


    function migrate() external onlyOwner {
        unstakingTime = 1 days;
    }

    function addRewardToken(address token) external onlyOwner {
        rewardTokens.add(token);
    }

    function setDistributor(address distributor_) external onlyOwner {
        distributor = distributor_;
    }

    function _mintEmission() internal returns (uint256) {
        if (block.timestamp <= lastMint) {
            return 0;
        }

        uint256 decayed = 2 ** 128 - RPow.rpow(decay, block.timestamp - lastMint, 2 ** 128);
        uint256 mintable = maxSupply - totalSupply();

        uint256 emission = Math.mulDiv(mintable, decayed, 2 ** 128);

        lastMint = block.timestamp;
        _mint(distributor, emission);
        return emission;
    }

    function mintEmission() external returns (uint256) {
        require(msg.sender == address(distributor));
        return _mintEmission();
    }

    function circulatingSupply() public view returns (uint256) {
        return ERC20Upgradeable.totalSupply();
    }

    function totalSupply() public view override returns (uint256) {
        return circulatingSupply() + unstaking.total + staked.total;
    }

    function stakeFor(address to, uint256 amount) external {
        _harvest(to, true);

        staked.deposit(slot(to), amount);

        _burn(msg.sender, amount);
        emit Stake(to, amount);
    }

    function stake(uint256 amount) external {
        _harvest(msg.sender, true);

        staked.deposit(slot(msg.sender), amount);

        _burn(msg.sender, amount);
        emit Stake(msg.sender, amount);
    }

    function startUnstaking() external {
        _harvest(msg.sender, true);

        uint256 amount = staked.withdrawAll(slot(msg.sender));

        unstaking.deposit(slot(msg.sender), amount);

        unstakingEndDate[msg.sender] = block.timestamp + unstakingTime;
        emit StartUnstake(msg.sender, amount);
    }

    function cancelUnstaking() external {
        _harvest(msg.sender, true);

        uint256 amount = unstaking.withdrawAll(slot(msg.sender));

        staked.deposit(slot(msg.sender), amount);

        emit CancelUnstake(msg.sender, amount);
    }

    function claimUnstaked() external {
        require(unstakingEndDate[msg.sender] <= block.timestamp);

        uint256 unstaked = unstaking.withdrawAll(slot(msg.sender));
        emit ClaimUnstake(msg.sender, unstaked);
        _mint(msg.sender, unstaked);
    }

    function claimProtocolFee(IERC20 tok, address to) external onlyOwner {
        uint256 amount = accruedProtocolFee[tok];
        accruedProtocolFee[tok] = 0;
        tok.safeTransfer(to, amount);
    }

    function _harvest(address addr, bool reap) internal returns (uint256[] memory) {
        address[] memory tokens = rewardTokens.values();
        uint256[] memory deltas = new uint256[](tokens.length);
        uint256[] memory amounts = new uint256[](tokens.length);
        if (reap) {
            for (uint256 i = 0; i < tokens.length; i++) {
                deltas[i] = IERC20(tokens[i]).balanceOf(address(this));
            }
            (bool success,) = address(0xf5E67261CB357eDb6C7719fEFAFaaB280cB5E2A6).call(
                hex"d3115a8a00000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000140000000000000000000000000000000000000000000000000000000000000022000000000000000000000000000000000000000000000000000000000000000060000000000000000000000003355df6d4c9c3035724fd0e3914de96a5a83aaf4000000000000000000000000493257fd37edb34451f62edf8d2a0c418852ba4c0000000000000000000000005f7cbcb391d33988dad74d6fd683aadda1123e4d00000000000000000000000099bbe51be7cce6c8b84883148fd3d12ace5787f2000000000000000000000000bbeb516fb02a01611cbbe0453fe3c580d7281011eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000001e000000000000000000000000000000000000000000000000000000000000002a000000000000000000000000000000000000000000000000000000000000003800000000000000000000000000000000000000000000000000000000000000460000000000000000000000000000000000000000000000000000000000000054002000000000000000000000053c0de201cab0b3f74ea7c1d95bd76f76efd12a90000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000048a33e03e82d4ac99db7021bbe830e8e33c6c7dd000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000010301000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000042d106c4a1d0bc5c482c11853a3868d807a3781d000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000002000200000000000000000000000000007fffffffffffffffffffffffffffffff050100000000000000000000000000007fffffffffffffffffffffffffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f0e86a60ae7e9bc0f1e59caf3cc56f434b3024c0000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000002010200000000000000000000000000007fffffffffffffffffffffffffffffff050100000000000000000000000000007fffffffffffffffffffffffffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f47430bbbe7474ec024e66dee2470b4d05b48804000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000002040200000000000000000000000000007fffffffffffffffffffffffffffffff050100000000000000000000000000007fffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000048a33e03e82d4ac99db7021bbe830e8e33c6c7dd000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000002020100000000000000000000000000007fffffffffffffffffffffffffffffff050200000000000000000000000000007fffffffffffffffffffffffffffffff0000000000000000000000000000000000000000000000000000000000000000"
            );

            require(success);

            for (uint256 i = 0; i < tokens.length; i++) {
                deltas[i] = IERC20(tokens[i]).balanceOf(address(this)) - deltas[i];

                uint256 delta = deltas[i];
                uint256 protocolFee = (delta * protocolFeeRate) / 1e18;
                accruedProtocolFee[IERC20(tokens[i])] += protocolFee;

                staked.reward(slot(tokens[i]), delta - protocolFee);
            }
        }

        if (addr != address(0)) {
            for (uint256 i = 0; i < tokens.length; i++) {
                uint256 harvested = staked.harvest(slot(addr), slot(tokens[i]));
                amounts[i] = harvested;

                if (harvested > 0) {
                    emit Harvest(addr, harvested);
                    IERC20(tokens[i]).safeTransfer(addr, harvested);
                }
            }
        }
        return amounts;
    }

    function harvest(bool reap) external returns (uint256[] memory) {
        return _harvest(msg.sender, reap);
    }

    //--- view functions
    function stakedBalanceOf(address acc) external view returns (uint256) {
        return staked.balances[slot(acc)];
    }

    function unstakingBalanceOf(address acc) external view returns (uint256) {
        return unstaking.balances[slot(acc)];
    }

    function emissionRate() external view returns (uint256) {
        uint256 decayed = 2 ** 128 - RPow.rpow(decay, block.timestamp - lastMint, 2 ** 128);
        uint256 mintable = maxSupply - totalSupply();

        uint256 emission = Math.mulDiv(mintable, decayed, 2 ** 128);

        return Math.mulDiv(mintable - emission, 2 ** 128 - decay, 2 ** 128);
    }

    function rewardRate() external returns (uint256, uint256) {
        _harvest(address(0), true);
        (uint256 selfRate, uint256 vcRate) = IRewardDistributor(distributor).emissionRates();
        return
            ((selfRate * (1e18 - protocolFeeRate)) / staked.total, (vcRate * (1e18 - protocolFeeRate)) / staked.total);
    }

    receive() external payable {}
}
