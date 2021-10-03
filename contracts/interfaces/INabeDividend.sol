// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface INabeDividend {

    event Distribute(address indexed by, uint256 distributed);
    event Claim(address indexed to, uint256 claimed);

    function pid() external view returns (uint256);
    function shares(address owner) external view returns (uint256);

    function accumulativeOf(address owner) external view returns (uint256);
    function claimedOf(address owner) external view returns (uint256);
    function claimableOf(address owner) external view returns (uint256);
    function claim() external returns (uint256);
}