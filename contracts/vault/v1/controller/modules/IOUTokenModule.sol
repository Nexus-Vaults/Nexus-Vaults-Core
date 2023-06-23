//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {V1TokenTypes} from '../../types/V1TokenTypes.sol';

import {IOUToken} from '../../../../iou/IOUToken.sol';
import {V1Payment} from '../../types/V1Payment.sol';

struct IOUTokenRecord {
  bool isDefined;
  uint16 vaultChainId;
  uint32 gatewayId;
  bytes32 nexusId;
  uint32 vaultId;
  V1TokenTypes tokenType;
  string tokenIdentifier;
}

abstract contract IOUTokenModule {
  mapping(address => IOUTokenRecord) public tokenToRecord;
  mapping(bytes32 => IOUToken) public recordToToken;

  function _makeTokenId(
    uint16 vaultChainId,
    uint32 gatewayId,
    bytes32 nexusId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string memory tokenIdentifier
  ) private pure returns (bytes32 tokenId) {
    return
      keccak256(
        abi.encodePacked(
          vaultChainId,
          gatewayId,
          nexusId,
          vaultId,
          tokenType,
          tokenIdentifier
        )
      );
  }

  function _deployIOU(
    string memory name,
    string memory symbol,
    uint16 vaultChainId,
    uint32 gatewayId,
    bytes32 nexusId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string memory tokenIdentifier
  ) private returns (IOUToken) {
    bytes32 tokenId = _makeTokenId(
      vaultChainId,
      gatewayId,
      nexusId,
      vaultId,
      tokenType,
      tokenIdentifier
    );

    IOUToken token = new IOUToken{salt: tokenId}(name, symbol);

    recordToToken[tokenId] = token;
    tokenToRecord[address(token)] = IOUTokenRecord({
      isDefined: true,
      vaultChainId: vaultChainId,
      gatewayId: gatewayId,
      nexusId: nexusId,
      vaultId: vaultId,
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
    uint32 gatewayId,
    bytes32 nexusId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string memory tokenIdentifier,
    address receiver,
    uint256 amount
  ) internal {
    bytes32 tokenId = _makeTokenId(
      vaultChainId,
      gatewayId,
      nexusId,
      vaultId,
      tokenType,
      tokenIdentifier
    );

    IOUToken token = recordToToken[tokenId];

    if (address(token) == address(0)) {
      token = _deployIOU(
        tokenIdentifier,
        tokenIdentifier,
        vaultChainId,
        gatewayId,
        nexusId,
        vaultId,
        tokenType,
        tokenIdentifier
      );
    }

    token.mint(receiver, amount);
  }

  function _batchMintIOU(
    uint16 vaultChainId,
    uint32 gatewayId,
    bytes32 nexusId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string memory tokenIdentifier,
    V1Payment[] memory payments
  ) internal {
    bytes32 tokenId = _makeTokenId(
      vaultChainId,
      gatewayId,
      nexusId,
      vaultId,
      tokenType,
      tokenIdentifier
    );

    IOUToken token = recordToToken[tokenId];

    if (address(token) == address(0)) {
      token = _deployIOU(
        tokenIdentifier,
        tokenIdentifier,
        vaultChainId,
        gatewayId,
        nexusId,
        vaultId,
        tokenType,
        tokenIdentifier
      );
    }

    token.batchMint(payments);
  }

  function _burnIOU(
    uint16 vaultChainId,
    uint32 gatewayId,
    bytes32 nexusId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string memory tokenIdentifier,
    address from,
    uint256 amount
  ) internal {
    bytes32 tokenId = _makeTokenId(
      vaultChainId,
      gatewayId,
      nexusId,
      vaultId,
      tokenType,
      tokenIdentifier
    );

    IOUToken token = recordToToken[tokenId];

    if (address(token) == address(0)) {
      token = _deployIOU(
        tokenIdentifier,
        tokenIdentifier,
        vaultChainId,
        gatewayId,
        nexusId,
        vaultId,
        tokenType,
        tokenIdentifier
      );
    }

    token.burn(from, amount);
  }
}
