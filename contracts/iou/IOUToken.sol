//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';

error MustBeIOUTokenFactory(address factory, address sender);

contract IOUToken is ERC20 {
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

  function mint(address target, uint256 amount) external onlyFactory {
    _mint(target, amount);
  }

  function burn(address target, uint256 amount) external onlyFactory {
    _burn(target, amount);
  }
}
