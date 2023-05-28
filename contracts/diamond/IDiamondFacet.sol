// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IDiamondFacet {
  function getSelectors() external pure returns (bytes4[] memory);

  function getSupportedInterfaceIds()
    external
    pure
    returns (bytes4[] memory);
}
