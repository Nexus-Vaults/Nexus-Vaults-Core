//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Nexus} from './Nexus.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IFacetCatalog} from '../catalog/IFacetCatalog.sol';
import {IDeployer} from '../deployer/IDeployer.sol';

error FeeTransferFailed();

contract NexusFactory is Ownable {
  event FeesUpdated(IERC20 indexed feeToken, uint256 indexed feeAmount);
  event NexusDeployed(Nexus indexed nexus, address indexed owner);

  Nexus[] public deployedContracts;
  mapping(address => bool) public hasDeployed;

  IERC20 public feeToken;
  uint256 public feeAmount;

  struct FacetInstallation {
    IFacetCatalog catalog;
    address facet;
  }

  constructor() {
    IDeployer deployer = IDeployer(msg.sender);
    bytes memory args = deployer.getCurrentDeploymentArgs();

    (IERC20 _feeToken, uint256 _feeAmount, address _treasuryAddress) = abi
      .decode(args, (IERC20, uint256, address));

    _transferOwnership(_treasuryAddress);

    feeToken = _feeToken;
    feeAmount = _feeAmount;
  }

  function create(
    string calldata name,
    address nexusOwner,
    FacetInstallation[] calldata facets
  ) external returns (address) {
    if (!feeToken.transferFrom(msg.sender, owner(), feeAmount)) {
      revert FeeTransferFailed();
    }

    Nexus nexus = new Nexus(name);

    for (uint256 i = 0; i < facets.length; i++) {
      FacetInstallation calldata facet = facets[i];

      if (facet.catalog != IFacetCatalog(address(0))) {
        facet.catalog.purchaseFacetFrom(
          msg.sender,
          address(nexus),
          facet.facet
        );
      }

      nexus.installFacet(facet.facet);
    }

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
