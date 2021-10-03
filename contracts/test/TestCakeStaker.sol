// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "../interfaces/ICakeStaker.sol";
import "./TestCake.sol";

contract TestCakeStaker is ICakeStaker {

    TestCake immutable public cake;

    constructor(TestCake _cake) {
        cake = _cake;
    }

    mapping(address => uint256) blocks;

    function enterStaking(uint256 amount) override external {
        cake.transferFrom(msg.sender, address(this), amount);
        blocks[msg.sender] = block.number;
    }

    function leaveStaking(uint256 amount) override external {
        uint256 reward = blocks[msg.sender] * 1e18;
        cake.mint(reward);
        cake.transfer(msg.sender, amount + reward);
    }

    function pendingCake(uint256 pid, address user) override external view returns (uint256) {
        return blocks[user] * 1e18;
    }

    function userInfo(uint256 pid, address user) override view external returns(uint256 amount, uint256 rewardDebt) {
        return (0, 0);
    }
}
