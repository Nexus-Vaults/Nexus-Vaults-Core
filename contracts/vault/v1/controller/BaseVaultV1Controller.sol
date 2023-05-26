//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {INexusGateway} from '../../../gateway/INexusGateway.sol';
import {VaultV1} from '../VaultV1.sol';
import {ERC165Checker} from "../../../utils/ERC165Checker.sol";

import {IFacetCatalog} from '../../../catalog/IFacetCatalog.sol';

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

error FacetNotInstalled();

error GatewayNotAccepted(
  bytes32 nexusId,
  address gatewayAddress
);

abstract contract BaseVaultV1Controller is ERC165Checker, Ownable {
  struct NexusRecord {
    mapping(uint256 => VaultRecord) vaults;
    mapping(address => bool) acceptedGateways;
    uint32[] vaultIds;
  }
  struct VaultRecord {
    bool isDefined;
    VaultV1 vault;
  }

  event NexusAddAcceptedGateway(
    bytes32 indexed nexusId,
    address indexed gateway
  );

  mapping(bytes32 => NexusRecord) internal nexusVaults;
  mapping(INexusGateway => bool) public gateways;

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

  function _enforceAcceptedGateway(
    bytes32 nexusId,
    address gatewayAddress
  ) internal view {
    if (
      !nexusVaults[nexusId].acceptedGateways[gatewayAddress]
    ) {
      revert GatewayNotAccepted(nexusId, gatewayAddress);
    }
  }

  function _addAcceptedGatewayToNexus(
    bytes32 nexusId,
    address gatewayAddress
  ) internal {
    emit NexusAddAcceptedGateway(nexusId, gatewayAddress);

    nexusVaults[nexusId].acceptedGateways[gatewayAddress] = true;
  }
}
