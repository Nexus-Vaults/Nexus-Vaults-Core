//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {BaseNexusGateway} from './BaseNexusGateway.sol';
import {AxelarPacketGateway} from './axelar/AxelarPacketGateway.sol';
import {INexusGateway} from './INexusGateway.sol';
import {IVaultGatewayAdapater} from '../vault/IVaultGatewayAdapater.sol';
import {IDeployer} from '../deployer/IDeployer.sol';

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import {IAxelarGateway} from '@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarGateway.sol';
import {IAxelarGasService} from '@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarGasService.sol';

error AlreadyInitialized();
error NotInitialized();
error RouteAlreadyDefined(uint16 chainId);
error NoRouteDefined();
error SenderNotAuthorized();

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

  uint16 public immutable currentChainId;
  IVaultGatewayAdapater public immutable vaultGatewayAdapater;

  mapping(uint16 => RouteType) public routeTypes;

  constructor()
    AxelarPacketGateway(
      _decodeAxelarGatewayParam(),
      _decodeAxelarGasServiceParam()
    )
  {
    IDeployer deployer = IDeployer(msg.sender);
    bytes memory args = deployer.getCurrentDeploymentArgs();
    (
      uint16 _currentChainId,
      IVaultGatewayAdapater _vaultGatewayAdapater,
      ,
      ,
      address _owner
    ) = abi.decode(
        args,
        (
          uint16,
          IVaultGatewayAdapater,
          IAxelarGateway,
          IAxelarGasService,
          address
        )
      );

    _transferOwnership(_owner);
    currentChainId = _currentChainId;
    vaultGatewayAdapater = _vaultGatewayAdapater;
  }

  function _decodeAxelarGatewayParam()
    internal
    view
    returns (IAxelarGateway)
  {
    IDeployer deployer = IDeployer(msg.sender);
    bytes memory args = deployer.getCurrentDeploymentArgs();
    (, , IAxelarGateway _axelarGateway, , ) = abi.decode(
      args,
      (
        uint16,
        IVaultGatewayAdapater,
        IAxelarGateway,
        IAxelarGasService,
        address
      )
    );
    return _axelarGateway;
  }

  function _decodeAxelarGasServiceParam()
    internal
    view
    returns (IAxelarGasService)
  {
    IDeployer deployer = IDeployer(msg.sender);
    bytes memory args = deployer.getCurrentDeploymentArgs();
    (, , , IAxelarGasService _axelarGasService, ) = abi.decode(
      args,
      (
        uint16,
        IVaultGatewayAdapater,
        IAxelarGateway,
        IAxelarGasService,
        address
      )
    );
    return _axelarGasService;
  }

  struct AxelarRoute {
    uint16 chainId;
    string chainName;
    string gatewayAddress;
  }

  function isReady() public view returns (bool) {
    return owner() == address(0);
  }

  function initialize(
    AxelarRoute[] calldata axelarRoutes
  ) external onlyOwner {
    _initializeAxelarRoutes(axelarRoutes);
    _transferOwnership(address(0));
  }

  function _initializeAxelarRoutes(
    AxelarRoute[] calldata routes
  ) internal {
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
  ) external payable {
    if (!isReady()) {
      revert NotInitialized();
    }
    if (msg.sender != address(vaultGatewayAdapater)) {
      revert SenderNotAuthorized();
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

    vaultGatewayAdapater.handlePacket{value: msg.value}(
      sourceChainId,
      message
    );
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public pure override returns (bool) {
    return interfaceId == type(INexusGateway).interfaceId;
  }
}
