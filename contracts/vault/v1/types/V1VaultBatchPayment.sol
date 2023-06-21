//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {V1TokenPayment} from './V1TokenPayment.sol';

struct V1VaultBatchPayment {
  uint32 vaultId;
  V1TokenPayment[] tokenPayments;
}
