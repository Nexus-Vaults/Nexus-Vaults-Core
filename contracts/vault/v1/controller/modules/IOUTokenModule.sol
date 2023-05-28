//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {V1TokenTypes} from '../../V1TokenTypes.sol';

import {IOUToken} from '../../../../iou/IOUToken.sol';

struct IOUTokenRecord {
  bool isDefined;
  uint16 vaultChainId;
  bytes32 nexusId;
  uint32 vaultId;
  address gateway;
  V1TokenTypes tokenType;
  string tokenIdentifier;
}

abstract contract IOUTokenModule {
  mapping(address => IOUTokenRecord) public tokenToRecord;
  mapping(bytes32 => IOUToken) public recordToToken;

  function _makeTokenId(
    uint16 vaultChainId,
    bytes32 nexusId,
    uint32 vaultId,
    address gatewayAddress,
    V1TokenTypes tokenType,
    string memory tokenIdentifier
  ) private pure returns (bytes32 tokenId) {
    return
      keccak256(
        abi.encodePacked(
          vaultChainId,
          nexusId,
          vaultId,
          gatewayAddress,
          tokenType,
          tokenIdentifier
        )
      );
  }

  function _deployIOU(
    string memory name,
    string memory symbol,
    uint16 vaultChainId,
    bytes32 nexusId,
    uint32 vaultId,
    address gatewayAddress,
    V1TokenTypes tokenType,
    string memory tokenIdentifier
  ) private returns (IOUToken) {
    bytes32 tokenId = _makeTokenId(
      vaultChainId,
      nexusId,
      vaultId,
      gatewayAddress,
      tokenType,
      tokenIdentifier
    );

    IOUToken token = new IOUToken{salt: tokenId}(name, symbol);

    recordToToken[tokenId] = token;
    tokenToRecord[address(token)] = IOUTokenRecord({
      isDefined: true,
      vaultChainId: vaultChainId,
      nexusId: nexusId,
      vaultId: vaultId,
      gateway: gatewayAddress,
      tokenType: tokenType,
      tokenIdentifier: tokenIdentifier
    });

    return token;
  }

  function _isIOUToken(address tokenAddress) internal view returns (bool) {
    return tokenToRecord[tokenAddress].isDefined;
  }

  function _mintIOU(
    uint16 vaultChainId,
    bytes32 nexusId,
    uint32 vaultId,
    address gatewayAddress,
    V1TokenTypes tokenType,
    string memory tokenIdentifier,
    address receiver,
    uint256 amount
  ) internal {
    bytes32 tokenId = _makeTokenId(
      vaultChainId,
      nexusId,
      vaultId,
      gatewayAddress,
      tokenType,
      tokenIdentifier
    );

    IOUToken token = recordToToken[tokenId];

    if (address(token) == address(0)) {
      token = _deployIOU(
        tokenIdentifier,
        tokenIdentifier,
        vaultChainId,
        nexusId,
        vaultId,
        gatewayAddress,
        tokenType,
        tokenIdentifier
      );
    }

    token.mint(receiver, amount);
  }

  function _burnIOU(
    uint16 vaultChainId,
    bytes32 nexusId,
    uint32 vaultId,
    address gatewayAddress,
    V1TokenTypes tokenType,
    string memory tokenIdentifier,
    address from,
    uint256 amount
  ) internal {
    bytes32 tokenId = _makeTokenId(
      vaultChainId,
      nexusId,
      vaultId,
      gatewayAddress,
      tokenType,
      tokenIdentifier
    );

    IOUToken token = recordToToken[tokenId];

    if (address(token) == address(0)) {
      token = _deployIOU(
        tokenIdentifier,
        tokenIdentifier,
        vaultChainId,
        nexusId,
        vaultId,
        gatewayAddress,
        tokenType,
        tokenIdentifier
      );
    }

    token.burn(from, amount);
  }
}
