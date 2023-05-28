//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {INexusGateway} from '../../../gateway/INexusGateway.sol';
import {VaultV1} from '../VaultV1.sol';
import {V1TokenTypes} from '../V1TokenTypes.sol';
import {ERC165Checker} from '../../../utils/ERC165Checker.sol';

import {IFacetCatalog} from '../../../catalog/IFacetCatalog.sol';

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

error FacetNotInstalled();

error GatewayNotAccepted(bytes32 nexusId, address gatewayAddress);
error GatewayBalanceTooLow(
  bytes32 nexusId,
  uint32 vaultId,
  address gatewayAddress
);
error AvailableBalanceTooLow(bytes32 nexusId, uint32 vaultId);

abstract contract BaseVaultV1Controller is ERC165Checker, Ownable {
  struct NexusRecord {
    mapping(uint256 => VaultRecord) vaults;
    mapping(address => bool) acceptedGateways;
    uint32[] vaultIds;
  }
  struct VaultRecord {
    bool isDefined;
    VaultV1 vault;
    mapping(V1TokenTypes => mapping(string => TokenRecord)) tokens;
  }
  struct TokenRecord {
    uint256 bridgedBalance;
    mapping(address => uint256) gatewayBalances;
  }

  event NexusAddAcceptedGateway(
    bytes32 indexed nexusId,
    address indexed gateway
  );

  mapping(bytes32 => NexusRecord) internal nexusVaults;
  mapping(INexusGateway => bool) public gateways;

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
    address gatewayAddress
  ) internal view {
    if (!nexusVaults[nexusId].acceptedGateways[gatewayAddress]) {
      revert GatewayNotAccepted(nexusId, gatewayAddress);
    }
  }

  function _enforceMinimumGatewayBalance(
    address gatewayAddress,
    bytes32 nexusId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string calldata tokenIdentifier,
    uint256 minimumBalance
  ) internal view {
    if (
      nexusVaults[nexusId]
      .vaults[vaultId]
      .tokens[tokenType][tokenIdentifier].gatewayBalances[gatewayAddress] <
      minimumBalance
    ) {
      revert GatewayBalanceTooLow(nexusId, vaultId, gatewayAddress);
    }
  }

  function _enforceMinimumAvailableBalance(
    bytes32 nexusId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string calldata tokenIdentifier,
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
    address gatewayAddress
  ) internal {
    emit NexusAddAcceptedGateway(nexusId, gatewayAddress);

    nexusVaults[nexusId].acceptedGateways[gatewayAddress] = true;
  }

  function _incrementBridgedBalance(
    address gatewayAddress,
    bytes32 nexusId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string calldata tokenIdentifier,
    uint256 amount
  ) internal {
    TokenRecord storage tokenRecord = nexusVaults[nexusId]
      .vaults[vaultId]
      .tokens[tokenType][tokenIdentifier];

    tokenRecord.bridgedBalance += amount;
    tokenRecord.gatewayBalances[gatewayAddress] += amount;
  }

  function _decrementBridgedBalance(
    address gatewayAddress,
    bytes32 nexusId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string calldata tokenIdentifier,
    uint256 amount
  ) internal {
    TokenRecord storage tokenRecord = nexusVaults[nexusId]
      .vaults[vaultId]
      .tokens[tokenType][tokenIdentifier];

    tokenRecord.bridgedBalance -= amount;
    tokenRecord.gatewayBalances[gatewayAddress] -= amount;
  }
}
