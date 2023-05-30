//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {INexusGateway} from '../../../gateway/INexusGateway.sol';
import {VaultV1} from '../VaultV1.sol';
import {V1TokenTypes} from '../V1TokenTypes.sol';
import {ERC165Checker} from '../../../utils/ERC165Checker.sol';

import {IFacetCatalog} from '../../../catalog/IFacetCatalog.sol';

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

error FacetNotInstalled();

error GatewayNotAccepted(bytes32 nexusId, uint32 gatewayId);
error GatewayBalanceTooLow(
  bytes32 nexusId,
  uint32 vaultId,
  uint32 gatewayId
);
error AvailableBalanceTooLow(bytes32 nexusId, uint32 vaultId);

abstract contract BaseVaultV1Controller is ERC165Checker, Ownable {
  struct NexusRecord {
    mapping(uint256 => VaultRecord) vaults;
    mapping(uint32 => bool) acceptedGateways;
    uint32[] vaultIds;
  }
  struct VaultRecord {
    bool isDefined;
    VaultV1 vault;
    mapping(V1TokenTypes => mapping(string => TokenRecord)) tokens;
  }
  struct TokenRecord {
    uint256 bridgedBalance;
    mapping(uint32 => uint256) gatewayBalances;
  }

  event NexusAddAcceptedGateway(
    bytes32 indexed nexusId,
    uint32 indexed gatewayId
  );

  mapping(bytes32 => NexusRecord) internal nexusVaults;

  uint16 public immutable currentChainId;

  address public immutable facetAddress;
  IFacetCatalog public immutable facetCatalog;

  constructor(
    uint16 _currentChainId,
    IFacetCatalog _facetCatalog,
    address _facetAddress
  ) {
    currentChainId = _currentChainId;
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
    uint32 gatewayId
  ) internal view {
    if (!nexusVaults[nexusId].acceptedGateways[gatewayId]) {
      revert GatewayNotAccepted(nexusId, gatewayId);
    }
  }

  function _enforceMinimumGatewayBalance(
    bytes32 nexusId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string memory tokenIdentifier,
    uint256 minimumBalance,
    uint32 gatewayId
  ) internal view {
    if (
      nexusVaults[nexusId]
      .vaults[vaultId]
      .tokens[tokenType][tokenIdentifier].gatewayBalances[gatewayId] <
      minimumBalance
    ) {
      revert GatewayBalanceTooLow(nexusId, vaultId, gatewayId);
    }
  }

  function _enforceMinimumAvailableBalance(
    bytes32 nexusId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string memory tokenIdentifier,
    uint256 minimumBalance
  ) internal view {
    VaultRecord storage vaultRecord = nexusVaults[nexusId].vaults[vaultId];
    TokenRecord storage tokenRecord = vaultRecord.tokens[tokenType][
      tokenIdentifier
    ];

    uint256 totalBalance = vaultRecord.vault.getBalance(
      tokenType,
      tokenIdentifier
    );

    if (totalBalance - tokenRecord.bridgedBalance < minimumBalance) {
      revert AvailableBalanceTooLow(nexusId, vaultId);
    }
  }

  function _addAcceptedGatewayToNexus(
    bytes32 nexusId,
    uint32 gatewayId
  ) internal {
    emit NexusAddAcceptedGateway(nexusId, gatewayId);

    nexusVaults[nexusId].acceptedGateways[gatewayId] = true;
  }

  function _incrementBridgedBalance(
    bytes32 nexusId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string memory tokenIdentifier,
    uint256 amount,
    uint32 gatewayId
  ) internal {
    TokenRecord storage tokenRecord = nexusVaults[nexusId]
      .vaults[vaultId]
      .tokens[tokenType][tokenIdentifier];

    tokenRecord.bridgedBalance += amount;
    tokenRecord.gatewayBalances[gatewayId] += amount;
  }

  function _decrementBridgedBalance(
    bytes32 nexusId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string memory tokenIdentifier,
    uint256 amount,
    uint32 gatewayId
  ) internal {
    TokenRecord storage tokenRecord = nexusVaults[nexusId]
      .vaults[vaultId]
      .tokens[tokenType][tokenIdentifier];

    tokenRecord.bridgedBalance -= amount;
    tokenRecord.gatewayBalances[gatewayId] -= amount;
  }
}
