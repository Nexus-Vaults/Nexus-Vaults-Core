//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {BaseNexusGateway} from './BaseNexusGateway.sol';
import {AxelarPacketGateway} from './axelar/AxelarPacketGateway.sol';
import {INexusGateway} from './INexusGateway.sol';
import {IVaultController} from '../vault/IVaultController.sol';

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import {IAxelarGateway} from '@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarGateway.sol';
import {IAxelarGasService} from '@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarGasService.sol';

error AlreadyInitialized();
error NotInitialized();
error RouteAlreadyDefined(uint16 chainId);
error NoRouteDefined();

contract NexusGateway is
  BaseNexusGateway,
  AxelarPacketGateway,
  Ownable,
  IERC165,
  INexusGateway
{
  enum RouteType {
    None,
    Axelar,
    Wormhole
  }

  uint16 public currentChainId;
  IVaultController public vaultController;
  mapping(uint16 => RouteType) public routeTypes;

  constructor(
    uint16 chainId,
    IVaultController controller,
    IAxelarGateway axelarGateway,
    IAxelarGasService axelarGasService
  ) AxelarPacketGateway(axelarGateway, axelarGasService) {
    currentChainId = chainId;
    vaultController = controller;
  }

  struct AxelarRoute {
    uint16 chainId;
    string chainName;
    string gatewayAddress;
  }

  function initialize(AxelarRoute[] calldata axelarRoutes) external onlyOwner {
    _initializeAxelarRoutes(axelarRoutes);
    _transferOwnership(address(0));
  }

  function _initializeAxelarRoutes(AxelarRoute[] calldata routes) internal {
    if (isReady()) {
      revert AlreadyInitialized();
    }

    for (uint i = 0; i < routes.length; i++) {
      AxelarRoute calldata route = routes[i];

      if (routeTypes[route.chainId] != RouteType.None) {
        revert RouteAlreadyDefined(route.chainId);
      }

      _addChain(route.chainId, route.chainName, route.gatewayAddress);
      routeTypes[route.chainId] = RouteType.Axelar;
    }
  }

  function sendPacketTo(
    uint16 chainId,
    bytes memory payload
  ) external payable onlyOwner {
    if (!isReady()) {
      revert NotInitialized();
    }

    if (chainId == currentChainId) {
      _handlePacket(currentChainId, payload);
      return;
    }

    if (routeTypes[chainId] == RouteType.None) {
      revert NoRouteDefined();
    }
    if (routeTypes[chainId] == RouteType.Axelar) {
      axelar_sendPacketTo(chainId, payload);
      return;
    }

    assert(false);
  }

  function _handlePacket(
    uint16 sourceChainId,
    bytes memory message
  ) internal override {
    if (!isReady()) {
      revert NotInitialized();
    }

    vaultController.handlePacket(sourceChainId, message);
  }

  function isReady() public view returns (bool) {
    return owner() == address(0);
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override returns (bool) {
    return interfaceId == type(INexusGateway).interfaceId;
  }
}