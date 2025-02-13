// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./inheritance/Controllable.sol";
import "./interface/IController.sol";
import "./interface/IFoldingStrategy.sol";
import "./interface/reactorFusion/CTokenInterface.sol";
import "./interface/reactorFusion/IComptroller.sol";

contract FoldingCapChecker is Controllable {
    using SafeMath for uint256;

    struct VaultInfo {
        address vault;
        address strategy;
        address comptroller;
        address cToken;
    }

    VaultInfo[] public vaults;

    constructor(address _storage) Controllable(_storage) {}

    function addVault(address _vault, address _strategy, address _comptroller, address _cToken) public onlyGovernance {
        vaults.push(VaultInfo({
            vault: _vault,
            strategy: _strategy,
            comptroller: _comptroller,
            cToken: _cToken
        }));
    }

    function removeVault(address _target) public onlyGovernance {
      uint256 i = getVaultIndex(_target);
      require(i != type(uint256).max, "Vault does not exists");
      uint256 lastIndex = vaults.length - 1;

      // swap
      vaults[i] = vaults[lastIndex];

      // delete last element
      vaults.pop();
    }

    // If the return value is MAX_UINT256, it means that
    // the specified vault is not in the list
    function getVaultIndex(address _target) public view returns(uint256) {
      for(uint i = 0 ; i < vaults.length ; i++){
        if(vaults[i].vault == _target)
          return i;
      }
      return type(uint256).max;
    }

    function getTargetFactor(address _strategy) public view returns(uint256) {
        return IFoldingStrategy(_strategy).borrowTargetFactorNumerator();
    }

    function getCurrentFactor(address _strategy, address _cToken) public view returns(uint256) {
        (, uint256 supplyBalance, uint256 borrowBalance, uint256 exchange) = CTokenInterface(_cToken).getAccountSnapshot(_strategy);
        return borrowBalance.mul(1000).div(supplyBalance.mul(exchange).div(1e18));
    }

    function getSupplyCap(address _cToken, address _comptroller) public view returns(uint256) {
        return IComptroller(_comptroller).supplyCaps(_cToken);
    }

    function getBorrowCap(address _cToken, address _comptroller) public view returns(uint256) {
        return IComptroller(_comptroller).borrowCaps(_cToken);
    }

    function getCurrentBorrowed(address _cToken) public view returns(uint256) {
        return CTokenInterface(_cToken).totalBorrows();
    }

    function getCurrentSupplied(address _cToken) public view returns(uint256) {
        return CTokenInterface(_cToken).getCash()
            .add(CTokenInterface(_cToken).totalBorrows())
            .add(CTokenInterface(_cToken).totalReserves());
    }

    function checker() external view returns (bool, bytes memory) {
        for (uint256 i = 0; i < vaults.length; i++) {
            VaultInfo memory vault = vaults[i];
            uint256 targetFactor = getTargetFactor(vault.strategy);
            uint256 currentFactor = getCurrentFactor(vault.strategy, vault.cToken);
            if (targetFactor > currentFactor) {
                uint256 supplyCap = getSupplyCap(vault.cToken, vault.comptroller);
                uint256 borrowCap = getBorrowCap(vault.cToken, vault.comptroller);
                uint256 currentBorrowed = getCurrentBorrowed(vault.cToken);
                uint256 currentSupplied = getCurrentSupplied(vault.cToken);
                if (currentSupplied < supplyCap && currentBorrowed < borrowCap) {
                    bytes memory execPayload = abi.encodeWithSelector(IController.doHardWork.selector, vault.vault);
                    return(true, execPayload);
                }
            }
        }

        return(false, bytes("No vaults to harvest"));
    }

}