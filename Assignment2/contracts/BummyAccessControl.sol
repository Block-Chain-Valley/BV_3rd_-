// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.17;

contract BummyAccessControl is Pausable {
  address public ceoAddress;
  address public cfoAddress;
  address public cooAddress;

  event ContractUpgrade(address newContract);

  modifier onlyCEO() {
    require(msg.sender == ceoAddress, 'Only CEO can call this function.');
    _;
  }

  modifier onlyCFO() {
    require(msg.sender == cfoAddress, 'Only CFO can call this function.');
    _;
  }

  modifier onlyCOO() {
    require(msg.sender == cooAddress, 'Only COO can call this function.');
    _;
  }

  modifier onlyCLevel() {
    require(
      msg.sender == cooAddress ||
        msg.sender == ceoAddress ||
        msg.sender == cfoAddress,
      'Only C-level can call this function.'
    );
    _;
  }

  function setCEO(address _newCEO) public onlyCEO {
    require(_newCEO != address(0));
    ceoAddress = _newCEO;
  }

  function setCFO(address _newCFO) public onlyCEO {
    require(_newCFO != address(0));
    cfoAddress = _newCFO;
  }

  function setCOO(address _newCOO) public onlyCEO {
    require(_newCOO != address(0));
    cooAddress = _newCOO;
  }

  function pause() public onlyCLevel {
    _pause();
  }

  function unpause() public onlyCEO whenPaused {
    _unpause();
  }
}
