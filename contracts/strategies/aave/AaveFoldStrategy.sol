// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../base/interface/universalLiquidator/IUniversalLiquidator.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../../base/interface/aave/IAToken.sol";
import "../../base/interface/aave/IVariableDebtToken.sol";
import "../../base/interface/aave/IPool.sol";
import "../../base/interface/aave/IAaveIncentivesController.sol";
import "../../base/interface/aave/DataTypes.sol";
import "../../base/interface/aave/ReserveConfiguration.sol";
import "../../base/interface/IRewardPrePay.sol";

contract AaveFoldStrategy is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  address public constant harvestMSIG = address(0x6a74649aCFD7822ae8Fb78463a9f2192752E5Aa2);
  address public constant _rewardPrePay = address(0xbB17B5689DcC01A42d976255C20BD86fEe7f96Cf);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _ATOKEN_SLOT = 0x8cdee58637b787efaa2d78bb1da1e053a2c91e61640b32339bfbba65c00abd68;
  bytes32 internal constant _DEBT_TOKEN_SLOT = 0x29e482e0e21cdcc43d1f0a48ba975f14078bf56d1ca40ed3f48e655ac06df8cb;
  bytes32 internal constant _STORED_SUPPLIED_SLOT = 0x280539da846b4989609abdccfea039bd1453e4f710c670b29b9eeaca0730c1a2;
  bytes32 internal constant _PENDING_FEE_SLOT = 0x0af7af9f5ccfa82c3497f40c7c382677637aee27293a6243a22216b51481bd97;
  bytes32 internal constant _COLLATERALFACTORNUMERATOR_SLOT = 0x129eccdfbcf3761d8e2f66393221fa8277b7623ad13ed7693a0025435931c64a;
  bytes32 internal constant _FACTORDENOMINATOR_SLOT = 0x4e92df66cc717205e8df80bec55fc1429f703d590a2d456b97b74f0008b4a3ee;
  bytes32 internal constant _BORROWTARGETFACTORNUMERATOR_SLOT = 0xa65533f4b41f3786d877c8fdd4ae6d27ada84e1d9c62ea3aca309e9aa03af1cd;
  bytes32 internal constant _FOLD_SLOT = 0x1841be4c16015a744c9fbf595f7c6b32d40278c16c1fc7cf2de88c6348de44ba;

  // this would be reset on each upgrade
  address[] public rewardTokens;
  mapping(address => bool) public isAToken;

  constructor() BaseUpgradeableStrategy() {
    assert(_ATOKEN_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.aToken")) - 1));
    assert(_DEBT_TOKEN_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.debtToken")) - 1));
    assert(_STORED_SUPPLIED_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.storedSupplied")) - 1));
    assert(_PENDING_FEE_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.pendingFee")) - 1));
    assert(_COLLATERALFACTORNUMERATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.collateralFactorNumerator")) - 1));
    assert(_FACTORDENOMINATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.factorDenominator")) - 1));
    assert(_BORROWTARGETFACTORNUMERATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.borrowTargetFactorNumerator")) - 1));
    assert(_FOLD_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.fold")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _aToken,
    address _debtToken,
    address _rewardToken,
    uint256 _borrowTargetFactorNumerator,
    uint256 _collateralFactorNumerator,
    uint256 _factorDenominator,
    bool _fold
  )
  public initializer {
    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _aToken,
      _rewardToken,
      harvestMSIG,
      _rewardPrePay
    );

    require(IAToken(_aToken).UNDERLYING_ASSET_ADDRESS() == _underlying, "Underlying mismatch");
    require(IVariableDebtToken(_debtToken).UNDERLYING_ASSET_ADDRESS() == _underlying, "Underlying mismatch");
    _setAToken(_aToken);
    _setDebtToken(_debtToken);

    require(_collateralFactorNumerator < _factorDenominator, "Numerator should be smaller than denominator");
    require(_borrowTargetFactorNumerator < _collateralFactorNumerator, "Target should be lower than limit");
    _setFactorDenominator(_factorDenominator);
    setUint256(_COLLATERALFACTORNUMERATOR_SLOT, _collateralFactorNumerator);
    setUint256(_BORROWTARGETFACTORNUMERATOR_SLOT, _borrowTargetFactorNumerator);
    setBoolean(_FOLD_SLOT, _fold);
  }

  function currentBalance() public view returns (uint256) {
    return IAToken(aToken()).balanceOf(address(this)).sub(IVariableDebtToken(debtToken()).balanceOf(address(this)));
  }

  function storedBalance() public view returns (uint256) {
    return getUint256(_STORED_SUPPLIED_SLOT);
  }

  function _updateStoredBalance() internal {
    uint256 balance = currentBalance();
    setUint256(_STORED_SUPPLIED_SLOT, balance);
  }

  function totalFeeNumerator() public view returns (uint256) {
    return strategistFeeNumerator().add(platformFeeNumerator()).add(profitSharingNumerator());
  }

  function pendingFee() public view returns (uint256) {
    return getUint256(_PENDING_FEE_SLOT);
  }

  function _accrueFee() internal {
    uint256 fee;
    if (currentBalance() > storedBalance()) {
      uint256 balanceIncrease = currentBalance().sub(storedBalance());
      fee = balanceIncrease.mul(totalFeeNumerator()).div(feeDenominator());
    }
    setUint256(_PENDING_FEE_SLOT, pendingFee().add(fee));
    _updateStoredBalance();
  }

  function _handleFee() internal {
    _accrueFee();
    uint256 fee = pendingFee();
    if (fee > 100) {
      _redeem(fee);
      address _underlying = underlying();
      fee = Math.min(fee, IERC20(_underlying).balanceOf(address(this)));
      uint256 balanceIncrease = fee.mul(feeDenominator()).div(totalFeeNumerator());
      _notifyProfitInRewardToken(_underlying, balanceIncrease);
      setUint256(_PENDING_FEE_SLOT, pendingFee().sub(fee));
    }
  }
  
  function depositArbCheck() public pure returns (bool) {
    // there's no arb here.
    return true;
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == underlying() || token == aToken());
  }

  function _investAllUnderlying() internal onlyNotPausedInvesting {
    address _underlying = underlying();
    uint256 underlyingBalance = IERC20(_underlying).balanceOf(address(this));
    if (underlyingBalance > 0) {
      _supply(underlyingBalance);
    }
    if (fold()) {
      _depositNoFlash();
    }
  }

  function withdrawAllToVault() public restricted {
    address _underlying = underlying();
    _withdrawMaximum(true);
    uint256 balance = IERC20(_underlying).balanceOf(address(this));
    if (balance > 0) {
      IERC20(_underlying).safeTransfer(vault(), balance);
    }
    _updateStoredBalance();
  }

  function emergencyExit() external onlyGovernance {
    _withdrawMaximum(false);
    _setPausedInvesting(true);
    _updateStoredBalance();
  }

  function _withdrawMaximum(bool claim) internal {
    if (claim) {
      _handleFee();
      uint256 aTokenAmount = _claimReward();
      uint256 prePayAmount;
      if (IRewardPrePay(rewardPrePay()).claimable(address(this)) > 0) {
        prePayAmount = _claimPrePay();
      }
      _liquidateReward(aTokenAmount, prePayAmount);
    } else {
      _accrueFee();
    }
    _redeemMaximum();
  }

  function continueInvesting() public onlyGovernance {
    _setPausedInvesting(false);
  }

  function withdrawToVault(uint256 amountUnderlying) public restricted {
    _accrueFee();
    address _underlying = underlying();
    uint256 balance = IERC20(_underlying).balanceOf(address(this));
    if (amountUnderlying <= balance) {
      IERC20(_underlying).safeTransfer(vault(), amountUnderlying);
      return;
    }
    uint256 toRedeem = amountUnderlying.sub(balance);
    // get some of the underlying
    _redeemPartial(toRedeem);
    // transfer the amount requested (or the amount we have) back to vault()
    IERC20(_underlying).safeTransfer(vault(), amountUnderlying);
    balance = IERC20(_underlying).balanceOf(address(this));
    if (balance > 0) {
      _investAllUnderlying();
    }
    _updateStoredBalance();
  }

  function _redeemPartial(uint256 amountUnderlying) internal {
    address _underlying = underlying();
    uint256 balanceBefore = IERC20(_underlying).balanceOf(address(this));
    _redeemNoFlash(
      amountUnderlying,
      fold()? borrowTargetFactorNumerator():0
    );
    uint256 balanceAfter = IERC20(_underlying).balanceOf(address(this));
    require(balanceAfter.sub(balanceBefore) >= amountUnderlying, "Unable to withdraw the entire amountUnderlying");
  }

  function doHardWork() public restricted {
    _handleFee();
    uint256 aTokenAmount = _claimReward();
    uint256 prePayAmount;
    if (IRewardPrePay(rewardPrePay()).claimable(address(this)) > 0) {
      prePayAmount = _claimPrePay();
    }
    _liquidateReward(aTokenAmount, prePayAmount);
    _investAllUnderlying();
    _updateStoredBalance();
  }

  /**
  * Salvages a token.
  */
  function salvage(address recipient, address token, uint256 amount) public onlyGovernance {
    // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  function _claimReward() internal returns (uint256 aTokenAmount){
    address _aToken = aToken();
    address incentivesController = IAToken(_aToken).getIncentivesController();
    address[] memory assets = new address[](2);
    assets[0] = _aToken;
    assets[1] = debtToken();
    uint256 balanceBefore = IERC20(_aToken).balanceOf(address(this));
    IAaveIncentivesController(incentivesController).claimAllRewards(assets, address(this));
    aTokenAmount = IERC20(_aToken).balanceOf(address(this)).sub(balanceBefore);
  }

  function _liquidateReward(uint256 aTokenAmount, uint256 prePayAmount) internal {
    if (!sell()) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(sell(), false);
      return;
    }
    address _rewardToken = rewardToken();
    address _universalLiquidator = universalLiquidator();
    address _underlying = underlying();
    for(uint256 i = 0; i < rewardTokens.length; i++){
      address token = rewardTokens[i];
      uint256 balance;
      if (token == aToken()) {
        balance = aTokenAmount;
        _redeem(balance);
        token = underlying();
      } else if (token == IRewardPrePay(rewardPrePay()).ZK()) {
        balance = prePayAmount;
      } else {
        if (isAToken[token]) {
          balance = IERC20(token).balanceOf(address(this));
          if (balance > 0) {
            address _pool = IAToken(token).POOL();
            token = IAToken(token).UNDERLYING_ASSET_ADDRESS();
            IPool(_pool).withdraw(token, balance, address(this));
          }
        } else {
          balance = IERC20(token).balanceOf(address(this));
        }
      }

      if (balance > 0 && token != _rewardToken){
        IERC20(token).safeApprove(_universalLiquidator, 0);
        IERC20(token).safeApprove(_universalLiquidator, balance);
        IUniversalLiquidator(_universalLiquidator).swap(token, _rewardToken, balance, 1, address(this));
      }
    }

    uint256 rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
    _notifyProfitInRewardToken(_rewardToken, rewardBalance);
    uint256 remainingRewardBalance = IERC20(_rewardToken).balanceOf(address(this));

    if (remainingRewardBalance == 0) {
      return;
    }

    if (_underlying != _rewardToken) {
      IERC20(_rewardToken).safeApprove(_universalLiquidator, 0);
      IERC20(_rewardToken).safeApprove(_universalLiquidator, remainingRewardBalance);
      IUniversalLiquidator(_universalLiquidator).swap(_rewardToken, _underlying, remainingRewardBalance, 1, address(this));
    }
  }

  /**
  * Returns the current balance.
  */
  function investedUnderlyingBalance() public view returns (uint256) {
    uint256 balance = IERC20(underlying()).balanceOf(address(this));
    return balance.add(storedBalance()).sub(pendingFee());
  }

  function _supply(uint256 amountUnderlying) internal {
    if (amountUnderlying == 0){
      return;
    }
    address _underlying = underlying();
    address _pool = IAToken(aToken()).POOL();
    DataTypes.ReserveConfigurationMap memory configuration = IPool(_pool).getConfiguration(_underlying);
    uint256 supplyCap = configuration.getSupplyCap();
    if (supplyCap == 0) {
      supplyCap = type(uint256).max;
    } else {
      supplyCap = supplyCap.mul(10 ** configuration.getDecimals());
    }
    uint256 totalSupply = IERC20(aToken()).totalSupply();
    if (totalSupply >= supplyCap) {
      return;
    } else if (supplyCap.sub(totalSupply) <= amountUnderlying) {
      amountUnderlying = supplyCap.sub(totalSupply).sub(2);
    }
    IERC20(_underlying).safeApprove(_pool, 0);
    IERC20(_underlying).safeApprove(_pool, amountUnderlying);
    IPool(_pool).supply(_underlying, amountUnderlying, address(this), 0);
  }

  function _borrow(uint256 amountUnderlying) internal {
    if (amountUnderlying == 0){
      return;
    }
    address _pool = IAToken(aToken()).POOL();
    IPool(_pool).borrow(underlying(), amountUnderlying, 2, 0, address(this));
  }

  function _redeem(uint256 amountUnderlying) internal {
    if (amountUnderlying == 0){
      return;
    }
    address _pool = IAToken(aToken()).POOL();
    IPool(_pool).withdraw(underlying(), amountUnderlying, address(this));
  }

  function _repay(uint256 amountUnderlying) internal {
    if (amountUnderlying == 0){
      return;
    }
    address _underlying = underlying();
    address _pool = IAToken(aToken()).POOL();
    IERC20(_underlying).safeApprove(_pool, 0);
    IERC20(_underlying).safeApprove(_pool, amountUnderlying);
    IPool(_pool).repay(_underlying, amountUnderlying, 2, address(this));
  }

  function _redeemMaximum() internal {
    address _aToken = aToken();
    // amount we supplied
    uint256 supplied = IAToken(_aToken).balanceOf(address(this));
    // amount we borrowed
    uint256 borrowed = IVariableDebtToken(debtToken()).balanceOf(address(this));
    uint256 balance = supplied.sub(borrowed).sub(pendingFee());

    _redeemNoFlash(balance, 0);
    supplied = IAToken(_aToken).balanceOf(address(this));
    if (supplied > pendingFee()) {
      _redeem(supplied.sub(pendingFee()));
    }
  }

  function _depositNoFlash() internal {
    address _underlying = underlying();
    uint256 _denom = factorDenominator();
    uint256 _borrowNum = borrowTargetFactorNumerator();
    // amount we supplied
    uint256 supplied = IAToken(aToken()).balanceOf(address(this));
    // amount we borrowed
    uint256 borrowed = IVariableDebtToken(debtToken()).balanceOf(address(this));
    uint256 balance = supplied.sub(borrowed);
    uint256 borrowTarget = balance.mul(_borrowNum).div(_denom.sub(_borrowNum));

    if (borrowed > borrowTarget) {
      _redeemPartial(0);
      borrowTarget = borrowed;
    } else {
      address _pool = IAToken(aToken()).POOL();
      DataTypes.ReserveConfigurationMap memory configuration = IPool(_pool).getConfiguration(_underlying);
      (uint256 borrowCap, uint256 supplyCap) = configuration.getCaps();
      if (borrowCap == 0) {
        borrowCap = type(uint256).max;
      } else {
        borrowCap = borrowCap.mul(10 ** configuration.getDecimals());
      }
      if (supplyCap == 0) {
        supplyCap = type(uint256).max;
      } else {
        supplyCap = supplyCap.mul(10 ** configuration.getDecimals());
      }
      uint256 totalBorrow = IERC20(debtToken()).totalSupply();
      uint256 totalSupply = IERC20(aToken()).totalSupply();
      uint256 borrowAvail;
      if (totalBorrow < borrowCap) {
        borrowAvail = borrowCap.sub(totalBorrow).sub(2);
        if (totalSupply < supplyCap) {
          borrowAvail = Math.min(supplyCap.sub(totalSupply).sub(2), borrowAvail);
        } else {
          borrowAvail = 0;
        }
      } else {
        borrowAvail = 0;
      }
      borrowTarget = Math.min(borrowTarget, borrowed.add(borrowAvail));
    }

    while (borrowed < borrowTarget) {
      uint256 wantBorrow = borrowTarget.sub(borrowed);
      uint256 maxBorrow = supplied.mul(collateralFactorNumerator()).div(_denom).sub(borrowed);
      _borrow(Math.min(wantBorrow, maxBorrow));
      uint256 underlyingBalance = IERC20(_underlying).balanceOf(address(this));
      if (underlyingBalance > 0) {
        _supply(underlyingBalance);
      }
      //update parameters
      borrowed = IVariableDebtToken(debtToken()).balanceOf(address(this));
      supplied = IAToken(aToken()).balanceOf(address(this));
    }
  }

  function _redeemNoFlash(uint256 amount, uint256 _borrowNum) internal {
    address _underlying = underlying();
    uint256 _denom = factorDenominator();
    // amount we supplied
    uint256 supplied = IAToken(aToken()).balanceOf(address(this));
    // amount we borrowed
    uint256 borrowed = IVariableDebtToken(debtToken()).balanceOf(address(this));
    uint256 newBorrowTarget;
    {
        uint256 oldBalance = supplied.sub(borrowed);
        uint256 newBalance = oldBalance.sub(amount);
        newBorrowTarget = newBalance.mul(_borrowNum).div(_denom.sub(_borrowNum));
    }
    while (borrowed > newBorrowTarget) {
      uint256 requiredCollateral = borrowed.mul(_denom).div(collateralFactorNumerator());
      uint256 toRepay = borrowed.sub(newBorrowTarget);
      // redeem just as much as needed to repay the loan
      // supplied - requiredCollateral = max redeemable, amount + repay = needed
      uint256 toRedeem = Math.min(supplied.sub(requiredCollateral), amount.add(toRepay));
      _redeem(toRedeem);
      // now we can repay our borrowed amount
      uint256 balance = IERC20(_underlying).balanceOf(address(this));
      _repay(Math.min(toRepay, balance));
      // update the parameters
      borrowed = IVariableDebtToken(debtToken()).balanceOf(address(this));
      supplied = IAToken(aToken()).balanceOf(address(this));
    }
    uint256 underlyingBalance = IERC20(_underlying).balanceOf(address(this));
    if (underlyingBalance < amount) {
      uint256 toRedeem = amount.sub(underlyingBalance);
      uint256 balance = supplied.sub(borrowed);
      // redeem the most we can redeem
      _redeem(Math.min(toRedeem, balance));
    }
  }

  // updating collateral factor
  // note 1: one should settle the loan first before calling this
  // note 2: collateralFactorDenominator is 1000, therefore, for 20%, you need 200
  function _setCollateralFactorNumerator(uint256 _numerator) public onlyGovernance {
    require(_numerator <= factorDenominator(), "Collateral factor cannot be this high");
    require(_numerator > borrowTargetFactorNumerator(), "Collateral factor should be higher than borrow target");
    setUint256(_COLLATERALFACTORNUMERATOR_SLOT, _numerator);
  }

  function collateralFactorNumerator() public view returns (uint256) {
    return getUint256(_COLLATERALFACTORNUMERATOR_SLOT);
  }

  function _setFactorDenominator(uint256 _denominator) internal {
    setUint256(_FACTORDENOMINATOR_SLOT, _denominator);
  }

  function factorDenominator() public view returns (uint256) {
    return getUint256(_FACTORDENOMINATOR_SLOT);
  }

  function setBorrowTargetFactorNumerator(uint256 _numerator) public onlyGovernance {
    require(_numerator < collateralFactorNumerator(), "Target should be lower than collateral limit");
    setUint256(_BORROWTARGETFACTORNUMERATOR_SLOT, _numerator);
  }

  function borrowTargetFactorNumerator() public view returns (uint256) {
    return getUint256(_BORROWTARGETFACTORNUMERATOR_SLOT);
  }

  function setFold (bool _fold) public onlyGovernance {
    setBoolean(_FOLD_SLOT, _fold);
  }

  function fold() public view returns (bool) {
    return getBoolean(_FOLD_SLOT);
  }

  function _setAToken (address _target) internal {
    setAddress(_ATOKEN_SLOT, _target);
  }

  function aToken() public view returns (address) {
    return getAddress(_ATOKEN_SLOT);
  }

  function _setDebtToken (address _target) internal {
    setAddress(_DEBT_TOKEN_SLOT, _target);
  }

  function debtToken() public view returns (address) {
    return getAddress(_DEBT_TOKEN_SLOT);
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }

  receive() external payable {}
}