//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

  error UnchangedConfiguration();
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
  error RemoveMismatch(uint16 chain, string chainName);

  event ChainAdded(
    uint16 indexed chain,
    string chainName,
    string gatewayAddress
  );
  event ChainRemoved(uint16 indexed chain);
  event ChainNameUpdated(
    uint16 indexed chain,
    string previousChainName,
    string currentChainName
  );
  event ChainGatewayAddressUpdated(
    uint16 indexed chain,
    string previousGatewayAddress,
    string currentGatewayAddress
  );

  mapping(uint16 => ChainNameRecord) chainRecords;
  mapping(string => ChainRecord) chains;

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

  function _removeChain(uint16 chainId, string calldata chainName) internal {
    if (!chainRecords[chainId].isConfigured) {
      revert InvalidChainId(chainId);
    }
    if (!chains[chainName].isConfigured) {
      revert InvalidChainName(chainName);
    }

    if (chains[chainName].chainId != chainId) {
      revert RemoveMismatch(chainId, chainName);
    }
    if (
      keccak256(bytes(chainRecords[chainId].chainName)) !=
      keccak256(bytes(chainName))
    ) {
      revert RemoveMismatch(chainId, chainName);
    }

    delete (chains[chainRecords[chainId].chainName]);
    delete (chainRecords[chainId]);

    emit ChainRemoved(chainId);
  }

  function _updateChainName(
    uint16 chainId,
    string calldata chainName
  ) internal {
    if (!chainRecords[chainId].isConfigured) {
      revert InvalidChainId(chainId);
    }
    if (chains[chainName].isConfigured) {
      revert ChainNameAlreadyConfigured(
        chainName,
        chains[chainName].chainId,
        chainId
      );
    }

    emit ChainNameUpdated(chainId, chainRecords[chainId].chainName, chainName);

    delete (chains[chainRecords[chainId].chainName]);

    chainRecords[chainId].chainName = chainName;
    chains[chainName] = ChainRecord({isConfigured: true, chainId: chainId});
  }

  function _updateChainGatewayAddress(
    uint16 chainId,
    string calldata gatewayAddress
  ) internal {
    if (!chainRecords[chainId].isConfigured) {
      revert InvalidChainId(chainId);
    }

    bytes32 gatewayAddressHash = keccak256(bytes(gatewayAddress));

    if (chainRecords[chainId].gatewayAddressHash == gatewayAddressHash) {
      revert UnchangedConfiguration();
    }

    emit ChainGatewayAddressUpdated(
      chainId,
      chainRecords[chainId].gatewayAddress,
      gatewayAddress
    );

    chainRecords[chainId].gatewayAddress = gatewayAddress;
    chainRecords[chainId].gatewayAddressHash = gatewayAddressHash;
  }
}
