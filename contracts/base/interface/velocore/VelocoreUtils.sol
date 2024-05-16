// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import "./Token.sol";

function toTokenInfo(bytes1 _tokenRefIndex,uint8 _method,int128 _amount) pure returns (bytes32) {
  return bytes32(bytes1(_tokenRefIndex)) | bytes32(bytes2(uint16(_method))) | bytes32(uint256(uint128(uint256(int256(_amount)))));
}
function toPoolId(uint8 _optype,address _pool) pure returns (bytes32){
    return bytes32(bytes1(_optype)) | bytes32(uint256(uint160(address(_pool))));
}

uint8 constant SWAP = 0;
uint8 constant GAUGE = 1;
uint8 constant CONVERT = 2;
uint8 constant VOTE = 3;
uint8 constant USERBALANCE = 4;

uint8 constant EXACTLY = 0;
uint8 constant AT_MOST = 1;
uint8 constant ALL = 2;
