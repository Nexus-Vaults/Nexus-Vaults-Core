//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

contract SimpleERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
  error Unsupported();

  mapping(uint256 => mapping(address => uint256)) private _balances;
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
  string private _uri;

  constructor(string memory uri_) {
    _setURI(uri_);
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC165, IERC165) returns (bool) {
    return
      interfaceId == type(IERC1155).interfaceId ||
      interfaceId == type(IERC1155MetadataURI).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function uri(
    uint256
  ) public view virtual override returns (string memory) {
    return _uri;
  }

  function balanceOf(
    address account,
    uint256 id
  ) public view virtual override returns (uint256) {
    require(
      account != address(0),
      'ERC1155: address zero is not a valid owner'
    );
    return _balances[id][account];
  }

  function balanceOfBatch(
    address[] memory accounts,
    uint256[] memory ids
  ) public view virtual override returns (uint256[] memory) {
    require(
      accounts.length == ids.length,
      'ERC1155: accounts and ids length mismatch'
    );

    uint256[] memory batchBalances = new uint256[](accounts.length);

    for (uint256 i = 0; i < accounts.length; ++i) {
      batchBalances[i] = balanceOf(accounts[i], ids[i]);
    }

    return batchBalances;
  }

  function setApprovalForAll(address, bool) public pure override {
    revert Unsupported();
  }

  function isApprovedForAll(
    address,
    address
  ) public pure override returns (bool) {
    revert Unsupported();
  }

  function safeTransferFrom(
    address,
    address,
    uint256,
    uint256,
    bytes memory
  ) public pure override {
    revert Unsupported();
  }

  function safeBatchTransferFrom(
    address,
    address,
    uint256[] memory,
    uint256[] memory,
    bytes memory
  ) public pure override {
    revert Unsupported();
  }

  function _setURI(string memory newuri) internal virtual {
    _uri = newuri;
  }

  function _mint(
    address to,
    uint256 id,
    uint256 amount,
    bytes memory
  ) internal {
    require(to != address(0), 'ERC1155: mint to the zero address');

    address operator = _msgSender();

    _balances[id][to] += amount;
    emit TransferSingle(operator, address(0), to, id, amount);
  }
}
