// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IINV {
    function mint(address dst, uint rawAmount) external;
    function setOwner(address owner_) external;
}

contract MintLocker {

    IINV public immutable inv;
    address public gov;
    uint constant MAX_LOCK_DURATION = 365 days;
    uint public lockedUntil;

    constructor(address _inv, address _gov) {
        inv = IINV(_inv);
        gov = _gov;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "!gov");
        _;
    }

    modifier onlyWhenUnlocked() {
        require(!isLocked(), "locked");
        _;
    }

    function isLocked() public view returns (bool) {
        return block.timestamp < lockedUntil;
    }

    function mint(address dst, uint rawAmount) external onlyGov onlyWhenUnlocked {
        inv.mint(dst, rawAmount);
    }

    function transferInvOwnership(address newOwner) external onlyGov onlyWhenUnlocked {
        inv.setOwner(newOwner);
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }

    function lock(uint duration) external onlyGov {
        require(duration <= MAX_LOCK_DURATION, "!duration");
        lockedUntil = block.timestamp + duration;
    }
}
