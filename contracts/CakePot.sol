// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "./interfaces/ICakePot.sol";
import "./interfaces/IRNG.sol";
import "./interfaces/ICakeStaker.sol";
import "./NabeDividend.sol";

contract CakePot is Ownable, ICakePot, NabeDividend {

    IRNG private rng;
    IBEP20 public cake;
    ICakeStaker public cakeStaker;

    constructor(
        INabeEmitter nabeEmitter,
        INabe nabe,
        uint256 pid,
        IRNG _rng,
        IBEP20 _cake,
        ICakeStaker _cakeStaker
    ) NabeDividend(nabeEmitter, nabe, pid) {
        startSeasonBlock = block.number;
        rng = _rng;
        cake = _cake;
        cakeStaker = _cakeStaker;
        emit Start(0);
    }
    
    uint256 public period = 720;
    uint256 override public currentSeason = 0;
    uint256 public startSeasonBlock;
    uint256 public drawTime = block.timestamp + 3600;

    mapping(uint256 => uint256) override public userCounts;
    mapping(uint256 => mapping(address => uint256)) override public amounts;
    mapping(uint256 => uint256) override public totalAmounts;
    mapping(uint256 => mapping(address => uint256)) override public weights;
    mapping(uint256 => uint256) override public totalWeights;
    
    mapping(uint256 => uint256) public maxSSRCounts;
    mapping(uint256 => uint256) public maxSRCounts;
    mapping(uint256 => uint256) public maxRCounts;
    mapping(uint256 => uint256) public ssrRewards;
    mapping(uint256 => uint256) public srRewards;
    mapping(uint256 => uint256) public rRewards;
    mapping(uint256 => uint256) public nRewards;

    mapping(uint256 => address[]) override public ssrs;
    mapping(uint256 => address[]) override public srs;
    mapping(uint256 => address[]) override public rs;
    mapping(uint256 => mapping(address => bool)) public exited;

    function setRNG(IRNG _rng) external onlyOwner {
        rng = _rng;
    }

    function setPeriod(uint256 _period) external onlyOwner {
        period = _period;
    }

    function checkEnd() override public view returns (bool) {
        return block.number - startSeasonBlock > period;
    }

    function enter(uint256 amount) override external {
        require(amount > 0);
        require(checkEnd() != true);

        if (amounts[currentSeason][msg.sender] == 0) {
            userCounts[currentSeason] += 1;
        }
        
        amounts[currentSeason][msg.sender] += amount;
        totalAmounts[currentSeason] += amount;
        uint256 weight = (period - (block.number - startSeasonBlock)) * amount;
        weights[currentSeason][msg.sender] += weight;
        totalWeights[currentSeason] += weight;

        cake.transferFrom(msg.sender, address(this), amount);
        cake.approve(address(cakeStaker), amount);
        cakeStaker.enterStaking(amount);

        _addShare(amount);
        emit Enter(currentSeason, msg.sender, amount);
    }

    function end() override external {
        require(checkEnd() == true);

        uint256 userCount = userCounts[currentSeason];
        uint256 totalReward = cakeStaker.pendingCake(0, address(this));
        (uint256 staked,) = cakeStaker.userInfo(0, address(this));
        cakeStaker.leaveStaking(staked);

        // ssr
        uint256 maxSSRCount = userCount * 3 / 100; // 3%
        uint256 totalSSRReward = totalReward * 3 / 10; // 30%
        maxSSRCounts[currentSeason] = maxSSRCount;
        ssrRewards[currentSeason] = maxSSRCount == 0 ? 0 : totalSSRReward / maxSSRCount;

        // sr
        uint256 maxSRCount = userCount * 7 / 100; // 7%
        uint256 totalSRReward = totalReward / 5; // 20%
        maxSRCounts[currentSeason] = maxSRCount;
        srRewards[currentSeason] = maxSRCount == 0 ? 0 : totalSRReward / maxSRCount;

        // r
        uint256 maxRCount = userCount * 3 / 20; // 15%
        uint256 totalRReward = totalReward / 10; // 10%
        maxRCounts[currentSeason] = maxRCount;
        rRewards[currentSeason] = maxRCount == 0 ? 0 : totalRReward / maxRCount;

        // n
        nRewards[currentSeason] = userCount == 0 ? 0 : (totalReward - totalSSRReward - totalSRReward - totalRReward) / userCount;

        emit End(currentSeason);

        // start next season.
        currentSeason += 1;
        startSeasonBlock = block.number;
        drawTime = block.timestamp;
        emit Start(currentSeason);
    }

    function exit(uint256 season) override external {
        require(season < currentSeason);
        require(exited[season][msg.sender] != true);
        
        uint256 enterAmount = amounts[season][msg.sender];
        _subShare(enterAmount);

        uint256 amount = enterAmount + nRewards[season];
        uint256 weight = weights[season][msg.sender];

        uint256 a = userCounts[season] * totalWeights[season] / weight;
        uint256 k = (rng.generateRandomNumber(season, msg.sender) % 100) * a;
        if (ssrs[season].length < maxSSRCounts[season] && k < 3) { // 3%, sr
            ssrs[season].push(msg.sender);
            amount += ssrRewards[season];
        }
        
        k = (rng.generateRandomNumber(season, msg.sender) % 100) * a;
        if (srs[season].length < maxSRCounts[season] && k < 7) { // 7%, sr
            srs[season].push(msg.sender);
            amount += srRewards[season];
        }
        
        k = (rng.generateRandomNumber(season, msg.sender) % 100) * a;
        if (rs[season].length < maxRCounts[season] && k < 15) { // 15%, r
            rs[season].push(msg.sender);
            amount += rRewards[season];
        }

        // n
        cake.transfer(msg.sender, amount);

        exited[season][msg.sender] = true;
        
        emit Exit(season, msg.sender, amount);
    }
}