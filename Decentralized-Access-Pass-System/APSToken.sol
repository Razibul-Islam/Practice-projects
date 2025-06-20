// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract APSToken is ERC20 {
    constructor() ERC20("APS Token", "APS") {
        _mint(msg.sender, 1000000 * 10**18);
    }
    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}