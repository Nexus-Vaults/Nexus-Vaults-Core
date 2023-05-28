//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Nexus} from './Nexus.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

error FeeTransferFailed();

contract NexusFactory is Ownable {
  event FeesUpdated(IERC20 indexed feeToken, uint256 indexed feeAmount);
  event NexusDeployed(Nexus indexed nexus, address indexed owner);

  Nexus[] public deployedContracts;
  mapping(address => bool) public hasDeployed;

  address private diamondLoupeFacet;
  IERC20 public feeToken;
  uint256 public feeAmount;

  constructor(
    address _diamondLoupeFacet,
    IERC20 _feeToken,
    uint256 _feeAmount,
    address _treasuryAddress
  ) {
    _transferOwnership(_treasuryAddress);
    diamondLoupeFacet = _diamondLoupeFacet;
    feeToken = _feeToken;
    feeAmount = _feeAmount;
  }

  function create(
    string calldata name,
    address nexusOwner
  ) external returns (address) {
    if (!feeToken.transferFrom(msg.sender, owner(), feeAmount)) {
      revert FeeTransferFailed();
    }

    Nexus nexus = new Nexus(name);
    nexus.installFacet(diamondLoupeFacet);
    nexus.transferOwnership(nexusOwner);

    deployedContracts.push(nexus);
    hasDeployed[address(nexus)] = true;

    emit NexusDeployed(nexus, nexusOwner);

    return address(nexus);
  }

  function setFees(
    IERC20 _feeToken,
    uint256 _feeAmount
  ) external onlyOwner {
    feeToken = _feeToken;
    feeAmount = _feeAmount;

    emit FeesUpdated(feeToken, feeAmount);
  }
}
