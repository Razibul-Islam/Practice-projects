// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Voting {
    struct VoteDetails {
        uint256 id;
        string name;
        uint256 voteCount;
    }

    address public owner;

    mapping(address => VoteDetails) public candidates;

    constructor() {
        owner = msg.sender;
    }

    function AddCandidate(uint256 _id, string memory _name) public {
        candidates[msg.sender] = VoteDetails(_id, _name, 0);
    }
}
