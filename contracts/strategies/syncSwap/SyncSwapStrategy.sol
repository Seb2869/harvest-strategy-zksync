//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../base/interface/universalLiquidator/IUniversalLiquidator.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../../base/interface/syncswap/IRouter.sol";
import "../../base/interface/syncswap/IStakingPool.sol";

contract SyncSwapStrategy is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant harvestMSIG = address(0x6a74649aCFD7822ae8Fb78463a9f2192752E5Aa2);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _DEPOSIT_TOKEN_SLOT = 0x219270253dbc530471c88a9e7c321b36afda219583431e7b6c386d2d46e70c86;
  bytes32 internal constant _ROUTER_SLOT = 0xc4bc41765b1e3f3fee6c9fdf0e8be35cc927fe7657e9189710451b83e4bf5b3e;
  bytes32 internal constant _USE_VAULT_SLOT = 0x4d5f82bc63870087e266f31bd63152445b69568bc578159eba0d0c339a764c3a;
  bytes32 internal constant _STAKE = 0x175ebcf75a7460f502cd8d8fc681df48f74de0f69d9368c454d23e8d7f9458f6;

  // this would be reset on each upgrade
  address[] public rewardTokens;

  uint256 public zkBalanceStart;
  uint256 public zkBalanceLast;
  uint256 public lastRewardTime;
  uint256 public zkPerSec;
  address public constant zk = address(0x5A7d6b2F92C77FAD6CCaBd7EE0624E64907Eaf3E);

  constructor() BaseUpgradeableStrategy() {
    assert(_DEPOSIT_TOKEN_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.depositToken")) - 1));
    assert(_ROUTER_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.router")) - 1));
    assert(_USE_VAULT_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.useVault")) - 1));
    assert(_STAKE == bytes32(uint256(keccak256("eip1967.strategyStorage.stake")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _stakingPool,
    address _rewardToken,
    address _depositToken,
    address _router,
    bool _useVault
  ) public initializer {
    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _stakingPool,
      _rewardToken,
      harvestMSIG
    );

    if (rewardPool() != address(0)) {
      address _lpt = IStakingPool(rewardPool()).shareToken();
      require(_lpt == _underlying, "Underlying mismatch");
    }

    _setDepositToken(_depositToken);
    _setRouter(_router);
    _setUseVault(_useVault);
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function _rewardPoolBalance() internal view returns (uint256 balance) {
    if (rewardPool() == address(0)) {
      balance = 0;
    } else {
      balance = IStakingPool(rewardPool()).userStaked(address(this));
    }
  }

  function _emergencyExitRewardPool() internal {
    uint256 stakedBalance = _rewardPoolBalance();
    if (stakedBalance > 0) {
      IStakingPool(rewardPool()).withdraw(stakedBalance, address(this));
    }
  }

  function _withdrawUnderlyingFromPool(uint256 amount) internal {
    if (amount > 0) {
      IStakingPool(rewardPool()).withdraw(amount, address(this));
    }
  }

  function _enterRewardPool() internal {
    address underlying_ = underlying();
    address rewardPool_ = rewardPool();
    uint256 entireBalance = IERC20(underlying_).balanceOf(address(this));
    IERC20(underlying_).safeApprove(rewardPool_, 0);
    IERC20(underlying_).safeApprove(rewardPool_, entireBalance);
    IStakingPool(rewardPool_).stake(entireBalance, address(this));
  }

  function _investAllUnderlying() internal onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    if(IERC20(underlying()).balanceOf(address(this)) > 0 && stake()) {
      _enterRewardPool();
    }
  }

  /*
  *   In case there are some issues discovered about the pool or underlying asset
  *   Governance can exit the pool properly
  *   The function is only used for emergency to exit the pool
  */
  function emergencyExit() public onlyGovernance {
    _emergencyExitRewardPool();
    _setPausedInvesting(true);
  }

  /*
  *   Resumes the ability to invest into the underlying reward pools
  */
  function continueInvesting() public onlyGovernance {
    _setPausedInvesting(false);
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying());
  }

  function addRewardToken(address _token) public onlyGovernance {
    rewardTokens.push(_token);
  }

  function _liquidateReward() internal {
    if (!sell()) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(sell(), false);
      return;
    }

    address _rewardToken = rewardToken();
    address _universalLiquidator = universalLiquidator();
    for(uint256 i = 0; i < rewardTokens.length; i++){
      address token = rewardTokens[i];
      uint256 balance = IERC20(token).balanceOf(address(this));
      if (token == zk) {
        if (balance > zkBalanceLast) {
          _updateZkDist(balance);
        }
        balance = _getZkAmt();
      }
      if (balance > 0 && token != _rewardToken){
        IERC20(token).safeApprove(_universalLiquidator, 0);
        IERC20(token).safeApprove(_universalLiquidator, balance);
        IUniversalLiquidator(_universalLiquidator).swap(token, _rewardToken, balance, 1, address(this));
      }
    }

    uint256 rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
    if (rewardBalance < 1e12) {
      return;
    }
    _notifyProfitInRewardToken(_rewardToken, rewardBalance);
    uint256 remainingRewardBalance = IERC20(_rewardToken).balanceOf(address(this));

    if (remainingRewardBalance == 0) {
      return;
    }

    address _depositToken = depositToken();
    uint256 depositTokenAmount;
    if (_rewardToken != _depositToken) {
      IERC20(_rewardToken).safeApprove(_universalLiquidator, 0);
      IERC20(_rewardToken).safeApprove(_universalLiquidator, remainingRewardBalance);

      IUniversalLiquidator(_universalLiquidator).swap(_rewardToken, _depositToken, remainingRewardBalance, 1, address(this));
      depositTokenAmount = IERC20(_depositToken).balanceOf(address(this));
    } else {
      depositTokenAmount = remainingRewardBalance;
    }

    address _router = router();
    IERC20(_depositToken).safeApprove(_router, 0);
    IERC20(_depositToken).safeApprove(_router, depositTokenAmount);

    IRouter.TokenInput memory input = IRouter.TokenInput(_depositToken, depositTokenAmount, useVault());
    IRouter.TokenInput[] memory inputs = new IRouter.TokenInput[](1);
    inputs[0] = input;

    IRouter(_router).addLiquidity2(
      underlying(),
      inputs,
      abi.encode(address(this)),
      1,
      address(0),
      bytes("0"),
      address(0)
    );
  }

  function _updateZkDist(uint256 balance) internal {
    zkBalanceStart = balance;
    zkBalanceLast = balance;
    lastRewardTime = block.timestamp.sub(86400);
    zkPerSec = balance.div(691200);
  }

  function _getZkAmt() internal returns (uint256) {
    uint256 balance = IERC20(zk).balanceOf(address(this));
    uint256 earned = Math.min(block.timestamp.sub(lastRewardTime).mul(zkPerSec), balance);
    zkBalanceLast = balance.sub(earned);
    lastRewardTime = block.timestamp;
    return earned;
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    _withdrawUnderlyingFromPool(_rewardPoolBalance());
    _liquidateReward();
    address underlying_ = underlying();
    IERC20(underlying_).safeTransfer(vault(), IERC20(underlying_).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 _amount) public restricted {
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    address underlying_ = underlying();
    uint256 entireBalance = IERC20(underlying_).balanceOf(address(this));

    if(_amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = _amount.sub(entireBalance);
      uint256 toWithdraw = Math.min(_rewardPoolBalance(), needToWithdraw);
      _withdrawUnderlyingFromPool(toWithdraw);
    }
    IERC20(underlying_).safeTransfer(vault(), _amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    if (rewardPool() == address(0)) {
      return IERC20(underlying()).balanceOf(address(this));
    }
    // Adding the amount locked in the reward pool and the amount that is somehow in this contract
    // both are in the units of "underlying"
    // The second part is needed because there is the emergency exit mechanism
    // which would break the assumption that all the funds are always inside of the reward pool
    return _rewardPoolBalance().add(IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Governance or Controller can claim coins that are somehow transferred into the contract
  *   Note that they cannot come in take away coins that are used and defined in the strategy itself
  */
  function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
     // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /*
  *   Get the reward, sell it in exchange for underlying, invest what you got.
  *   It's not much, but it's honest work.
  *
  *   Note that although `onlyNotPausedInvesting` is not added here,
  *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
  *   when the investing is being paused by governance.
  */
  function doHardWork() external onlyNotPausedInvesting restricted {
    if (rewardPool() != address(0)) {
      IStakingPool(rewardPool()).claimRewards(address(this), uint8(1), bytes("0"));
    }
    _liquidateReward();
    _investAllUnderlying();
  }

  /**
  * Can completely disable claiming UNI rewards and selling. Good for emergency withdraw in the
  * simplest possible way.
  */
  function setSell(bool s) public onlyGovernance {
    _setSell(s);
  }

  function _setDepositToken(address _value) internal {
    setAddress(_DEPOSIT_TOKEN_SLOT, _value);
  }

  function depositToken() public view returns (address) {
    return getAddress(_DEPOSIT_TOKEN_SLOT);
  }
  
  function _setRouter(address _value) internal {
    setAddress(_ROUTER_SLOT, _value);
  }

  function router() public view returns (address) {
    return getAddress(_ROUTER_SLOT);
  }

  function _setUseVault(bool _value) internal {
    setBoolean(_USE_VAULT_SLOT, _value);
  }

  function useVault() public view returns (bool) {
    return getBoolean(_USE_VAULT_SLOT);
  }

  function setStake(bool _value) public onlyGovernance {
    if (_value) {
      require(rewardPool() != address(0), "No rewardpool set");
      _enterRewardPool();
    } else {
      _emergencyExitRewardPool();
    }
    setBoolean(_STAKE, _value);
  }

  function stake() public view returns (bool) {
    return getBoolean(_STAKE);
  }

  function setRewardPool(address pool) external onlyGovernance {
    _setRewardPool(pool);
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }
}
