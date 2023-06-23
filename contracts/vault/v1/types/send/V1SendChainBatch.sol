//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {V1SendTokenBatch} from './V1SendTokenBatch.sol';

struct V1SendChainBatch {
  uint16 destinationChainId;
  uint32 transmitUsingGatewayId;
  uint256 gasFeeAmount;
  V1SendTokenBatch[] vaultPayments;
}
