// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MintLocker} from "../src/MintLocker.sol";

contract MockINV {
    address public owner;
    mapping(address => uint) public balances;

    function mint(address dst, uint rawAmount) external {
        balances[dst] += rawAmount;
    }

    function setOwner(address owner_) external {
        owner = owner_;
    }
}

contract MintLockerTest is Test {
    MintLocker public mintLocker;
    MockINV public mockInv;
    address public gov;
    address public user;

    function setUp() public {
        gov = address(this);
        user = address(0x1);
        mockInv = new MockINV();
        mintLocker = new MintLocker(address(mockInv), gov);
    }

    function testConstructor() public {
        assertEq(address(mintLocker.inv()), address(mockInv));
        assertEq(mintLocker.gov(), gov);
    }

    function testMint() public {
        mintLocker.mint(user, 100);
        assertEq(mockInv.balances(user), 100);
    }

    function testMintOnlyGov() public {
        vm.prank(user);
        vm.expectRevert(bytes("!gov"));
        mintLocker.mint(user, 100);
    }

    function testTransferInvOwnership() public {
        mintLocker.transferInvOwnership(user);
        assertEq(mockInv.owner(), user);
    }

    function testSetGov() public {
        mintLocker.setGov(user);
        assertEq(mintLocker.gov(), user);
    }

    function testLock() public {
        mintLocker.lock(7 days);
        assertTrue(mintLocker.isLocked());
        assertEq(mintLocker.lockedUntil(), block.timestamp + 7 days);
    }

    function testLockMaxDuration() public {
        vm.expectRevert("!duration");
        mintLocker.lock(366 days);
    }

    function testMintWhenLocked() public {
        mintLocker.lock(7 days);
        vm.expectRevert("locked");
        mintLocker.mint(user, 100);
    }

    function testTransferInvOwnershipWhenLocked() public {
        mintLocker.lock(7 days);
        vm.expectRevert("locked");
        mintLocker.transferInvOwnership(user);
    }

    function testUnlockAfterDuration() public {
        mintLocker.lock(7 days);
        assertTrue(mintLocker.isLocked());
        
        vm.warp(block.timestamp + 7 days + 1);
        assertFalse(mintLocker.isLocked());
        
        // Should be able to mint after unlock
        mintLocker.mint(user, 100);
        assertEq(mockInv.balances(user), 100);
    }

    function testSetGovOnlyGov() public {
        vm.prank(user);
        vm.expectRevert(bytes("!gov"));
        mintLocker.setGov(user);
    }

    function testLockOnlyGov() public {
        vm.prank(user);
        vm.expectRevert(bytes("!gov"));
        mintLocker.lock(7 days);
    }

    function testLockZeroDuration() public {
        mintLocker.lock(0);
        assertFalse(mintLocker.isLocked());
    }

    function testLockMultipleTimes() public {
        mintLocker.lock(7 days);
        uint firstLockUntil = mintLocker.lockedUntil();

        vm.warp(block.timestamp + 3 days);
        mintLocker.lock(14 days);
        uint secondLockUntil = mintLocker.lockedUntil();

        assertGt(secondLockUntil, firstLockUntil);
        assertEq(secondLockUntil, block.timestamp + 14 days);
    }
}
