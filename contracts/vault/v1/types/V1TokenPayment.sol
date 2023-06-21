//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {V1TokenTypes} from './V1TokenTypes.sol';
import {V1Payment} from './V1Payment.sol';

struct V1TokenPayment {
  V1TokenTypes tokenType;
  string tokenIdentifier;
  V1Payment[] payments;
}
