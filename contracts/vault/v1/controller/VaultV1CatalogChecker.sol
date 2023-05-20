//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IFacetCatalog} from '../../../catalog/IFacetCatalog.sol';

error FacetNotInstalled();

abstract contract VaultV1CatalogChecker {
  address public immutable facetAddress;
  IFacetCatalog public immutable facetCatalog;

  constructor(IFacetCatalog _facetCatalog, address _facetAddress) {
    facetCatalog = _facetCatalog;
    facetAddress = _facetAddress;
  }

  modifier onlyFacetOwners() {
    if (facetCatalog.hasPurchased(msg.sender, facetAddress)) {
      revert FacetNotInstalled();
    }
    _;
  }
}
