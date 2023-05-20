//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface INexus {
  function nexusName() external returns (string memory);

  function installFacet(address facetAddress) external;
}
