// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.17;
import './BummyBase.sol';

contract BummyOwnership is BummyBase {
  function _owns(
    address _claimant,
    uint256 _tokenId
  ) internal view returns (bool) {
    require(_tokenId>0, "Token ID must be greater than 0");
    return ERC721._owners[_tokenId] == _claimant;
  }

  function rescueLostBummy(
    uint256 _bummyId,
    address _recipient
  ) external onlyCOO whenNotPaused {
    require(_owns(address(this), _bummyId));
    _transfer(address(this), _recipient, _bummyId);
  }
}
