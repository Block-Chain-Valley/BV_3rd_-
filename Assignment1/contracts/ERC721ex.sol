// SPDX-License-Identifier:MIT
pragma solidity ^0.8.17;

import './IERC721.sol';
import './ERC165.sol';
import './IERC721Metadata.sol';
import './Context.sol';
import './IERC721Receiver.sol';
import './Address.sol';
import './Strings.sol';

contract ERC721ex is Context, IERC721, ERC165, IERC721Metadata {
  using Address for address;
  using Strings for uint256;

  string private _name;
  string private _symbol;
  mapping(uint256 => address) private _owners;
  mapping(address => uint256) private _balances;
  mapping(uint256 => address) private _tokenApprovals;
  //owner -> (operator->bool)
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
  }

  function name() public view virtual override returns (string memory) {
    return _name;
  }

  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC165, IERC165) returns (bool) {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  

  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) private returns (bool) {
    if (to.isContract()) {
      try
        IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data)
      returns (bytes4 retval) {
        return retval == IERC721Receiver.onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert('ERC721: transfer to non ERC721Receiver implementer');
        } else {
          /// @solidity memory-safe-assembly
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  }

  function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
    return _owners[tokenId];
  }

  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return _ownerOf(tokenId) != address(0);
  }

  function _requireMinted(uint256 tokenId) internal view virtual {
    require(_exists(tokenId), 'Invalid token ID');
  }

  function _baseURI() internal view virtual returns (string memory) {
    return '';
  }

  function tokenURI(
    uint256 tokenId
  ) public view virtual override returns (string memory) {
    _requireMinted(tokenId);

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : '';
  }

  function balanceOf(
    address owner
  ) public view virtual override returns (uint256) {
    return _balances[owner];
  }

  function ownerOf(
    uint256 tokenId
  ) public view virtual override returns (address) {
    address owner = _ownerOf(tokenId);
    require(owner != address(0), 'Not minted token');
    return owner;
  }

  function _mint(address to, uint256 tokenId) internal virtual {
    require(to != address(0), 'Not an Valid Address');
    require(!_exists(tokenId), 'token is already minted');
    unchecked {
      _balances[to] += 1;
    }
    _owners[tokenId] = to;
    emit Transfer(address(0), to, tokenId);
  }

  function _safeMint(
    address to,
    uint256 tokenId,
    bytes memory data
  ) internal virtual {
    _mint(to, tokenId);
    require(
      _checkOnERC721Received(address(0), to, tokenId, data),
      'The Contract has no ERC721Receiver'
    );
  }

  function _burn(uint256 tokenId) internal virtual {
    address owner = ownerOf(tokenId);
    _beforeTokenTransfer(owner, address(0), tokenId, 1);
    delete _tokenApprovals[tokenId];
    delete _owners[tokenId];
    unchecked {
      _balances[owner] -= 1;
    }
    emit Transfer(owner, address(0), tokenId);
    _afterTokenTransfer(owner, address(0), tokenId, 1);
  }

  function _approve(address to, uint256 tokenId) internal virtual {
    _tokenApprovals[tokenId] = to;
    emit Approval(ownerOf(tokenId), to, tokenId);
  }

  function _setApprovalForAll(
    address owner,
    address operator,
    bool approved
  ) internal virtual {
    _operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  function approve(address to, uint256 tokenId) public virtual override {
    address owner = ownerOf(tokenId);
    require(to != address(0), 'Invalid Account');
    require(to != owner);
    require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()));
    _approve(to, tokenId);
  }

  function getApproved(
    uint256 tokenId
  ) public view virtual override returns (address) {
    _requireMinted(tokenId);
    return _tokenApprovals[tokenId];
  }

  function setApprovalForAll(
    address operator,
    bool approved
  ) public virtual override {
    _setApprovalForAll(_msgSender(), operator, approved);
  }

  function isApprovedForAll(
    address owner,
    address operator
  ) public view virtual override returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    require(from != address(0) && to != address(0), 'Invalid Account!');
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      'Caller is not approved'
    );
    _transfer(from, to, tokenId);
  }

  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {
    require(from != address(0) && to != address(0), 'Check the Address!');
    require(ownerOf(tokenId) == from, 'Incorrect Owner');
    _beforeTokenTransfer(from, to, tokenId, 1);
    delete _tokenApprovals[tokenId];
    unchecked {
      _balances[from] -= 1;
      _balances[to] += 1;
    }
    _owners[tokenId] = to;
    emit Transfer(from, to, tokenId);
    _afterTokenTransfer(from, to, tokenId, 1);
  }

  function _safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) internal virtual {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, data),
      'Contract have no ERC721Receiver'
    );
  }

  function _isApprovedOrOwner(
    address spender,
    uint256 tokenId
  ) internal view virtual returns (bool) {
    address owner = ownerOf(tokenId);
    return (owner == spender ||
      spender == getApproved(tokenId) ||
      isApprovedForAll(owner, spender));
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 firstTokenId,
    uint256 batchSize
  ) internal virtual {}

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 firstTokenId,
    uint256 batchSize
  ) internal virtual {}

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external override {
    safeTransferFrom(from, to, tokenId, '');
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public virtual override {
    require(from != address(0) && to != address(0), 'Invalid Account!');
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      'Caller is not approved'
    );
    _safeTransfer(from, to, tokenId, data);
  }
}
