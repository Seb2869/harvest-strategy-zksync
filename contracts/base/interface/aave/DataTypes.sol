// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.24;

library DataTypes {
	// refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
	struct ReserveData {
		//stores the reserve configuration
		ReserveConfigurationMap configuration;
		//the liquidity index. Expressed in ray
		uint128 liquidityIndex;
		//variable borrow index. Expressed in ray
		uint128 variableBorrowIndex;
		//the current supply rate. Expressed in ray
		uint128 currentLiquidityRate;
		//the current variable borrow rate. Expressed in ray
		uint128 currentVariableBorrowRate;
		//the current stable borrow rate. Expressed in ray
		uint128 currentStableBorrowRate;
		uint40 lastUpdateTimestamp;
		//tokens addresses
		address aTokenAddress;
		address stableDebtTokenAddress;
		address variableDebtTokenAddress;
		//address of the interest rate strategy
		address interestRateStrategyAddress;
		//the id of the reserve. Represents the position in the list of the active reserves
		uint8 id;
	}

	struct ReserveConfigurationMap {
		//bit 0-15: LTV
		//bit 16-31: Liq. threshold
		//bit 32-47: Liq. bonus
		//bit 48-55: Decimals
		//bit 56: reserve is active
		//bit 57: reserve is frozen
		//bit 58: borrowing is enabled
		//bit 59: DEPRECATED: stable rate borrowing enabled
		//bit 60: asset is paused
		//bit 61: borrowing in isolation mode is enabled
		//bit 62: siloed borrowing enabled
		//bit 63: flashloaning enabled
		//bit 64-79: reserve factor
		//bit 80-115: borrow cap in whole tokens, borrowCap == 0 => no cap
		//bit 116-151: supply cap in whole tokens, supplyCap == 0 => no cap
		//bit 152-167: liquidation protocol fee
		//bit 168-175: DEPRECATED: eMode category
		//bit 176-211: unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
		//bit 212-251: debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
		//bit 252: virtual accounting is enabled for the reserve
		//bit 253-255 unused
		uint256 data;
	}

	struct UserConfigurationMap {
		uint256 data;
	}

	enum InterestRateMode {
		NONE,
		STABLE,
		VARIABLE
	}
}