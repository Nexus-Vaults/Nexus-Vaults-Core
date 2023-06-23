//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {V1Payment} from '../vault/v1/types/V1Payment.sol';
import {StringToAddress} from '../utils/StringAddressUtils.sol';

error MustBeIOUTokenFactory(address factory, address sender);

contract IOUToken is ERC20 {
  using StringToAddress for string;

  address public immutable factory;

  constructor(
    string memory _name,
    string memory _symbol
  ) ERC20(_name, _symbol) {
    factory = msg.sender;
  }

  modifier onlyFactory() {
    if (msg.sender != factory) {
      revert MustBeIOUTokenFactory(factory, msg.sender);
    }
    _;
  }

  function batchMint(V1Payment[] memory payments) external onlyFactory {
    for (uint i = 0; i < payments.length; i++) {
      _mint(payments[i].target.toAddress(), payments[i].amount);
    }
  }

  function mint(address target, uint256 amount) external onlyFactory {
    _mint(target, amount);
  }

  function burn(address target, uint256 amount) external onlyFactory {
    _burn(target, amount);
  }
}
