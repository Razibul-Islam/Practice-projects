// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TipJar {
    struct Tip {
        address sender;
        uint256 amount;
        string message;
    }
    address private owner;

    Tip[] messages;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "You are not the owner");
        _;
    }

    function tip(string calldata message) public payable {
        messages.push(Tip(msg.sender, msg.value, message));
    }

    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function getAllTips() public view returns(Tip[] memory) {
        return messages;
    }
}
