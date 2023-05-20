//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IFacetCatalog {
  function purchaseFacet(address facetAddress) external;

  function purchaseFacetFrom(address payer, address facetAddress) external;
}
