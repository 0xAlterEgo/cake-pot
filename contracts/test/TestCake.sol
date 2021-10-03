// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestCake is ERC20 {

    constructor() ERC20("PancakeSwap Token", "Cake") {}

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}
