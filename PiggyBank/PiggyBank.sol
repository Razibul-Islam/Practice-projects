// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract PiggyBank {
    address public Owner;

    mapping(address => uint256) public accountHolders;

    constructor() {
        Owner = msg.sender;
    }

    receive() external payable {
        deposit();
    }

    fallback() external payable {
        deposit();
    }

    address[] public accounts;

    modifier onlyOwner() {
        require(msg.sender == Owner, "You are not the Owner");
        _;
    }

    function deposit() public payable {
        require(msg.value >= 1e13, "Minimum diposit 0.00001 ETH");
        accountHolders[msg.sender] += msg.value;
        accounts.push(msg.sender);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw() public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            accountHolders[account] = 0;
        }
        (bool success, ) = Owner.call{value: address(this).balance}("");
        require(success, "Transfer Faild");
    }
}
