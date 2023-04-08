// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.17;
import './BummyAccessControl.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';

contract BummyBase is BummyAccesControl, ERC721Enumerable {
    

  constructor() ERC721("Bummy","BV") {}


  struct Bummy {
    // 버미 유전자
    uint256 genes;
    // 버미가 생겨난 시간
    uint64 birthTime;
    // 교배후 자식 키티가 민팅이 가능해지는 시각, 다음 교배가 가능해지는 시각
    uint64 cooldownEndTime;
    uint32 MomId;
    uint32 DadId;
    // 교배 중인 BummyId
    uint32 cheeringWithId;
    //교배시 1씩 증가하며 교배 쿨타임 기간 증가
    uint8 cooldownIndex;
    //자식 수
    uint8 children;
    // 세대수, 이 값은 부모의 세대에 의해 아래와 같이 결정
    // max(mom.generation, dad.generation) + 1
    uint16 generation;
  }

  uint32[8] public cooldowns = [
    uint32(1 minutes),
    uint32(2 minutes),
    uint32(5 minutes),
    uint32(10 minutes),
    uint32(30 minutes),
    uint32(1 hours),
    uint32(2 hours),
    uint32(4 hours)
  ];
  mapping(uint256 => address) public cheerAllowedToAddress;

  Bummy[] bummies;

  event Birth(
    address indexed owner,
    uint256 bummyId,
    uint256 momId,
    uint256 dadId,
    uint256 genes
  );

  function _createBummy(
    uint256 _momId,
    uint256 _dadId,
    uint256 _generation,
    uint256 _genes,
    address _owner
  ) internal returns (uint) {
    require(_momId <= 2 ** 32 - 1, 'Mom Id is too big');
    require(_dadId <= 2 ** 32 - 1, 'Dad Id is too big');
    require(_generation <= 2 ** 16 - 1, 'Generation is too big');
  
    Bummy memory _bummy = Bummy(  {
      genes: _genes,
      birthTime: uint64(block.timestamp),
        cooldownEndTime: 0,
      MomId: uint32(_momId),
       DadId: uint32(_dadId),
      cheeringWithId: 0,
      cooldownIndex: 0,
      children: 0,
      generation: uint16(_generation)
    });

    bummies.push(_bummy);
    uint256 newBummyId = bummies.length - 1;
    require(newBummyId <= 2 ** 32 - 1, 'Bummy Id is too big');
    emit Birth(_owner, uint256(newBummyId), uint256(_momId), _dadId, _genes);

    _safeMint(_owner, newBummyId);
    return newBummyId;
  }

  
}
