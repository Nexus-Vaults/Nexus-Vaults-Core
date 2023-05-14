//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../IPacketGateway.sol";
import "../INexusGateway.sol";
import "./AxelarChainResolver.sol";

import "@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarGateway.sol";
import "@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarGasService.sol";
import "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract AxelarPacketGateway is
  AxelarExecutable,
  AxelarChainResolver,
  IPacketGateway,
  Ownable
{
  using Address for address;

  error CallWithTokenNotAllowed();
  error UnAuthorizedSender(address expected, address actual);
  error UnAuthorizedSourceAddress();

  IAxelarGateway private AxelarGateway;
  IAxelarGasService private AxelarGasService;

  INexusGateway private NexusGateway;

  constructor(
    IAxelarGateway axelarGateway,
    IAxelarGasService axelarGasService,
    INexusGateway nexusGateway
  ) IAxelarExecutable(address(axelarGateway)) Ownable() {
    require(
      address(axelarGateway).isContract(),
      "axelarGateway not a contract"
    );
    require(
      address(axelarGasService).isContract(),
      "axelarGasService not a contract"
    );
    require(address(nexusGateway).isContract(), "nexusGateway not a contract");

    AxelarGateway = axelarGateway;
    AxelarGasService = axelarGasService;
    NexusGateway = nexusGateway;
  }

  function sendPacketTo(
    uint16 targetChainId,
    bytes memory packetBytes
  ) external payable {
    if (msg.sender != address(NexusGateway)) {
      revert UnAuthorizedSender(address(NexusGateway), msg.sender);
    }

    (string memory chainName, string memory gatewayAddress) = resolveChainById(
      targetChainId
    );

    AxelarGateway.callContract(chainName, gatewayAddress, packetBytes);

    if (msg.value > 0) {
      AxelarGasService.payNativeGasForContractCall{value: msg.value}(
        address(this),
        chainName,
        gatewayAddress,
        packetBytes,
        tx.origin
      );
    }
  }

  function _execute(
    string memory sourceChain,
    string memory sourceAddress,
    bytes calldata payload
  ) internal override {
    (uint16 chainId, bytes32 gatewayAddressHash) = resolveChainByName(
      sourceChain
    );

    if (keccak256(bytes(sourceAddress)) != gatewayAddressHash) {
      revert UnAuthorizedSourceAddress();
    }

    NexusGateway.handlePacket(chainId, payload);
  }

  function _executeWithToken(
    string memory,
    string memory,
    bytes calldata,
    string memory,
    uint256
  ) internal pure override {
    revert CallWithTokenNotAllowed();
  }

  function addChain(
    uint16 chainId,
    string calldata chainName,
    string calldata gatewayAddress
  ) external onlyOwner {
    _addChain(chainId, chainName, gatewayAddress);
  }

  function removeChain(
    uint16 chainId,
    string calldata chainName
  ) external onlyOwner {
    _removeChain(chainId, chainName);
  }

  function updateChainName(
    uint16 chainId,
    string calldata chainName
  ) external onlyOwner {
    _updateChainName(chainId, chainName);
  }

  function updateChainGatewayAddress(
    uint16 chainId,
    string calldata gatewayAddress
  ) external onlyOwner {
    _updateChainGatewayAddress(chainId, gatewayAddress);
  }
}
