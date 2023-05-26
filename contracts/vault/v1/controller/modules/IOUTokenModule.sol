//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IOUToken} from '../../../../iou/IOUToken.sol';

struct IOUTokenRecord {
  bool isDefined;
  uint16 vaultChainId;
  uint32 vaultId;
  address gateway;
  string asset;
}

abstract contract IOUTokenModule {
  mapping(address => IOUTokenRecord) public tokenToRecord;
  mapping(bytes32 => IOUToken) public recordToToken;

  function _makeTokenId(
    uint16 vaultChainId,
    uint32 vaultId,
    address gatewayAddress,
    string memory asset
  ) private pure returns (bytes32 tokenId) {
    return keccak256(abi.encodePacked(vaultChainId, vaultId, gatewayAddress, asset));
  }

  function _deployIOU(
    string memory name,
    string memory symbol,
    uint16 vaultChainId,
    uint32 vaultId,
    address gatewayAddress,
    string memory asset
  ) private returns (IOUToken) {
    bytes32 tokenId = _makeTokenId(vaultChainId, vaultId, gatewayAddress, asset);

    IOUToken token = new IOUToken{salt: tokenId}(name, symbol);

    recordToToken[tokenId] = token;
    tokenToRecord[address(token)] = IOUTokenRecord({
      isDefined: true,
      vaultChainId: vaultChainId,
      vaultId: vaultId,
      gateway: gatewayAddress,
      asset: asset
    });

    return token;
  }

  function _isIOUToken(address tokenAddress) internal view returns (bool) {
    return tokenToRecord[tokenAddress].isDefined;
  }

  function _mintIOU(
    uint16 vaultChainId,
    uint32 vaultId,
    address gatewayAddress,
    string calldata asset,
    address receiver,
    uint256 amount
  ) internal {
    bytes32 tokenId = _makeTokenId(vaultChainId, vaultId, gatewayAddress, asset);

    IOUToken token = recordToToken[tokenId];

    if (address(token) == address(0)) {
      token = _deployIOU(asset, asset, vaultChainId, vaultId, gatewayAddress, asset);
    }

    token.mint(receiver, amount);
  }

  function _burnIOU(
    uint16 vaultChainId,
    uint32 vaultId,
    address gatewayAddress,
    string calldata asset,
    address from,
    uint256 amount
  ) internal {
    bytes32 tokenId = _makeTokenId(vaultChainId, vaultId, gatewayAddress, asset);

    IOUToken token = recordToToken[tokenId];

    if (address(token) == address(0)) {
      token = _deployIOU(asset, asset, vaultChainId, vaultId, gatewayAddress, asset);
    }

    token.burn(from, amount);
  }
}
