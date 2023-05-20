//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Diamond} from '../diamond/Diamond.sol';
import {INexus} from './INexus.sol';
import {LibDiamond} from '../diamond/LibDiamond.sol';
import {IFacetCatalog} from '../catalog/IFacetCatalog.sol';

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

error MustBeOwner(address owner, address sender);

contract Nexus is Diamond, INexus {
  struct FacetPayment {
    IERC20 token;
    uint256 amount;
  }

  string public override nexusName;

  constructor(string memory name, address owner) {
    nexusName = name;

    LibDiamond.diamondStorage().contractOwner = owner;
  }

  function installFacet(address facetAddress) public {
    LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

    if (msg.sender != ds.contractOwner) {
      revert MustBeOwner(ds.contractOwner, msg.sender);
    }

    _installFacet(facetAddress);
  }

  function batchInstallFacet(address[] calldata facetAddresses) external {
    LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

    if (msg.sender != ds.contractOwner) {
      revert MustBeOwner(ds.contractOwner, msg.sender);
    }

    for (uint i = 0; i < facetAddresses.length; i++) {
      _installFacet(facetAddresses[i]);
    }
  }

  function _installFacetFromCatalog(
    IFacetCatalog catalog,
    address facetAddress,
    FacetPayment calldata payment
  ) external {
    LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

    if (msg.sender != ds.contractOwner) {
      revert MustBeOwner(ds.contractOwner, msg.sender);
    }

    payment.token.approve(address(catalog), payment.amount);
    catalog.purchaseFacet(facetAddress);
    _installFacet(facetAddress);
  }

  function _batchInstallFacetFromCatalog(
    IFacetCatalog catalog,
    address[] memory facetAddresses,
    FacetPayment[] calldata payments
  ) external {
    LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

    if (msg.sender != ds.contractOwner) {
      revert MustBeOwner(ds.contractOwner, msg.sender);
    }

    for (uint i = 0; i < payments.length; i++) {
      payments[i].token.approve(address(catalog), payments[i].amount);
    }

    for (uint i = 0; i < facetAddresses.length; i++) {
      catalog.purchaseFacet(facetAddresses[i]);
      _installFacet(facetAddresses[i]);
    }
  }
}
