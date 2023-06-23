// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {V1SendChainBatch} from '../types/send/V1SendChainBatch.sol';

interface IBatchPaymentsV1Facet {
  function batchSendV1(
    V1SendChainBatch[] calldata batches
  ) external payable;
}
