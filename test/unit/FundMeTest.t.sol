// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test,console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {  
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); // GIVE USER 10 ETHER
    }

    function testMinimumDollarIsFIve() public view {
        assertEq(fundMe.MINIMUM_USD(),5e18);
    }

    function testOwnerIsMsgSender() public view {
        console.log(msg.sender);
        console.log(fundMe.getOwner());
        console.log(address(this));
        // assertEq(fundMe.i_owner(),address(this));
        assertEq(fundMe.getOwner(),msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view{
        uint256 version = fundMe.getVersion();
        assertEq(version,4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert();
        fundMe.fund();// this will send 0 value and then it should revert
    }

    function testFundMeUpdatesFundedDataStructure() public {
        vm.prank(USER); // THE NEXT TXN WILL BE SENT BY USER
        fundMe.fund{value:SEND_VALUE}();
        uint256 amountFunded = fundMe.getAdressToAmountFunded(USER);
        assertEq(amountFunded,SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder,USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value:SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance,0);
        assertEq(endingOwnerBalance,startingOwnerBalance + startingFundMeBalance);

    }

    function testWithdrawFromMultipleFunder() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;

        for(uint160 i= startingFunderIndex;i<numberOfFunders;i++) {
            // address i = makeAddr(i);
            // vm.deal(i,STARTING_BALANCE);
            // vm.prank(i);
            // fundMe.fund{value:SEND_VALUE}();
            hoax(address(i),SEND_VALUE);
            fundMe.fund{value:SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.txGasPrice(GAS_PRICE);
        uint256 gasStarting = gasleft();
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        uint256 gasEnding = gasleft();

        uint256 gasUsed = gasStarting - gasEnding;
        console.log(gasUsed);

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance,0);
        assertEq(endingOwnerBalance,startingOwnerBalance + startingFundMeBalance);

    }

    function testWithdrawFromMultipleFunderCheaper() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;

        for(uint160 i= startingFunderIndex;i<numberOfFunders;i++) {
            // address i = makeAddr(i);
            // vm.deal(i,STARTING_BALANCE);
            // vm.prank(i);
            // fundMe.fund{value:SEND_VALUE}();
            hoax(address(i),SEND_VALUE);
            fundMe.fund{value:SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.txGasPrice(GAS_PRICE);
        uint256 gasStarting = gasleft();
        vm.prank(fundMe.getOwner());
        fundMe.cheaperWitdraw();
        uint256 gasEnding = gasleft() * tx.gasprice;

        uint256 gasUsed = gasStarting - gasEnding;
        console.log(gasUsed);

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance,0);
        assertEq(endingOwnerBalance,startingOwnerBalance + startingFundMeBalance);

    }
}