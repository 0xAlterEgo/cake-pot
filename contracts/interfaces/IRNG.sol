// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRNG {
    function generateRandomNumber(uint256 seed, address sender) external returns (uint256);
}