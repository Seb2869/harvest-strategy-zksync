// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./inheritance/Controllable.sol";
import "./interface/IController.sol";
import "./interface/IStrategy.sol";

import "./interface/aave/IPool.sol";
import "./interface/aave/IAToken.sol";
import "./interface/aave/ILendingPoolAddressesProvider.sol";
import "./interface/aave/IOracle.sol";

contract RewardPrePay is Controllable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    event RewardUpdated(address indexed strategy, uint256 oldValue, uint256 newValue);
    event RewardClaimed(address indexed strategy, uint256 amount);
    event RewardRepayed(address indexed strategy, uint256 amount);
    event StrategyInitialized(address indexed strategy, uint256 earned, uint256 claimed);
    event StrategyForceUpdated(address indexed strategy, uint256 earned, uint256 claimed, bool initialized);

    uint256 public constant MIN_HEALTH_FACTOR = 1.5e18;

    address public constant WETH = address(0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91);
    address public constant aWETH = address(0xb7b93bCf82519bB757Fd18b23A389245Dbd8ca64);
    address public constant ZK = address(0x5A7d6b2F92C77FAD6CCaBd7EE0624E64907Eaf3E);
    address public constant variableDebtZK = address(0x6450fd7F877B5bB726F7Bc6Bf0e6ffAbd48d72ad);

    mapping (address => uint256) public rewardEarned;
    mapping (address => uint256) public rewardClaimed;
    mapping (address => bool) public strategyInitialized;

    modifier onlyHardWorkerOrGovernance() {
        require(IController(controller()).hardWorkers(msg.sender) || (msg.sender == governance()),
            "only hard worker can call this");
        _;
    }

    modifier onlyInitialized(address _strategy) {
        require(strategyInitialized[_strategy], "strategy not initialized");
        _;
    }

    constructor(address _storage) Controllable(_storage) {}

    function getAaveAccountData() public view returns (uint256 totalCollateralBase, uint256 totalDebtBase, uint256 availableBorrowsBase, uint256 currentLiquidationThreshold, uint256 ltv, uint256 healthFactor) {
        address _pool = IAToken(aWETH).POOL();
        return IPool(_pool).getUserAccountData(address(this));
    }

    function _getNewHealthFactor(uint256 removeCollateral, uint256 addDebt) internal view returns (uint256 newHealth) {
        (uint256 collateralUsd, uint256 debtUsd,, uint256 liqFactor,,)  = getAaveAccountData();
        address _pool = IAToken(aWETH).POOL();
        address _addressProvider = IPool(_pool).ADDRESSES_PROVIDER();
        address _oracle = ILendingPoolAddressesProvider(_addressProvider).getPriceOracle();
        uint256 newCollateralUsd;
        if (removeCollateral > 0) {
            uint256 currentCollateral = IERC20(aWETH).balanceOf(address(this));
            uint256 newCollateral = currentCollateral.sub(removeCollateral);
            newCollateralUsd = IOracle(_oracle).getAssetPrice(WETH).mul(newCollateral).div(1e18);
        } else {
            newCollateralUsd = collateralUsd;
        }
        uint256 newDebtUsd;
        if (addDebt > 0) {
            uint256 currentDebt = IERC20(variableDebtZK).balanceOf(address(this));
            uint256 newDebt = currentDebt.add(addDebt);
            newDebtUsd = IOracle(_oracle).getAssetPrice(ZK).mul(newDebt).div(1e18);
        } else {
            newDebtUsd = debtUsd;
        }
        uint256 newLtv = newDebtUsd.mul(1e4).div(newCollateralUsd);
        if (newLtv > 0) {
            newHealth = liqFactor.mul(1e18).div(newLtv);
        } else {
            newHealth = type(uint256).max;
        }
    }

    function increaseCollateral(uint256 _amount) external onlyGovernance {
        IERC20(WETH).safeTransferFrom(msg.sender, address(this), _amount);
        address _pool = IAToken(aWETH).POOL();
        IERC20(WETH).safeApprove(_pool, 0);
        IERC20(WETH).safeApprove(_pool, _amount);
        IPool(_pool).supply(WETH, _amount, address(this), 0);
    }

    function withdrawCollateral(uint256 _amount) external onlyGovernance {
        uint256 newHealth = _getNewHealthFactor(_amount, 0);
        require(newHealth >= MIN_HEALTH_FACTOR, "health factor too low");
        
        address _pool = IAToken(aWETH).POOL();
        IPool(_pool).withdraw(WETH, _amount, address(this));
    }

    function withdrawAll() external onlyGovernance {
        (,uint256 totalDebtBase,,,,) = getAaveAccountData();
        require(totalDebtBase == 0, "debt must be 0");
        address _pool = IAToken(aWETH).POOL();
        IPool(_pool).withdraw(WETH, IERC20(aWETH).balanceOf(address(this)), address(this));
    }

    function _borrow(uint256 _amount) internal {
        uint256 newHealth = _getNewHealthFactor(0, _amount);
        require(newHealth >= MIN_HEALTH_FACTOR, "health factor too low");

        address _pool = IAToken(variableDebtZK).POOL();
        IPool(_pool).borrow(ZK, _amount, 2, 0, address(this));
    }

    function _repay(uint256 _amount) internal {
        address _pool = IAToken(variableDebtZK).POOL();
        IERC20(ZK).safeApprove(_pool, 0);
        IERC20(ZK).safeApprove(_pool, _amount);
        IPool(_pool).repay(ZK, _amount, 2, address(this));
    }

    function repayDebt() public {
        uint256 balance = IERC20(ZK).balanceOf(address(this));
        uint256 debt = IERC20(variableDebtZK).balanceOf(address(this));
        uint256 maxRepay = Math.min(balance, debt);
        if (maxRepay > 0) {
            _repay(maxRepay);
        }
    }

    function updateReward(address _strategy, uint256 _newAmount) public onlyHardWorkerOrGovernance onlyInitialized(_strategy) {
        require(_newAmount > rewardEarned[_strategy], "new amount must be greater than current amount");
        uint256 oldAmount = rewardEarned[_strategy];
        rewardEarned[_strategy] = _newAmount;
        emit RewardUpdated(_strategy, oldAmount, _newAmount);
    }

    function batchUpdateReward(address[] calldata _strategies, uint256[] calldata _newAmounts) external onlyHardWorkerOrGovernance {
        require(_strategies.length == _newAmounts.length, "array length mismatch");
        for (uint256 i = 0; i < _strategies.length; i++) {
            updateReward(_strategies[i], _newAmounts[i]);
        }
    }

    function claimable(address _strategy) public view returns (uint256) {
        return rewardEarned[_strategy].sub(rewardClaimed[_strategy]);
    }

    function _claim(address _strategy) internal onlyInitialized(_strategy) nonReentrant {
        uint256 claimableAmount = claimable(_strategy);
        uint256 payableAmount = claimableAmount.mul(100).div(101);
        if (payableAmount > 0) {
            uint256 balance = IERC20(ZK).balanceOf(address(this));
            if (payableAmount > balance) {
                uint256 toBorrow = payableAmount.sub(balance);
                _borrow(toBorrow);
            }
            rewardClaimed[_strategy] = rewardClaimed[_strategy].add(claimableAmount);
            IERC20(ZK).safeTransfer(_strategy, payableAmount);
        }
        emit RewardClaimed(_strategy, claimableAmount);
    }

    function claim() external {
        _claim(msg.sender);
    }

    function claimFor(address _strategy) external onlyGovernance {
        _claim(_strategy);
    }

    function initializeStrategy(address _strategy, uint256 _earned, uint256 _claimed) external onlyGovernance {
        require(!strategyInitialized[_strategy], "strategy already initialized");
        rewardEarned[_strategy] = _earned;
        rewardClaimed[_strategy] = _claimed;
        strategyInitialized[_strategy] = true;
        emit StrategyInitialized(_strategy, _earned, _claimed);
    }

    function forceUpdateValues(address _strategy, uint256 _earned, uint256 _claimed, bool _initialized) external onlyGovernance {
        rewardEarned[_strategy] = _earned;
        rewardClaimed[_strategy] = _claimed;
        strategyInitialized[_strategy] = _initialized;
        emit StrategyForceUpdated(_strategy, _earned, _claimed, _initialized);
    }

    function salvage(address _token, uint256 _amount) external onlyGovernance {
        IERC20(_token).safeTransfer(governance(), _amount);
    }

    function merklClaim(
        address strategy,
        uint256 newAmount,
        address merklDistr,
        address[] calldata users,
        address[] calldata tokens,
        uint256[] calldata amounts,
        bytes32[][] calldata proofs
    ) public onlyHardWorkerOrGovernance nonReentrant {
        updateReward(strategy, newAmount);
        _claim(strategy);
        uint256 balanceBefore = IERC20(ZK).balanceOf(address(this));
        IStrategy(strategy).merklClaim(merklDistr, users, tokens, amounts, proofs);
        uint256 received = IERC20(ZK).balanceOf(address(this)).sub(balanceBefore);
        rewardClaimed[strategy] = rewardClaimed[strategy].sub(received);
        rewardEarned[strategy] = rewardEarned[strategy].sub(received);
        emit RewardRepayed(strategy, received);
        repayDebt();
    }

    function batchMerklClaim(
        address[] calldata strategies,
        uint256[] calldata newAmounts,
        address[] calldata merklDistrs,
        address[][] calldata users,
        address[][] calldata tokens,
        uint256[][] calldata amounts,
        bytes32[][][] calldata proofs
    ) external onlyHardWorkerOrGovernance {
        require(
            strategies.length == newAmounts.length &&
            strategies.length == merklDistrs.length &&
            strategies.length == users.length &&
            strategies.length == tokens.length &&
            strategies.length == amounts.length &&
            strategies.length == proofs.length,
            "array length mismatch"
        );
        for (uint256 i = 0; i < strategies.length; i++) {
            merklClaim(strategies[i], newAmounts[i], merklDistrs[i], users[i], tokens[i], amounts[i], proofs[i]);
        }
    }
}
