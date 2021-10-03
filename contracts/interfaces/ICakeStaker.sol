// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICakeStaker {
    function enterStaking(uint256 amount) external;
    function leaveStaking(uint256 amount) external;
    function pendingCake(uint256 pid, address user) external view returns (uint256);
    function userInfo(uint256 pid, address user) view external returns(uint256 amount, uint256 rewardDebt);
}
