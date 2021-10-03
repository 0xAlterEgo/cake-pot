// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/INabeDividend.sol";
import "./interfaces/INabeEmitter.sol";
import "./interfaces/INabe.sol";

abstract contract NabeDividend is INabeDividend {

    INabeEmitter public immutable nabeEmitter;
    INabe public immutable nabe;
    uint256 public override immutable pid;

    constructor(
        INabeEmitter _nabeEmitter,
        INabe _nabe,
        uint256 _pid
    ) {
        nabeEmitter = _nabeEmitter;
        nabe = _nabe;
        pid = _pid;
    }

    uint256 internal currentBalance = 0;
    uint256 internal totalShares = 0;
    mapping(address => uint256) public shares;

    uint256 constant internal pointsMultiplier = 2**128;
    uint256 internal pointsPerShare = 0;
    mapping (address => int256) internal pointsCorrection;
    mapping (address => uint256) internal claimed;

    function updateBalance() internal {
        if (totalShares > 0) {
            nabeEmitter.updatePool(pid);
            uint256 balance = nabe.balanceOf(address(this));
            uint256 value = balance - currentBalance;
            if (value > 0) {
                pointsPerShare += value * pointsMultiplier / totalShares;
                emit Distribute(msg.sender, value);
            }
            currentBalance = balance;
        }
    }

    function claimedOf(address owner) override public view returns (uint256) {
        return claimed[owner];
    }

    function accumulativeOf(address owner) override public view returns (uint256) {
        uint256 _pointsPerShare = pointsPerShare;
        if (totalShares > 0) {
            uint256 balance = nabeEmitter.pendingToken(pid) + nabe.balanceOf(address(this));
            uint256 value = balance - currentBalance;
            if (value > 0) {
                _pointsPerShare += value * pointsMultiplier / totalShares;
            }
            return uint256(int256(_pointsPerShare * shares[owner]) + pointsCorrection[owner]) / pointsMultiplier;
        }
        return 0;
    }

    function claimableOf(address owner) override external view returns (uint256) {
        return accumulativeOf(owner) - claimed[owner];
    }

    function _accumulativeOf(address owner) internal view returns (uint256) {
        return uint256(int256(pointsPerShare * shares[owner]) + pointsCorrection[owner]) / pointsMultiplier;
    }

    function _claimableOf(address owner) internal view returns (uint256) {
        return _accumulativeOf(owner) - claimed[owner];
    }

    function claim() override external returns (uint256 claimable) {
        updateBalance();
        claimable = _claimableOf(msg.sender);
        if (claimable > 0) {
            claimed[msg.sender] += claimable;
            emit Claim(msg.sender, claimable);
            nabe.transfer(msg.sender, claimable);
            currentBalance -= claimable;
        }
    }

    function _addShare(uint256 amount) internal {
        updateBalance();
        totalShares += amount;
        shares[msg.sender] += amount;
        pointsCorrection[msg.sender] -= int256(pointsPerShare * amount);
    }

    function _subShare(uint256 amount) internal {
        updateBalance();
        totalShares -= amount;
        shares[msg.sender] -= amount;
        pointsCorrection[msg.sender] += int256(pointsPerShare * amount);
    }
}