//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IVaultV1Controller} from './IVaultV1Controller.sol';
import {V1PacketTypes} from '../V1PacketTypes.sol';
import {V1TokenTypes} from '../V1TokenTypes.sol';
import {INexus} from '../../../nexus/INexus.sol';
import {BaseVaultV1Controller} from './BaseVaultV1Controller.sol';
import {IFacetCatalog} from '../../../catalog/IFacetCatalog.sol';
import {VaultV1Facet} from '../facet/VaultV1Facet.sol';

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
    uint32 vaultId,
    address transmitUsing
  ) external onlyFacetOwners {
    bytes32 nexusId = keccak256(abi.encodePacked(msg.sender));
    bytes memory innerPayload = abi.encode(vaultId);

    _sendPacket(
      destinationChainId,
      V1PacketTypes.CreateVault,
      nexusId,
      transmitUsing,
      innerPayload
    );
  }

  function addAcceptedGateway(
    uint16 destinationChainId,
    address gatewayToAdd,
    address transmitUsing
  ) external onlyFacetOwners {
    bytes32 nexusId = _makeNexusId(msg.sender);
    bytes memory innerPayload = abi.encode(gatewayToAdd);

    _sendPacket(
      destinationChainId,
      V1PacketTypes.AddAcceptedGateway,
      nexusId,
      transmitUsing,
      innerPayload
    );
  }

  function sendPayment(
    uint16 destinationChainId,
    uint32 vaultId,
    address transmitUsing,
    V1TokenTypes tokenType,
    string calldata tokenIdentifier,
    string calldata target,
    uint256 amount
  ) external onlyFacetOwners {
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
      transmitUsing,
      innerPayload
    );
  }

  function _handlePacket(
    uint16 senderChainId,
    V1PacketTypes packetType,
    bytes32 nexusId,
    address gatewayAddress,
    bytes memory payload
  ) internal override {
    _enforceAcceptedGateway(nexusId, gatewayAddress);

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
      _handleRedeemPayment(nexusId, gatewayAddress, payload);
      return;
    }
    if (packetType == V1PacketTypes.BridgeOut) {
      _handleBridgeOut(nexusId, payload);
      return;
    }
    if (packetType == V1PacketTypes.MintIOUTokens) {
      _handleMintIOUTokens(
        senderChainId,
        nexusId,
        gatewayAddress,
        payload
      );
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
    string memory addedGatewayAddressRaw = abi.decode(payload, (string));
    address addedGatewayAddress = addedGatewayAddressRaw.toAddress();

    _addAcceptedGatewayToNexus(nexusId, addedGatewayAddress);
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
    address gatewayAddress,
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
      gatewayAddress,
      nexusId,
      vaultId,
      tokenType,
      tokenIdentifier,
      amount
    );
    _decrementBridgedBalance(
      gatewayAddress,
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

  function _handleBridgeOut(
    bytes32 nexusId,
    bytes memory payload
  ) internal {
    (
      uint32 vaultId,
      V1TokenTypes tokenType,
      string memory tokenIdentifier,
      address targetGatewayAddress,
      uint16 targetChainId,
      string memory target,
      uint256 amount
    ) = abi.decode(
        payload,
        (uint32, V1TokenTypes, string, address, uint16, string, uint256)
      );

    _enforceAcceptedGateway(nexusId, targetGatewayAddress);
    _enforceMinimumAvailableBalance(
      nexusId,
      vaultId,
      tokenType,
      tokenIdentifier,
      amount
    );
    _incrementBridgedBalance(
      targetGatewayAddress,
      nexusId,
      vaultId,
      tokenType,
      tokenIdentifier,
      amount
    );
    _sendPacket(
      targetChainId,
      V1PacketTypes.MintIOUTokens,
      nexusId,
      targetGatewayAddress,
      abi.encode(vaultId, tokenType, tokenIdentifier, target, amount)
    );
  }

  function _handleMintIOUTokens(
    uint16 senderChainId,
    bytes32 nexusId,
    address gatewayAddress,
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
      nexusId,
      vaultId,
      gatewayAddress,
      tokenType,
      tokenIdentifier,
      target.toAddress(),
      amount
    );
  }

  function _makeNexusId(
    address nexusAddress
  ) internal view returns (bytes32) {
    return keccak256(abi.encode(currentChainId, nexusAddress));
  }
}
