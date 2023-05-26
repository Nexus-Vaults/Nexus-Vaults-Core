// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import {ERC165Checker} from '../utils/ERC165Checker.sol';
import {IDiamondFacet} from './IDiamondFacet.sol';
import {LibDiamond} from './LibDiamond.sol';

// When no function exists for function called
error FunctionNotFound(bytes4 _functionSelector);
error TargetMustBeFacet(address target);

error CannotInstallSelectorThatAlreadyExists(bytes4 selector);

contract Diamond is ERC165Checker {
  function _installFacet(address facetAddress) internal {
    LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

    if (
      !_supportsERC165Interface(
        facetAddress,
        type(IDiamondFacet).interfaceId
      )
    ) {
      revert TargetMustBeFacet(facetAddress);
    }

    bytes4[] memory functionSelectors = IDiamondFacet(facetAddress)
      .getSelectors();
    uint16 selectorCount = uint16(ds.selectors.length);

    for (
      uint256 selectorIndex;
      selectorIndex < functionSelectors.length;
      selectorIndex++
    ) {
      bytes4 selector = functionSelectors[selectorIndex];
      address oldFacetAddress = ds
        .facetAddressAndSelectorPosition[selector]
        .facetAddress;
      if (oldFacetAddress != address(0)) {
        revert CannotInstallSelectorThatAlreadyExists(selector);
      }
      ds.facetAddressAndSelectorPosition[selector] = LibDiamond
        .FacetAddressAndSelectorPosition(facetAddress, selectorCount);
      ds.selectors.push(selector);
      selectorCount++;
    }
  }

  // Find facet for function that is called and execute the
  // function if a facet is found and return any value.
  fallback() external payable {
    // get facet from function selector
    address facet = LibDiamond
      .diamondStorage()
      .facetAddressAndSelectorPosition[msg.sig]
      .facetAddress;

    if (facet == address(0)) {
      revert FunctionNotFound(msg.sig);
    }
    // Execute external function from facet using delegatecall and return any value.
    assembly {
      // copy function selector and any arguments
      calldatacopy(0, 0, calldatasize())
      // execute function call using the facet
      let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
      // get any return value
      returndatacopy(0, 0, returndatasize())
      // return any return value or error back to the caller
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  receive() external payable {}
}
