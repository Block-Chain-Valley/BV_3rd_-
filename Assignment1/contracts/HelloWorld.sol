// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract HelloWorld is ERC20 {
    address owner;
    
    constructor(string memory _name,string memory _symbol,uint256 initialSupply ) ERC20(_name,_symbol){
        owner = msg.sender; 
        _mint(msg.sender,initialSupply);
    }

    uint num = 0;

    function add () public {
        num++;
    }
  

}