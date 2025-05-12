// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract SimpleToken{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowances;

    event Transfer(address indexed from,address indexed to, uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);

    constructor(string memory _name,string memory _symbol,uint8 _decimals,uint256 _initialSupply){
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initialSupply *(10 ** decimals);
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function balanceOf(address owner) public view returns(uint256){
        return balances[owner];
    }

    function transfer(address to,uint256 value) public returns(bool){
        require(address(0) != to,"Invalid recipient");
        require(balances[msg.sender] >= value,"Insufficient Balance");

        balances[msg.sender] -= value;
        balances[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns(bool){
        allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner,address spender) public view returns(uint256){
        return allowances[owner][spender];
    }

    function transferFrom(address from,address to,uint256 value) public returns(bool){
        require(from != address(0),"Invalid Address");
        require(to != address(0),"Invalid recipient");
        require(balances[from] >= value,"Insufficient Balance");
        require(allowances[from][msg.sender] >= value, "Insufficient Allowance");

        balances[from] -= value;
        balances[to] += value;
        allowances[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
}
