// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {V1ChainBatchPayment} from '../types/V1ChainBatchPayment.sol';

interface IBatchPaymentsV1Facet {
  function batchSendPayment(
    V1ChainBatchPayment[] calldata batchPayments
  ) external payable;
}
