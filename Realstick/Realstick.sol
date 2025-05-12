// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Realstick {
    string public name = "RealstickToken";
    string public symbol = "RST";
    uint256 private initialSupply = 1000000;
    address private owner;
    address private feeCollector;
    uint256 private parcentages;
    bool private pause;

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    modifier pausedToken() {
        require(!pause, "Token Is Frezz now, You can't transfer Token");
        _;
    }

    modifier isBlackList(address addr) {
        require(!blacklist[addr], "You are in blocklist");
        _;
    }

    mapping(address => uint256) private balances;
    mapping(address => bool) private blacklist;

    event updateFeeCollector(address indexed prevColl, address indexed newColl);

    constructor() {
        owner = msg.sender;
        feeCollector = msg.sender;
        balances[owner] = initialSupply;
    }

    function paused() public {
        pause = true;
    }

    function unPaused() public {
        pause = false;
    }

    function addFeeCollector(address addr) public onlyOwner returns (bool) {
        require(addr != address(0), "Invalid Address");
        address prevColl = feeCollector;
        feeCollector = addr;
        emit updateFeeCollector(prevColl, addr);
        return true;
    }

    function setParcentage(uint256 parcentage) public onlyOwner returns (bool) {
        require(parcentage <=100, "Not Valid");
        parcentages = parcentage;
        return true;
    }

    function addBlacklist(address addr) public onlyOwner {
        blacklist[addr] = true;
    }

    function removeBlacklist(address addr) public onlyOwner {
        blacklist[addr] = false;
    }

    function transfer(address to, uint256 amount)
        public
        pausedToken
        isBlackList(to)
        returns (bool)
    {
        require(to != address(0), "Invalid Address");
        require(amount > 0, "Amount must be grater then 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        if (
            msg.sender == owner ||
            msg.sender == feeCollector ||
            to == owner ||
            to == feeCollector
        ) {
            balances[msg.sender] -= amount;
            balances[to] += amount;
            return true;
        }else{
        balances[msg.sender] -= amount;
        uint256 parcentAmount = (amount * parcentages) / 100;
        uint256 amountAfterFee = amount - parcentAmount;

        balances[feeCollector] += parcentAmount;
        balances[to] += amountAfterFee;
        return true;
        }

    }
}
