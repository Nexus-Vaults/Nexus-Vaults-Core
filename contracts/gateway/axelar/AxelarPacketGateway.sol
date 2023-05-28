//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AxelarChainResolver} from './AxelarChainResolver.sol';
import {BaseNexusGateway} from '../BaseNexusGateway.sol';

import {IAxelarGateway} from '@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarGateway.sol';
import {IAxelarGasService} from '@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarGasService.sol';
import {AxelarExecutable} from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol';

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';

abstract contract AxelarPacketGateway is
  BaseNexusGateway,
  AxelarExecutable,
  AxelarChainResolver
{
  using Address for address;

  error CallWithTokenNotAllowed();
  error UnAuthorizedSender(address expected, address actual);
  error UnAuthorizedSourceAddress();

  IAxelarGasService public immutable axelarGasService;

  constructor(
    IAxelarGateway _axelarGateway,
    IAxelarGasService _axelarGasService
  ) AxelarExecutable(address(_axelarGateway)) {
    axelarGasService = _axelarGasService;
  }

  function axelar_sendPacketTo(
    uint16 targetChainId,
    bytes memory packetBytes
  ) internal {
    (
      string memory chainName,
      string memory gatewayAddress
    ) = resolveChainById(targetChainId);

    gateway.callContract(chainName, gatewayAddress, packetBytes);

    if (msg.value > 0) {
      axelarGasService.payNativeGasForContractCall{value: msg.value}(
        address(this),
        chainName,
        gatewayAddress,
        packetBytes,
        tx.origin
      );
    }
  }

  function _execute(
    string calldata sourceChain,
    string calldata sourceAddress,
    bytes calldata payload
  ) internal override {
    (uint16 chainId, bytes32 gatewayAddressHash) = resolveChainByName(
      sourceChain
    );

    if (keccak256(bytes(sourceAddress)) != gatewayAddressHash) {
      revert UnAuthorizedSourceAddress();
    }

    _handlePacket(chainId, payload);
  }

  function _executeWithToken(
    string calldata,
    string calldata,
    bytes calldata,
    string calldata,
    uint256
  ) internal pure override {
    revert CallWithTokenNotAllowed();
  }
}
