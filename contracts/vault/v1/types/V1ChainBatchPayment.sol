//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {V1VaultBatchPayment} from './V1VaultBatchPayment.sol';

struct V1ChainBatchPayment {
  uint16 destinationChainId;
  uint32 transmitUsingGatewayId;
  uint256 gasFeeAmount;
  V1VaultBatchPayment[] vaultPayments;
}
