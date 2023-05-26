//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Nexus} from './Nexus.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

error FeeTransferFailed();

contract NexusFactory is Ownable {
  Nexus[] public deployedContracts;
  mapping(address => bool) public hasDeployed;

  IERC20 public feeToken;
  uint256 public feeAmount;

  constructor(IERC20 token, uint256 tokenAmount, address treasuryAddress) {
    _transferOwnership(treasuryAddress);
    feeToken = token;
    feeAmount = tokenAmount;
  }

  function create(string calldata name, address nexusOwner) external returns (address) {
    if (!feeToken.transferFrom(msg.sender, owner(), feeAmount)) {
      revert FeeTransferFailed();
    }

    Nexus nexus = new Nexus(name, nexusOwner);

    deployedContracts.push(nexus);
    hasDeployed[address(nexus)] = true;

    return address(nexus);
  }

  function setFees(IERC20 token, uint256 amt) external onlyOwner {
    feeToken = token;
    feeAmount = amt;
  }
}
