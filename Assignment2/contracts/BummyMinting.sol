// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.17;
import './BummyOwnership.sol';

contract BummyMintng is BummyOwnership {
  uint256 public promoCreationLimit = 100;
  uint256 public promoCreatedCount;
  uint256 public gen0CreationLimit = 300;
  uint256 public gen0CreatedCount;

  mapping (address => bool) alreadyMinted;

  function createPromoBummy(uint256 _genes, address _owner) public onlyCOO returns(uint256) {
    if (_owner == address(0)) {
      _owner = cooAddress;
    }
    require(promoCreatedCount < promoCreationLimit);
    require(gen0CreatedCount < gen0CreationLimit);
    promoCreatedCount++;
    gen0CreatedCount++;
    _createBummy(0, 0, 0, _genes, bummyOwner);
  }

  function createFirstGen0Bummy() external returns(uint256){
    require(alreadyMinted[msg.sender] == false,"YOU ALREADY MINTED A BUMMY"");
    uint256 randNonce = 15;
    uint256 _genes = uint256(keccak256(abi.encodePacked(msg.sender,block.timestamp,randNonce)));
    uint256 newbummyId = _createBummy(0, 0, 0, _genes, msg.sender);
    alreadyMinted[msg.sender] = true;
    return newbummyId;
  }
}
