//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Diamond} from '../diamond/Diamond.sol';
import {INexus} from './INexus.sol';
import {LibDiamond} from '../diamond/LibDiamond.sol';

error MustBeOwner(address owner, address sender);

contract Nexus is Diamond, INexus {
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
}
