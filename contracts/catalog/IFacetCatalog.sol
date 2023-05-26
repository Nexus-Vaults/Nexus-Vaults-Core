//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IFacetCatalog {
  function hasPurchased(
    address user,
    address facetAddress
  ) external returns (bool);

  function purchaseFacet(address facetAddress) external;

  function purchaseFacetFrom(address payer, address facetAddress) external;
}
