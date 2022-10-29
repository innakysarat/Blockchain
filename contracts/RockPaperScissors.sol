// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0 <0.9.0;
 
contract RockPaperScissors {
 
   enum Choice {
       Empty,
       Rock,
       Paper,
       Scissors
   }
 
   enum Stage {
       CommitFirstPlayer,
       CommitSecondPlayer,
       RevealFirstPlayer,
       RevealSecondPlayer,
       Distribute
   }
 
   struct PlayerChoice {
       address playerAddress;
       bytes32 commitment;
       Choice choice;
   }
 
   event Payout(address player, uint amount);
 
   uint public bet;
   uint public deposit;
   uint public deadlineReveal;
 
   PlayerChoice[2] public players;
 
   uint public revealDeadline;
   Stage public stage = Stage.CommitFirstPlayer;
 
   uint commitAmount = deposit + bet;
   uint winningAmount = deposit + 2 * bet;

   constructor(uint _bet, uint _deposit, uint _revealSpan) {
       bet = _bet;
       deposit = _deposit;
       deadlineReveal = _revealSpan;
   }
 
   modifier validStage(Stage _stage) {
       if (_stage != Stage.CommitFirstPlayer && _stage != Stage.CommitSecondPlayer) {
           revert("Both players have already played");
       } else {
           _;
       }
   }
   modifier checkAmount(uint _amount) {
       require(_amount >= bet, "Overflow error");
       _;
   }
    modifier checkAmount2(uint _amount) {
       require(msg.value >= commitAmount, "Value must be greater than commit amount");
       _;
   }
   function commit(bytes32 commitment) public payable validStage(stage) checkAmount(commitAmount) checkAmount2(commitAmount){
       // Only run during commit stages
       uint playerIndex;
       if(stage == Stage.CommitFirstPlayer) playerIndex = 0;
       else if(stage == Stage.CommitSecondPlayer) playerIndex = 1;
 
       (bool success, ) = msg.sender.call{value:msg.value - commitAmount}("");
       require(success, "Call failed");
 
      players[playerIndex] = PlayerChoice(msg.sender, commitment, Choice.Empty);
 
       if(stage == Stage.CommitFirstPlayer) stage = Stage.CommitSecondPlayer;
       else stage = Stage.RevealFirstPlayer;
   }
    modifier knownPlayer(address _player1, address _player2) {
       if (_player1 != msg.sender && _player2 != msg.sender) {
           revert("Unknown player");
       } else {
           _;
       }
   }
   modifier checkStage(Stage _stage){require(stage == Stage.RevealFirstPlayer || stage == Stage.RevealSecondPlayer, "Must be reveal stage");
       _;
   }
   modifier checkChoice(Choice _choice){
       require(_choice == Choice.Rock || _choice == Choice.Paper || _choice == Choice.Scissors, "Invalid choice");
       _;
   }
   function reveal(Choice choice, bytes32 blindingFactor) public knownPlayer(players[0].playerAddress, players[1].playerAddress) checkStage(stage) checkChoice(choice){
 
       uint playerIndex;
       if(players[0].playerAddress == msg.sender) playerIndex = 0;
       else if (players[1].playerAddress == msg.sender) playerIndex = 1;
 
       PlayerChoice storage playerChoice = players[playerIndex];
 
       require(keccak256(abi.encodePacked(msg.sender, choice, blindingFactor)) == playerChoice.commitment, "Invalid hash");
 
       playerChoice.choice = choice;
 
       if(stage == Stage.RevealFirstPlayer) {
           revealDeadline = block.number + deadlineReveal;
           require(revealDeadline >= block.number, "Overflow error");
           stage = Stage.RevealSecondPlayer;
       }
       else stage = Stage.Distribute;
   }
   modifier checkStageDistribute(Stage _stage){
       require(stage == Stage.Distribute || (stage == Stage.RevealSecondPlayer && revealDeadline <= block.number), "Must be distribute");
       _;
   }
   modifier checkWinningAmount(){
        require(winningAmount / deposit == 2 * bet, "Overflow error");
        _;
   }
function distribute() public checkStageDistribute(stage) checkWinningAmount(){
       uint player0Payout;
       uint player1Payout;
 
       if(players[0].choice == players[1].choice) {
           player0Payout = deposit + bet;
           player1Payout = deposit + bet;
       }
       else if(players[0].choice == Choice.Empty) {
           player1Payout = winningAmount;
       }
       else if(players[1].choice == Choice.Empty) {
           player0Payout = winningAmount;
       }
       else if(players[0].choice == Choice.Rock) {
           assert(players[1].choice == Choice.Paper || players[1].choice == Choice.Scissors);
           if(players[1].choice == Choice.Paper) {
               player0Payout = deposit;
               player1Payout = winningAmount;
           }
           else if(players[1].choice == Choice.Scissors) {
               player0Payout = winningAmount;
               player1Payout = deposit;
           }
 
       }
       else if(players[0].choice == Choice.Paper) {
           assert(players[1].choice == Choice.Rock || players[1].choice == Choice.Scissors);
           if(players[1].choice == Choice.Rock) {
               player0Payout = winningAmount;
               player1Payout = deposit;
           }
           else if(players[1].choice == Choice.Scissors) {
               player0Payout = deposit;
               player1Payout = winningAmount;
           }
       }
       else if(players[0].choice == Choice.Scissors) {
           assert(players[1].choice == Choice.Paper || players[1].choice == Choice.Rock);
           if(players[1].choice == Choice.Rock) {
               player0Payout = deposit;
               player1Payout = winningAmount;
           }
           else if(players[1].choice == Choice.Paper) {
               player0Payout = winningAmount;
               player1Payout = deposit;
           }
       }
       else revert("Invalid choice");
 
       if(player0Payout > 0) {
           (bool success, ) = players[0].playerAddress.call{value: player0Payout}("");
           require(success, 'Call failed');
           emit Payout(players[0].playerAddress, player0Payout);
       } else if (player1Payout > 0) {
           (bool success, ) = players[1].playerAddress.call{value: player1Payout}("");
           require(success, 'Call failed');
           emit Payout(players[1].playerAddress, player1Payout);
       }
       delete players;
       revealDeadline = 0;
       stage = Stage.CommitFirstPlayer;
   }
}
