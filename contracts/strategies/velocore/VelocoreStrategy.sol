//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../base/interface/universalLiquidator/IUniversalLiquidator.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../../base/interface/velocore/IGauge.sol";
import "../../base/interface/velocore/IPool.sol";
import "../../base/interface/velocore/IVault.sol";
import "../../base/interface/velocore/Token.sol";
import "../../base/interface/velocore/ILens.sol";
import "../../base/interface/velocore/VelocoreUtils.sol";

contract VelocoreStrategy is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public constant velocoreVault = address(0xf5E67261CB357eDb6C7719fEFAFaaB280cB5E2A6);
  address public constant velocoreLens = address(0xf55150000aac457eCC88b34dA9291e3F6E7DB165);
  address public constant harvestMSIG = address(0x6a74649aCFD7822ae8Fb78463a9f2192752E5Aa2);

  bytes32 internal constant _DEPOSIT_TOKEN_SLOT = 0x219270253dbc530471c88a9e7c321b36afda219583431e7b6c386d2d46e70c86;

  // this would be reset on each upgrade
  address[] public rewardTokens;

  constructor() BaseUpgradeableStrategy() {
    assert(_DEPOSIT_TOKEN_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.depositToken")) - 1));
  }

  function initializeBaseStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardToken,
    address _depositToken
  ) public initializer {

    BaseUpgradeableStrategy.initialize(
      _storage,
      _underlying,
      _vault,
      velocoreVault,
      _rewardToken,
      harvestMSIG
    );

    _setDepositToken(_depositToken);
  }

  function depositArbCheck() public pure returns(bool) {
    return true;
  }

  function _rewardPoolBalance() internal view returns (uint256) {
    uint256[] memory balances = IGauge(underlying()).stakedTokens(address(this));
    return balances[0];
  }

  function _emergencyExitRewardPool() internal {
    uint256 stakedBalance = _rewardPoolBalance();
    if (stakedBalance != 0) {
      _unstakeLPToken(stakedBalance);
    }
  }

  function _withdrawUnderlyingFromPool(uint256 amount) internal {
    if (amount > 0) {
      _unstakeLPToken(amount);
    }
  }

  function _enterRewardPool() internal {
    uint256 entireBalance = IERC20(underlying()).balanceOf(address(this));
    _stakeLPToken(entireBalance);
  }

  function _investAllUnderlying() internal onlyNotPausedInvesting {
    // this check is needed, because most of the SNX reward pools will revert if
    // you try to stake(0).
    if(IERC20(underlying()).balanceOf(address(this)) > 0) {
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
      uint256 rewardBalance = IERC20(token).balanceOf(address(this));
      if (rewardBalance == 0) {
        continue;
      }
      if (token != _rewardToken){
        IERC20(token).safeApprove(_universalLiquidator, 0);
        IERC20(token).safeApprove(_universalLiquidator, rewardBalance);
        IUniversalLiquidator(_universalLiquidator).swap(token, _rewardToken, rewardBalance, 1, address(this));
      }
    }

    uint256 rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
    _notifyProfitInRewardToken(_rewardToken, rewardBalance);
    uint256 remainingRewardBalance = IERC20(_rewardToken).balanceOf(address(this));

    if (remainingRewardBalance == 0) {
      return;
    }

    address _depositToken = depositToken();
    if (_depositToken != _rewardToken) {
      IERC20(_rewardToken).safeApprove(_universalLiquidator, 0);
      IERC20(_rewardToken).safeApprove(_universalLiquidator, remainingRewardBalance);
      IUniversalLiquidator(_universalLiquidator).swap(_rewardToken, _depositToken, remainingRewardBalance, 1, address(this));
    }

    _getLPToken();
  }

  function _getLPToken() internal {
    address _underlying = underlying();
    address _depositToken = depositToken();
    int128 depositBalance = int128(int256(IERC20(_depositToken).balanceOf(address(this))));
    Token[] memory tokens = new Token[](2);
    tokens[0] = toToken(IERC20(_depositToken));
    tokens[1] = toToken(IERC20(_underlying));

    // Adding LP is swapping 2 tokens to 1 lp. So op type is again, swap!
    VelocoreOperation[] memory ops = new VelocoreOperation[](1);
    ops[0].poolId = toPoolId(SWAP, _underlying);
    ops[0].tokenInformations = new bytes32[](2);
    // We use "EXACTLY" for the amount we know and "AT_MOST" for what we don't know exactly but expect to receive at least a certain amount.
    // Want to use 0.1e6 USDC(index 0) + 0.001e18 ETH(index 1) in exchange for at least 0 LP(index 2). (apply your slippage here)
    ops[0].tokenInformations[0] = toTokenInfo(0x00, EXACTLY, depositBalance);
    ops[0].tokenInformations[1] = toTokenInfo(0x01, AT_MOST, 0);
    ops[0].data = "";

    if (!(_depositToken == rewardToken())) {
      IERC20(_depositToken).safeApprove(velocoreVault, 0);
      IERC20(_depositToken).safeApprove(velocoreVault, uint256(int256(depositBalance)));
    }
    //we just called execute() here but of course if you are calling an external contract with ETH value transfer involved,
    // you should write it like this : vault.execute{value:0.001e18}(tokens, new int128[](3), ops);
    IVault(velocoreVault).execute(tokens, new int128[](2), ops);
  }

  function _stakeLPToken(uint256 amount) internal {
    address _underlying = underlying();
    Token[] memory tokens = new Token[](2);
    tokens[0] = toToken(IERC20(_underlying));
    tokens[1] = toToken(IERC20(rewardToken()));

    VelocoreOperation[] memory ops = new VelocoreOperation[](1);
    // address usdc_eth_pool = vault.getPair(usdc, eth);
    // OP type STAKE(GAUGE). For volatile pools, LP contract itself is a gauge contract. so use pool address for relevant pool address.
    // This is different for Wombat Pool, and I will return to that later.
    ops[0].poolId = toPoolId(GAUGE, _underlying);
    ops[0].tokenInformations = new bytes32[](2);
    int128 stakeAmount = int128(int256(amount));
    ops[0].tokenInformations[0] = toTokenInfo(0x00, EXACTLY, stakeAmount);
    //we don't know how much VC we'd harvest in this action. so just use AT_MOST 0 .
    ops[0].tokenInformations[1] = toTokenInfo(0x01, AT_MOST, 0);        
    ops[0].data = "";

    IVault(velocoreVault).execute(tokens, new int128[](2), ops);
  }

  function _unstakeLPToken(uint256 amount) internal {
    address _underlying = underlying();
    Token[] memory tokens = new Token[](2);
    tokens[0] = toToken(IERC20(_underlying));
    tokens[1] = toToken(IERC20(rewardToken()));

    VelocoreOperation[] memory ops = new VelocoreOperation[](1);
    // address usdc_eth_pool = vault.getPair(usdc, eth);
    // OP type STAKE(GAUGE). For volatile pools, LP contract itself is a gauge contract. so use pool address for relevant pool address.
    // This is different for Wombat Pool, and I will return to that later.
    ops[0].poolId = toPoolId(GAUGE, _underlying);
    ops[0].tokenInformations = new bytes32[](2);
    int128 stakeAmount = -int128(int256(amount));
    ops[0].tokenInformations[0] = toTokenInfo(0x00, EXACTLY, stakeAmount);
    //we don't know how much VC we'd harvest in this action. so just use AT_MOST 0 .
    ops[0].tokenInformations[1] = toTokenInfo(0x01, AT_MOST, 0);        
    ops[0].data = "";
    IVault(velocoreVault).execute(tokens, new int128[](2), ops);
  }

  function _claimRewards() internal {
    Token[] memory tokens = new Token[](1);
    tokens[0] = toToken(IERC20(rewardToken()));

    VelocoreOperation[] memory ops = new VelocoreOperation[](1);
    // Similar with Stake, we use op type STAKE with the pool but giving only VC as token info.
    // OP type STAKE(GAUGE). For volatile pools, LP contract itself is a gauge contract. so use pool address for relevant pool address.
    // This is different for Wombat Pool, and I will return to that later.
    ops[0].poolId = toPoolId(GAUGE, underlying());
    ops[0].tokenInformations = new bytes32[](1);
    //we don't know how much VC we'd harvest in this action. so just use AT_MOST 0 .
    ops[0].tokenInformations[0] = toTokenInfo(0x00, AT_MOST, 0);
    ops[0].data = "";

    IVault(velocoreVault).execute(tokens, new int128[](1), ops);
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
    _claimRewards();
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

  function _setDepositToken(address _address) internal {
    setAddress(_DEPOSIT_TOKEN_SLOT, _address);
  }

  function depositToken() public view returns (address) {
    return getAddress(_DEPOSIT_TOKEN_SLOT);
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }
}
