//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {INexusGateway} from '../../../gateway/INexusGateway.sol';
import {VaultV1} from '../VaultV1.sol';
import {V1TokenTypes} from '../types/V1TokenTypes.sol';
import {ERC165Consumer} from '../../../utils/ERC165Consumer.sol';

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

abstract contract BaseVaultV1Controller is ERC165Consumer, Ownable {
  event NexusInitialized(bytes32 nexusId, uint32 initialGatewayId);

  struct NexusRecord {
    bool isInitialized;
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
  address public immutable batchPaymentsFacetAddress;

  IFacetCatalog public immutable facetCatalog;

  mapping(INexusGateway => uint32) public gateways; //Valid if Id != 0
  uint32 internal gatewayCount;
  mapping(uint32 => INexusGateway) public gatewayVersions;

  constructor(
    uint16 _currentChainId,
    IFacetCatalog _facetCatalog,
    address _facetAddress,
    address _batchPaymentFacetAddress
  ) {
    currentChainId = _currentChainId;
    facetCatalog = _facetCatalog;
    facetAddress = _facetAddress;
    batchPaymentsFacetAddress = _batchPaymentFacetAddress;
  }

  modifier onlyFacetOwners() {
    if (!facetCatalog.hasPurchased(msg.sender, facetAddress)) {
      revert FacetNotInstalled();
    }
    _;
  }

  modifier onlyBatchFacetOwners() {
    if (
      !facetCatalog.hasPurchased(msg.sender, batchPaymentsFacetAddress)
    ) {
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
      _revertWithAvailableBalanceTooLow(nexusId, vaultId);
    }
  }

  function _revertWithAvailableBalanceTooLow(
    bytes32 nexusId,
    uint32 vaultId
  ) internal pure {
    revert AvailableBalanceTooLow(nexusId, vaultId);
  }

  function _initializeNexus(bytes32 nexusId, uint32 gatewayId) internal {
    emit NexusInitialized(nexusId, gatewayId);

    nexusVaults[nexusId].isInitialized = true;
    _addAcceptedGatewayToNexus(nexusId, gatewayId);
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
