// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract TimeSave is ERC20, Ownable, Pausable {
    uint256 private deployTime;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 initialSupply,
        address initialOwner
    ) ERC20(_name, _symbol) Ownable(initialOwner) {
        _mint(msg.sender, initialSupply * 10**decimals());
        deployTime = block.timestamp;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unPause() public onlyOwner {
        _unpause();
    }

    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(msg.sender, amount);
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }
}


// 0x4f28291c6ada914c000075ba5181e067fe79b35d