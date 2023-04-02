// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.17;
import './BummyMinting.sol';

contract BummyCore is BummyMinting {
  address public newContractAddress;

  constructor() {
    _pause();
    ceoAddress = msg.sender;
    cfoAddress = msg.sender;
    cooAddress = msg.sender;
    _createBummy(0, 0, 0, uint256(-1), msg.sender);
  }

  function setNewAddress(address _v2Addres) public onlyCEO whenPaused {
    newContractAddress = _v2Addres;
    emit ContractUpgrade(_v2Addres);
  }

  function getBummy(
    uint256 _bummyId
  )
    public
    view
    returns (
      bool isExhausted,
      bool isReady,
      uint256 cooldownIndex,
      uint256 nextActionAt,
      uint256 cheeringWithId,
      uint256 birthTime,
      uint256 momId,
      uint256 dadId,
      uint256 generation,
      uint256 genes
    )
  {
    Bummy storage bum = bummies[_id];
    // 값을 변경하지 않아서 memory를 써도 문제가 없어보여서 가스비 줄이는 측면에서 memory가 적절할 것 같다.

    // if this variable is 0 then it's not gestating
    isExhausted = (bum.cheeringWithId != 0);
    isReady = (bum.cooldownEndTime <= block.timestamp);
    cooldownIndex = uint256(bum.cooldownIndex);
    nextActionAt = uint256(bum.cooldownEndTime);
    cheeringWithId = uint256(bum.cheeringWithId);
    birthTime = uint256(bum.birthTime);
    momId = uint256(bum.MomId);
    dadId = uint256(bum.DadId);
    generation = uint256(bum.generation);
    genes = bum.genes;
  }
}
