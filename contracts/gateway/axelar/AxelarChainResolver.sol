//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract AxelarChainResolver {
  struct ChainNameRecord {
    bool isConfigured;
    string chainName;
    bytes32 gatewayAddressHash;
    string gatewayAddress;
  }
  struct ChainRecord {
    bool isConfigured;
    uint16 chainId;
  }

  error InvalidChainId(uint16 chainId);
  error InvalidChainName(string chainName);
  error ChainIdAlreadyConfigured(
    uint16 chainId,
    string currentName,
    string proposedName
  );
  error ChainNameAlreadyConfigured(
    string chainName,
    uint16 currentChain,
    uint16 proposedChain
  );

  event ChainAdded(
    uint16 indexed chain,
    string chainName,
    string gatewayAddress
  );

  mapping(uint16 => ChainNameRecord) public chainRecords;
  mapping(string => ChainRecord) public chains;

  function resolveChainById(
    uint16 chainId
  )
    public
    view
    returns (string memory chainName, string memory gatewayAddress)
  {
    if (!chainRecords[chainId].isConfigured) {
      revert InvalidChainId(chainId);
    }

    return (
      chainRecords[chainId].chainName,
      chainRecords[chainId].gatewayAddress
    );
  }

  function resolveChainByName(
    string memory chainName
  ) public view returns (uint16 chainId, bytes32 gatewayAddressHash) {
    if (!chains[chainName].isConfigured) {
      revert InvalidChainName(chainName);
    }

    chainId = chains[chainName].chainId;
    gatewayAddressHash = chainRecords[chainId].gatewayAddressHash;
  }

  function _addChain(
    uint16 chainId,
    string calldata chainName,
    string calldata gatewayAddress
  ) internal {
    if (chainRecords[chainId].isConfigured) {
      revert ChainIdAlreadyConfigured(
        chainId,
        chainRecords[chainId].chainName,
        chainName
      );
    }
    if (chains[chainName].isConfigured) {
      revert ChainNameAlreadyConfigured(
        chainName,
        chains[chainName].chainId,
        chainId
      );
    }

    bytes32 gatewayAddressHash = keccak256(bytes(gatewayAddress));

    chainRecords[chainId] = ChainNameRecord({
      isConfigured: true,
      chainName: chainName,
      gatewayAddress: gatewayAddress,
      gatewayAddressHash: gatewayAddressHash
    });
    chains[chainName] = ChainRecord({isConfigured: true, chainId: chainId});

    emit ChainAdded(chainId, chainName, gatewayAddress);
  }
}
