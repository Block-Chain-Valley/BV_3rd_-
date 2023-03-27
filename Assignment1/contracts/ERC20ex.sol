// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import './Context.sol';
import './IERC20.sol';
import './IERC20Metadata.sol';

contract MyToken is Context, IERC20,IERC20Metadata{
    mapping (address => uint256) private _balances; // owner -> 토큰 수량
    mapping (address => mapping (address => uint256)) private _allowances; // owner ->(spender->권한넘겨준 토큰 수량)
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_){
        _name=name_;
        _symbol=symbol_;
    }

    function name() public view virtual override returns(string memory){
        return _name;
    }

    function symbol() public view virtual override returns(string memory){
        return _symbol;
    }

    function decimals() public pure virtual override returns(uint8){
        return 18;
    }


    function totalSupply() external view returns(uint256){
        return _totalSupply;
    }

    function balanceOf(address account) external view returns(uint256){
        return _balances[account];
    }



    function _tranfer(address from, address to, uint256 amount) internal virtual{
        // 유효한 지갑인지 확인 
        require((from !=address(0) && to !=address(0)), "Check the account. There is an not valid account !!");
        // 보내는 사람의 잔고가 충분한지 확인
        uint256 sender_balance = _balances[from];
        require(sender_balance>=amount, "Not Enough Balance to Send !");
        // 보내는 이와 받는 이의 잔고를 바꿔서 거래를 성사
        unchecked{
        _balances[from]-=amount;
        _balances[to]+=amount;
        }
        // transfer가 일어났다고 emit
        emit Transfer(from,to,amount);
    }

    function transfer(address to, uint256 amount) external virtual override returns(bool){
       address sender=_msgSender();
       _tranfer(sender,to,amount);
       return true;
    }

    function transferFrom(address from, address to, uint256 amount) external virtual override returns (bool){
        address spender = _msgSender();
        _spendAllowance(from,spender,amount);
        _tranfer(from,to,amount);
        return true;
    }

    // account 에게 amount 만큼의 토큰을 민팅
    function _mint(address account,uint256 amount) internal virtual {
        require(account != address(0), "Check the account!");
        _totalSupply+=amount;
        unchecked{
            _balances[account]+=amount;
        }
        emit Transfer(address(0),account,amount);
    }

    function _burn(address account, uint256 amount) internal virtual{
        require(account!=address(0), "Check the account!");
        uint256 sender_balance= _balances[account];
        require(sender_balance>=amount,"Not Enough Token!");
        unchecked{
            _balances[account]-=amount;
            _totalSupply-=amount;
        }
        emit Transfer(account,address(0),amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual{
        require(owner!=address(0) && spender!=address(0),"Check the account");
        _allowances[owner][spender]=amount;
        emit Approval(owner,spender,amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual{
        require(owner!=address(0) && spender!=address(0),"Check the account");
        uint256 approvedAmount=_allowances[owner][spender];
        require(approvedAmount>=amount,"Not Enough allowance");
        unchecked{
            _approve(owner,spender,approvedAmount-amount);
        }
    }


    function approve(address spender, uint256 amount) external virtual override returns (bool){
        address owner = _msgSender();
        _approve(owner,spender,amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256){
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns(bool){
        address owner = _msgSender();
        unchecked{
            _approve(owner, spender, allowance(owner, spender) + addedValue);
        }
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns(bool){
        address owner = _msgSender();
        uint256 approvedAmount = allowance(owner,spender);
        require(approvedAmount>=subtractedValue,"Not Enough Allowance");
        unchecked{
            _approve(owner,spender,approvedAmount-subtractedValue);
        }
        return true;
    }
}