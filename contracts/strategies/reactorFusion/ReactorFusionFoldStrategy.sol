// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../base/interface/universalLiquidator/IUniversalLiquidator.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../../base/interface/reactorFusion/CTokenInterface.sol";
import "../../base/interface/reactorFusion/IComptroller.sol";
import "../../base/interface/reactorFusion/IRewardDistributor.sol";
import "../../base/interface/weth/IWETH.sol";

contract ReactorFusionFoldStrategy is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant weth = address(0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91);
  address public constant harvestMSIG = address(0x6a74649aCFD7822ae8Fb78463a9f2192752E5Aa2);

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _CTOKEN_SLOT = 0x316ad921d519813e6e41c0e056b79e4395192c2b101f8b61cf5b94999360d568;
  bytes32 internal constant _COMPTROLLER_SLOT = 0x21864471ca9d8b67bc7f58951fb160897ce623fdb405c56534d08a363a47e235;
  bytes32 internal constant _COLLATERALFACTORNUMERATOR_SLOT = 0x129eccdfbcf3761d8e2f66393221fa8277b7623ad13ed7693a0025435931c64a;
  bytes32 internal constant _FACTORDENOMINATOR_SLOT = 0x4e92df66cc717205e8df80bec55fc1429f703d590a2d456b97b74f0008b4a3ee;
  bytes32 internal constant _BORROWTARGETFACTORNUMERATOR_SLOT = 0xa65533f4b41f3786d877c8fdd4ae6d27ada84e1d9c62ea3aca309e9aa03af1cd;
  bytes32 internal constant _FOLD_SLOT = 0x1841be4c16015a744c9fbf595f7c6b32d40278c16c1fc7cf2de88c6348de44ba;

  uint256 public suppliedInUnderlying;
  uint256 public borrowedInUnderlying;

  // this would be reset on each upgrade
  address[] public rewardTokens;

  constructor() BaseUpgradeableStrategy() {
    assert(_CTOKEN_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.cToken")) - 1));
    assert(_COMPTROLLER_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.comptroller")) - 1));
    assert(_COLLATERALFACTORNUMERATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.collateralFactorNumerator")) - 1));
    assert(_FACTORDENOMINATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.factorDenominator")) - 1));
    assert(_BORROWTARGETFACTORNUMERATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.borrowTargetFactorNumerator")) - 1));
    assert(_FOLD_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.fold")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _cToken,
    address _comptroller,
    address _rewardDistributor,
    address _rewardToken,
    uint256 _borrowTargetFactorNumerator,
    uint256 _collateralFactorNumerator,
    bool _fold
  )
  public initializer {
    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      _rewardDistributor,
      _rewardToken,
      harvestMSIG
    );

    if (_underlying != weth) {
      require(CTokenInterface(_cToken).underlying() == _underlying, "Underlying mismatch");
    }

    _setCToken(_cToken);
    _setComptroller(_comptroller);

    require(_collateralFactorNumerator < uint(1000), "Numerator should be smaller than denominator");
    require(_borrowTargetFactorNumerator < _collateralFactorNumerator, "Target should be lower than limit");
    setUint256(_COLLATERALFACTORNUMERATOR_SLOT, _collateralFactorNumerator);
    setUint256(_BORROWTARGETFACTORNUMERATOR_SLOT, _borrowTargetFactorNumerator);
    setBoolean(_FOLD_SLOT, _fold);
    address[] memory markets = new address[](1);
    markets[0] = _cToken;
    IComptroller(_comptroller).enterMarkets(markets);
  }

  modifier updateSupplyInTheEnd() {
    _;
    address _cToken = cToken();
    // amount we supplied
    suppliedInUnderlying = CTokenInterface(_cToken).balanceOfUnderlying(address(this));
    // amount we borrowed
    borrowedInUnderlying = CTokenInterface(_cToken).borrowBalanceCurrent(address(this));
  }

  function depositArbCheck() public pure returns (bool) {
    // there's no arb here.
    return true;
  }

  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == rewardToken() || token == underlying() || token == cToken());
  }

  /**
  * The strategy invests by supplying the underlying as a collateral.
  */
  function _investAllUnderlying() internal onlyNotPausedInvesting updateSupplyInTheEnd {
    address _underlying = underlying();
    uint256 underlyingBalance = IERC20(_underlying).balanceOf(address(this));
    if (underlyingBalance > 0) {
      _supply(underlyingBalance);
    }
    if (!fold()) {
      return;
    }
    _foldDeposit();
  }

  /**
  * Exits Moonwell and transfers everything to the vault.
  */
  function withdrawAllToVault() public restricted updateSupplyInTheEnd {
    address _underlying = underlying();
    _withdrawMaximum(true);
    if (IERC20(_underlying).balanceOf(address(this)) > 0) {
      IERC20(_underlying).safeTransfer(vault(), IERC20(_underlying).balanceOf(address(this)));
    }
  }

  function emergencyExit() external onlyGovernance updateSupplyInTheEnd {
    _withdrawMaximum(false);
  }

  function _withdrawMaximum(bool claim) internal updateSupplyInTheEnd {
    if (claim) {
      _claimRewards();
      _liquidateRewards();
    }
    _redeemMaximum();
  }

  function withdrawToVault(uint256 amountUnderlying) public restricted updateSupplyInTheEnd {
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
  }

  /**
  * Withdraws all assets, liquidates XVS, and invests again in the required ratio.
  */
  function doHardWork() public restricted {
    _claimRewards();
    _liquidateRewards();
    _investAllUnderlying();
  }

  /**
  * Redeems `amountUnderlying` or fails.
  */
  function _redeemPartial(uint256 amountUnderlying) internal {
    address _underlying = underlying();
    uint256 balanceBefore = IERC20(_underlying).balanceOf(address(this));
    _foldRedeem(
      amountUnderlying,
      fold()? borrowTargetFactorNumerator():0
    );
    uint256 balanceAfter = IERC20(_underlying).balanceOf(address(this));
    require(balanceAfter.sub(balanceBefore) >= amountUnderlying, "Unable to withdraw the entire amountUnderlying");
  }

  /**
  * Salvages a token.
  */
  function salvage(address recipient, address token, uint256 amount) public onlyGovernance {
    // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  function _claimRewards() internal {
    address _rewardPool = rewardPool();
    address _cToken = cToken();
    bytes32 borrowSlot = IRewardDistributor(_rewardPool).borrowSlot(_cToken);
    bytes32 supplySlot = IRewardDistributor(_rewardPool).supplySlot(_cToken);
    bytes32[] memory ids = new bytes32[](2);
    ids[0] = borrowSlot;
    ids[1] = supplySlot;
    IRewardDistributor(_rewardPool).harvest(ids);
  }

  function addRewardToken(address _token) public onlyGovernance {
    rewardTokens.push(_token);
  }

  function _liquidateRewards() internal {
    if (!sell()) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(sell(), false);
      return;
    }
    address _rewardToken = rewardToken();
    address _universalLiquidator = universalLiquidator();
    for (uint256 i; i < rewardTokens.length; i++) {
      address token = rewardTokens[i];
      uint256 balance = IERC20(token).balanceOf(address(this));
      if (balance == 0) {
          continue;
      }
      if (token != _rewardToken){
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
  
    address _underlying = underlying();
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
    // underlying in this strategy + underlying redeemable from Radiant - debt
    return IERC20(underlying()).balanceOf(address(this))
    .add(suppliedInUnderlying)
    .sub(borrowedInUnderlying);
  }

  /**
  * Supplies to Moonwel
  */
  function _supply(uint256 amount) internal {
    if (amount == 0){
      return;
    }
    address _underlying = underlying();
    address _cToken = cToken();
    uint256 balance = IERC20(_underlying).balanceOf(address(this));
    if (amount < balance) {
      balance = amount;
    }
    if (_underlying == weth) {
      IWETH(weth).withdraw(balance);
      CTokenInterface(_cToken).mint{value: balance}();
    } else {
      IERC20(_underlying).safeApprove(_cToken, 0);
      IERC20(_underlying).safeApprove(_cToken, balance);
      CTokenInterface(_cToken).mint(balance);
    }
  }

  /**
  * Borrows against the collateral
  */
  function _borrow(uint256 amountUnderlying) internal {
    if (amountUnderlying == 0){
      return;
    }
    // Borrow, check the balance for this contract's address
    CTokenInterface(cToken()).borrow(amountUnderlying);
    if(underlying() == weth){
      IWETH(weth).deposit{value: address(this).balance}();
    }
  }

  function _redeem(uint256 amountUnderlying) internal {
    address _cToken = cToken();
    uint256 exchange = CTokenInterface(_cToken).exchangeRateCurrent();
    if (amountUnderlying.mul(1e18) < exchange){
      return;
    }
    CTokenInterface(cToken()).redeemUnderlying(amountUnderlying);
    if(underlying() == weth){
      IWETH(weth).deposit{value: address(this).balance}();
    }
  }

  function _repay(uint256 amountUnderlying) internal {
    if (amountUnderlying == 0){
      return;
    }
    address _underlying = underlying();
    address _cToken = cToken();
    if (_underlying == weth) {
      IWETH(weth).withdraw(amountUnderlying);
      CTokenInterface(_cToken).repayBorrow{value: amountUnderlying}();
    } else {
      IERC20(_underlying).safeApprove(_cToken, 0);
      IERC20(_underlying).safeApprove(_cToken, amountUnderlying);
      CTokenInterface(_cToken).repayBorrow(amountUnderlying);
    }
  }

  function _redeemMaximum() internal {
    address _cToken = cToken();
    // amount of liquidity in Radiant
    uint256 available = CTokenInterface(_cToken).getCash();
    // amount we supplied
    uint256 supplied = CTokenInterface(_cToken).balanceOfUnderlying(address(this));
    // amount we borrowed
    uint256 borrowed = CTokenInterface(_cToken).borrowBalanceCurrent(address(this));
    uint256 balance = supplied.sub(borrowed);

    _foldRedeem(Math.min(available, balance), 0);
    supplied = CTokenInterface(_cToken).balanceOfUnderlying(address(this));
    if (supplied > 0) {
      _redeem(supplied);
    }
  }

  function _foldDeposit() internal {
    address _cToken = cToken();
    uint _borrowNum = borrowTargetFactorNumerator();
    // amount we supplied
    uint256 supplied = CTokenInterface(_cToken).balanceOfUnderlying(address(this));
    // amount we borrowed
    uint256 borrowed = CTokenInterface(_cToken).borrowBalanceCurrent(address(this));

    _depositNoFlash(supplied, borrowed, _cToken, _borrowNum);
  }

  function _foldRedeem(uint256 amount, uint256 _borrowTargetFactorNumerator) internal {
    address _cToken = cToken();
    // amount we supplied
    uint256 supplied = CTokenInterface(_cToken).balanceOfUnderlying(address(this));
    // amount we borrowed
    uint256 borrowed = CTokenInterface(_cToken).borrowBalanceCurrent(address(this));

    _redeemNoFlash(amount, supplied, borrowed, _cToken, _borrowTargetFactorNumerator);
  }

  function _depositNoFlash(uint256 supplied, uint256 borrowed, address _cToken, uint256 _borrowNum) internal {
    address _underlying = underlying();
    uint256 balance = supplied.sub(borrowed);
    uint256 borrowTarget = balance.mul(_borrowNum).div(uint(1000).sub(_borrowNum));
    {
      uint256 borrowCap = IComptroller(comptroller()).borrowCaps(_cToken);
      uint256 totalBorrows = CTokenInterface(_cToken).totalBorrows();
      uint256 borrowAvail;
      if (borrowCap == 0) {
        borrowAvail = type(uint256).max;
      } else if (totalBorrows < borrowCap) {
        borrowAvail = borrowCap.sub(totalBorrows).sub(1);
      } else {
        borrowAvail = 0;
      }
      if (borrowTarget.sub(borrowed) > borrowAvail) {
        borrowTarget = borrowed.add(borrowAvail);
      }
    }
    while (borrowed < borrowTarget) {
      uint256 wantBorrow = borrowTarget.sub(borrowed);
      uint256 maxBorrow = supplied.mul(collateralFactorNumerator()).div(uint(1000)).sub(borrowed);
      _borrow(Math.min(wantBorrow, maxBorrow));
      uint256 underlyingBalance = IERC20(_underlying).balanceOf(address(this));
      if (underlyingBalance > 0) {
        _supply(underlyingBalance);
      }
      //update parameters
      borrowed = CTokenInterface(_cToken).borrowBalanceCurrent(address(this));
      supplied = CTokenInterface(_cToken).balanceOfUnderlying(address(this));
      balance = supplied.sub(borrowed);
    }
  }

  function _redeemNoFlash(uint256 amount, uint256 supplied, uint256 borrowed, address _cToken, uint256 _borrowNum) internal {
    address _underlying = underlying();
    uint256 newBorrowTarget;
    {
        uint256 oldBalance = supplied.sub(borrowed);
        uint256 newBalance = oldBalance.sub(amount);
        newBorrowTarget = newBalance.mul(_borrowNum).div(uint(1000).sub(_borrowNum));
    }
    while (borrowed > newBorrowTarget) {
      uint256 requiredCollateral = borrowed.mul(uint(1000)).div(collateralFactorNumerator());
      uint256 toRepay = borrowed.sub(newBorrowTarget);
      // redeem just as much as needed to repay the loan
      // supplied - requiredCollateral = max redeemable, amount + repay = needed
      uint256 toRedeem = Math.min(supplied.sub(requiredCollateral), amount.add(toRepay));
      _redeem(toRedeem);
      // now we can repay our borrowed amount
      uint256 underlyingBalance = IERC20(_underlying).balanceOf(address(this));
      _repay(Math.min(toRepay, underlyingBalance));
      // update the parameters
      borrowed = CTokenInterface(_cToken).borrowBalanceCurrent(address(this));
      supplied = CTokenInterface(_cToken).balanceOfUnderlying(address(this));
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
    require(_numerator <= uint(1000), "Collateral factor cannot be this high");
    require(_numerator > borrowTargetFactorNumerator(), "Collateral factor should be higher than borrow target");
    setUint256(_COLLATERALFACTORNUMERATOR_SLOT, _numerator);
  }

  function collateralFactorNumerator() public view returns (uint256) {
    return getUint256(_COLLATERALFACTORNUMERATOR_SLOT);
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

  function _setCToken (address _target) internal {
    setAddress(_CTOKEN_SLOT, _target);
  }

  function cToken() public view returns (address) {
    return getAddress(_CTOKEN_SLOT);
  }

  function _setComptroller (address _target) internal {
    setAddress(_COMPTROLLER_SLOT, _target);
  }

  function comptroller() public view returns (address) {
    return getAddress(_COMPTROLLER_SLOT);
  }

  function finalizeUpgrade() external onlyGovernance updateSupplyInTheEnd {
    _finalizeUpgrade();
  }

  receive() external payable {}
}