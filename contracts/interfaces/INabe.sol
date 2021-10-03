// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IFungibleToken.sol";

interface INabe is IFungibleToken {
    function mint(address to, uint256 amount) external;
    function burn(uint256 id) external;
}