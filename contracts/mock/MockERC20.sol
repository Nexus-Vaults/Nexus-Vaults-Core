//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract MockERC20 is ERC20 {
  constructor() ERC20('Mock', 'MCK') {}

  function transferFrom(
    address,
    address,
    uint256
  ) public override returns (bool) {
    return true;
  }
}
