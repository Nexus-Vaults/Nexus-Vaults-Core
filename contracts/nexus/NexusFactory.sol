//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Nexus} from './Nexus.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

error FeeTransferFailed();
error MustBeTreasury();

contract NexusFactory {
  Nexus[] public deployedContracts;
  mapping(address => bool) public hasDeployed;

  IERC20 public feeToken;
  uint256 public feeAmount;
  address public immutable treasury;

  constructor(IERC20 token, uint256 tokenAmount, address treasuryAddress) {
    feeToken = token;
    feeAmount = tokenAmount;
    treasury = treasuryAddress;
  }

  function create(
    string calldata name,
    address owner
  ) external returns (address) {
    if (!feeToken.transferFrom(msg.sender, treasury, feeAmount)) {
      revert FeeTransferFailed();
    }

    Nexus nexus = new Nexus(name, owner);

    deployedContracts.push(nexus);
    hasDeployed[address(nexus)] = true;

    return address(nexus);
  }

  function setFees(IERC20 token, uint256 amt) external {
    if (msg.sender != treasury) {
      revert MustBeTreasury();
    }

    feeToken = token;
    feeAmount = amt;
  }
}
