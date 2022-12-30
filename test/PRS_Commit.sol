pragma solidity ^0.4.2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/RockPaperScissors.sol";
import "./Prs.sol";
import "./ExecutionProxy.sol";

contract PRS_Commit {
    uint256 public initialBalance = 10 ether;
    uint256 depositAmount = 25;
    uint256 betAmount = 100;
    uint256 commitAmount = depositAmount + betAmount;
    uint256 commitAmountGreater = commitAmount + 13;
    
    uint256 revealSpan = 10;

    bytes32 rand1 = "abc";
    bytes32 rand2 = "123";

    function commitmentRock(address sender) private view returns (bytes32) {
        return keccak256(abi.encodePacked(sender, RockPaperScissors.Choice.Rock, rand1));
    }
    function commitmentPaper(address sender) private view returns (bytes32) {
        return keccak256(abi.encodePacked(sender, RockPaperScissors.Choice.Paper, rand2));
    }
    
    function testCommitIncreasesBalance() public {
        RockPaperScissors rps = new RockPaperScissors(betAmount, depositAmount, revealSpan);
        uint256 balanceBefore = address(rps).balance;
        rps.commit.value(commitAmount)(commitmentRock(this));
        uint256 balanceAfter = address(rps).balance;

        Assert.equal(balanceAfter - balanceBefore, commitAmount, "Balance not increased by commit amount.");
        Assert.equal(address(this).balance, initialBalance - commitAmount, "Sender acount did not decrease by bet amount.");
    }

    function testCommitRequiresSenderBetGreaterThanOrEqualContractBet() public {
        RockPaperScissors rps = new RockPaperScissors(betAmount, depositAmount, revealSpan);
        ExecutionProxy executionProxy = new ExecutionProxy(rps);

        RockPaperScissors(executionProxy).commit.value(commitAmount - 1)(commitmentPaper(executionProxy));
        bool result = executionProxy.execute();

        Assert.isFalse(result, "Commit amount less than contact bet amount did not throw.");
        Assert.equal(address(executionProxy).balance, commitAmount - 1, "Not all of balance returned after fault.");
    }
}