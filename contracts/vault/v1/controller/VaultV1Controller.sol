//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IVaultV1Controller} from './IVaultV1Controller.sol';
import {V1PacketTypes} from '../V1PacketTypes.sol';
import {V1TokenTypes} from '../V1TokenTypes.sol';
import {INexus} from '../../../nexus/INexus.sol';
import {BaseVaultV1Controller} from './BaseVaultV1Controller.sol';
import {IFacetCatalog} from '../../../catalog/IFacetCatalog.sol';
import {VaultV1Facet} from '../facet/VaultV1Facet.sol';
import {IOUTokenRecord} from './modules/IOUTokenModule.sol';

import {VaultFactoryModule} from './modules/VaultFactoryModule.sol';
import {GatewayAdapterModule} from './modules/GatewayAdapterModule.sol';
import {IOUTokenModule} from './modules/IOUTokenModule.sol';
import {InspectorModule} from './modules/InspectorModule.sol';

import {StringToAddress, AddressToString} from '../../../utils/StringAddressUtils.sol';

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

error UnsupportedPacket(V1PacketTypes packetType);

contract VaultV1Controller is
  IVaultV1Controller,
  Ownable,
  BaseVaultV1Controller,
  GatewayAdapterModule,
  VaultFactoryModule,
  IOUTokenModule,
  InspectorModule
{
  using StringToAddress for string;
  using AddressToString for address;

  constructor(
    uint16 _currentChainId,
    IFacetCatalog _facetCatalog
  )
    BaseVaultV1Controller(
      _currentChainId,
      _facetCatalog,
      address(new VaultV1Facet(address(this)))
    )
  {}

  function deployVault(
    uint16 destinationChainId,
    uint32 transmitUsingGatewayId,
    uint32 vaultId
  ) external payable onlyFacetOwners {
    bytes32 nexusId = _makeNexusId(msg.sender);
    bytes memory innerPayload = abi.encode(vaultId);

    _sendPacket(
      destinationChainId,
      V1PacketTypes.CreateVault,
      nexusId,
      innerPayload,
      transmitUsingGatewayId
    );
  }

  function addLocalAcceptedGateway(
    uint32 gatewayId
  ) external onlyFacetOwners {
    bytes32 nexusId = _makeNexusId(msg.sender);

    if (!nexusVaults[nexusId].isInitialized) {
      _initializeNexus(nexusId, gatewayId);
    } else {
      _addAcceptedGatewayToNexus(nexusId, gatewayId);
    }
  }

  function addAcceptedGateway(
    uint16 destinationChainId,
    uint32 transmitUsingGatewayId,
    uint32 gatewayIdToAdd
  ) external payable onlyFacetOwners {
    bytes32 nexusId = _makeNexusId(msg.sender);
    bytes memory innerPayload = abi.encode(gatewayIdToAdd);

    _sendPacket(
      destinationChainId,
      V1PacketTypes.AddAcceptedGateway,
      nexusId,
      innerPayload,
      transmitUsingGatewayId
    );
  }

  function sendPayment(
    uint16 destinationChainId,
    uint32 transmitUsingGatewayId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string calldata tokenIdentifier,
    string calldata target,
    uint256 amount
  ) external payable onlyFacetOwners {
    bytes32 nexusId = _makeNexusId(msg.sender);
    bytes memory innerPayload = abi.encode(
      vaultId,
      tokenType,
      tokenIdentifier,
      target,
      amount
    );

    _sendPacket(
      destinationChainId,
      V1PacketTypes.SendPayment,
      nexusId,
      innerPayload,
      transmitUsingGatewayId
    );
  }

  function redeemPayment(
    address iouTokenAddress,
    string calldata target,
    uint256 amount
  ) external payable {
    IOUTokenRecord storage tokenRecord = tokenToRecord[iouTokenAddress];

    _burnIOU(
      tokenRecord.vaultChainId,
      tokenRecord.gatewayId,
      tokenRecord.nexusId,
      tokenRecord.vaultId,
      tokenRecord.tokenType,
      tokenRecord.tokenIdentifier,
      msg.sender,
      amount
    );

    bytes memory innerPayload = abi.encode(
      tokenRecord.vaultId,
      tokenRecord.tokenType,
      tokenRecord.tokenIdentifier,
      target,
      amount
    );

    _sendPacket(
      tokenRecord.vaultChainId,
      V1PacketTypes.RedeemPayment,
      tokenRecord.nexusId,
      innerPayload,
      tokenRecord.gatewayId
    );
  }

  function bridgeOut(
    uint16 targetChainId,
    uint32 transmitUsingGatewayId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string calldata tokenIdentifier,
    uint16 destinationChainId,
    address destinationGatewayAddress,
    string memory target,
    uint256 amount
  ) external payable onlyFacetOwners {
    bytes32 nexusId = _makeNexusId(msg.sender);
    bytes memory innerPayload = abi.encode(
      vaultId,
      tokenType,
      tokenIdentifier,
      destinationGatewayAddress,
      destinationChainId,
      target,
      amount
    );

    _sendPacket(
      targetChainId,
      V1PacketTypes.BridgeOut,
      nexusId,
      innerPayload,
      transmitUsingGatewayId
    );
  }

  function _handlePacket(
    uint16 senderChainId,
    V1PacketTypes packetType,
    bytes32 nexusId,
    bytes memory payload,
    uint32 gatewayId
  ) internal override {
    if (packetType == V1PacketTypes.CreateVault) {
      _handleDeployVault(nexusId, payload);
      return;
    }
    if (packetType == V1PacketTypes.AddAcceptedGateway) {
      _handleAddAcceptedGateway(nexusId, payload);
      return;
    }
    if (packetType == V1PacketTypes.SendPayment) {
      _handleSendPayment(nexusId, payload);
      return;
    }
    if (packetType == V1PacketTypes.RedeemPayment) {
      _handleRedeemPayment(nexusId, gatewayId, payload);
      return;
    }
    if (packetType == V1PacketTypes.BridgeOut) {
      _handleBridgeOut(nexusId, payload);
      return;
    }
    if (packetType == V1PacketTypes.MintIOUTokens) {
      _handleMintIOUTokens(senderChainId, nexusId, gatewayId, payload);
      return;
    }

    revert UnsupportedPacket(packetType);
  }

  function _handleDeployVault(
    bytes32 nexusId,
    bytes memory payload
  ) internal {
    uint32 vaultId = abi.decode(payload, (uint32));

    _deployVault(nexusId, vaultId);
  }

  function _handleAddAcceptedGateway(
    bytes32 nexusId,
    bytes memory payload
  ) internal {
    uint32 gatewayIdToAdd = abi.decode(payload, (uint32));
    _addAcceptedGatewayToNexus(nexusId, gatewayIdToAdd);
  }

  function _handleSendPayment(
    bytes32 nexusId,
    bytes memory payload
  ) internal {
    (
      uint32 vaultId,
      V1TokenTypes tokenType,
      string memory tokenIdentifier,
      string memory target,
      uint256 amount
    ) = abi.decode(
        payload,
        (uint32, V1TokenTypes, string, string, uint256)
      );

    _enforceMinimumAvailableBalance(
      nexusId,
      vaultId,
      tokenType,
      tokenIdentifier,
      amount
    );
    nexusVaults[nexusId].vaults[vaultId].vault.sendTokens(
      tokenType,
      tokenIdentifier,
      payable(target.toAddress()),
      amount
    );
  }

  function _handleRedeemPayment(
    bytes32 nexusId,
    uint32 gatewayId,
    bytes memory payload
  ) internal {
    (
      uint32 vaultId,
      V1TokenTypes tokenType,
      string memory tokenIdentifier,
      string memory target,
      uint256 amount
    ) = abi.decode(
        payload,
        (uint32, V1TokenTypes, string, string, uint256)
      );

    _enforceMinimumGatewayBalance(
      nexusId,
      vaultId,
      tokenType,
      tokenIdentifier,
      amount,
      gatewayId
    );
    _decrementBridgedBalance(
      nexusId,
      vaultId,
      tokenType,
      tokenIdentifier,
      amount,
      gatewayId
    );
    nexusVaults[nexusId].vaults[vaultId].vault.sendTokens(
      tokenType,
      tokenIdentifier,
      payable(target.toAddress()),
      amount
    );
  }

  function _handleBridgeOut(
    bytes32 nexusId,
    bytes memory payload
  ) internal {
    (
      uint32 vaultId,
      V1TokenTypes tokenType,
      string memory tokenIdentifier,
      uint32 targetGatewayId,
      uint16 targetChainId,
      string memory target,
      uint256 amount
    ) = abi.decode(
        payload,
        (uint32, V1TokenTypes, string, uint32, uint16, string, uint256)
      );

    _enforceAcceptedGateway(nexusId, targetGatewayId);
    _enforceMinimumAvailableBalance(
      nexusId,
      vaultId,
      tokenType,
      tokenIdentifier,
      amount
    );
    _incrementBridgedBalance(
      nexusId,
      vaultId,
      tokenType,
      tokenIdentifier,
      amount,
      targetGatewayId
    );
    _sendPacket(
      targetChainId,
      V1PacketTypes.MintIOUTokens,
      nexusId,
      abi.encode(vaultId, tokenType, tokenIdentifier, target, amount),
      targetGatewayId
    );
  }

  function _handleMintIOUTokens(
    uint16 senderChainId,
    bytes32 nexusId,
    uint32 gatewayId,
    bytes memory payload
  ) internal {
    (
      uint32 vaultId,
      V1TokenTypes tokenType,
      string memory tokenIdentifier,
      string memory target,
      uint256 amount
    ) = abi.decode(
        payload,
        (uint32, V1TokenTypes, string, string, uint256)
      );

    _mintIOU(
      senderChainId,
      gatewayId,
      nexusId,
      vaultId,
      tokenType,
      tokenIdentifier,
      target.toAddress(),
      amount
    );
  }

  function _makeNexusId(
    address nexusAddress
  ) internal view returns (bytes32) {
    return keccak256(abi.encodePacked(currentChainId, nexusAddress));
  }
}
