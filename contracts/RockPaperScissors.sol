pragma solidity ^0.4.19;
 
contract RockPaperScissors {
    
    address public owner;
    //if uint winningPlayer in playBet() returns 1, winner is player1
    //if uint winningPlayer in playBet() returns 2, winner is player2
    
    enum Bet {ROCK, PAPER, SCISSORS}
    
    struct BetBox {
       address player1;
       address player2;
       address winner;
       Bet betPlayer1;
       Bet betPlayer2;
       uint amountPlayer1;
       uint amountPlayer2;
       uint amountWinner;
       uint joinDeadline; 
       uint playersNextMoveDeadline;
    }
    
    // for every uint there is a BetBox and those namespaces (struct) will conform a mapping named betStructs
    mapping (bytes32 => BetBox) public betStructs; 
    
    event LogCreateBet(address caller, uint amount, uint numberOfBlocks);
    event LogJoinBet(address caller, uint amount, uint nextNumberOfBlocks);
    event LogPlayer1Move(address caller, Bet betPlayer1);
    event LogPlayer2Move(address caller, Bet betPlayer2);
    event LogPlayBet(address caller, Bet betPlayer1, Bet betPlayer2);
    event LogAwardWinner (address caller, address winner);
    event LogAwardBet(uint amount, address winner);
    
    function RockPaperScissors() public {
        owner = msg.sender;
    }
    
    function getGameID(bytes32 passPlayer1, bytes32 passPlayer2) internal pure returns(bytes32 gameID) {
        return keccak256(passPlayer1, passPlayer2);
    }
    
    function createBet(bytes32 passPlayer1, address player2, uint numberOfBlocks) public payable returns(bool success) {
        require(betStructs[passPlayer1].amountPlayer1 == 0);
        require(msg.sender != player2); 
        betStructs[passPlayer1].player1 = msg.sender;
        betStructs[passPlayer1].player2 = player2;
        betStructs[passPlayer1].joinDeadline = block.number + numberOfBlocks;
        betStructs[passPlayer1].amountPlayer1 = msg.value;
        LogCreateBet(msg.sender, msg.value, numberOfBlocks);
        return true;
    }
    
    function joinBet(bytes32 passPlayer1, uint nextNumberOfBlocks) public payable returns(bool success) {
        require(betStructs[passPlayer1].amountPlayer2 == 0);
        require(betStructs[passPlayer1].joinDeadline > block.number);
        require(betStructs[passPlayer1].player2 == msg.sender); 
        require(betStructs[passPlayer1].amountPlayer1 == msg.value);
        betStructs[passPlayer1].playersNextMoveDeadline = block.number + nextNumberOfBlocks;
        betStructs[passPlayer1].amountPlayer2 = msg.value;
        LogJoinBet(msg.sender, msg.value, nextNumberOfBlocks);
        return true;
    }
    
    function player1Move(bytes32 passPlayer1, Bet betPlayer1) internal returns(bool success) {
        require(betStructs[passPlayer1].player1 == msg.sender);
        require(betStructs[passPlayer1].betPlayer1 == Bet.ROCK || betStructs[passPlayer1].betPlayer1 == Bet.PAPER || betStructs[passPlayer1].betPlayer1 == Bet.SCISSORS);
        require(betStructs[passPlayer1].playersNextMoveDeadline > block.number);
        LogPlayer1Move(msg.sender, betPlayer1);
        return true;
    }
    
    function player2Move(bytes32 passPlayer1, Bet betPlayer2) internal returns(bool success) {
        require(betStructs[passPlayer1].player2 == msg.sender);
        require(betStructs[passPlayer1].betPlayer2 == Bet.ROCK || betStructs[passPlayer1].betPlayer2 == Bet.PAPER || betStructs[passPlayer1].betPlayer2 == Bet.SCISSORS);
        require(betStructs[passPlayer1].playersNextMoveDeadline > block.number);
        LogPlayer2Move(msg.sender, betPlayer2);
        return true;
    }
    
    function playBet(bytes32 passPlayer1, Bet betPlayer1, Bet betPlayer2) public returns(uint winningPlayer) {
        require(owner == msg.sender);
        betStructs[passPlayer1].betPlayer1 = Bet(betPlayer1);
        betStructs[passPlayer1].betPlayer2 = Bet(betPlayer2);
        LogPlayBet(msg.sender, betPlayer1, betPlayer2);
        if (betPlayer1 == betPlayer2) revert();
        if ((betPlayer1 == Bet.PAPER && betPlayer2 == Bet.ROCK)||
            (betPlayer1 == Bet.ROCK && betPlayer2 == Bet.SCISSORS)||
            (betPlayer1 == Bet.SCISSORS && betPlayer2 == Bet.PAPER)||
            (betPlayer1 == Bet.ROCK && betPlayer2 == Bet.SCISSORS)||
            (betPlayer1 == Bet.PAPER && betPlayer2 == Bet.ROCK)||
            (betPlayer1 == Bet.SCISSORS && betPlayer2 == Bet.PAPER)) return 1;
        if ((betPlayer2 == Bet.PAPER && betPlayer1 == Bet.ROCK)||
            (betPlayer2 == Bet.ROCK && betPlayer1 == Bet.SCISSORS)||
            (betPlayer2 == Bet.SCISSORS && betPlayer1 == Bet.PAPER)||
            (betPlayer2 == Bet.ROCK && betPlayer1 == Bet.SCISSORS)||
            (betPlayer2 == Bet.PAPER && betPlayer1 == Bet.ROCK)||
            (betPlayer2 == Bet.SCISSORS && betPlayer1 == Bet.PAPER)) return 2;  
        assert(false);
    }
    
    function awardWinner(bytes32 passPlayer1, address winner) public returns(bool success) {
        require(owner == msg.sender);
        betStructs[passPlayer1].winner = winner;
        LogAwardWinner(msg.sender, winner);
        return true;
    }

    function awardBetToWinner(bytes32 gameID, bytes32 passPlayer1, bytes32 passPlayer2) public returns(bool success) {
        gameID = getGameID(passPlayer1, passPlayer2);
        require(owner == msg.sender);
        betStructs[passPlayer1].amountWinner = betStructs[passPlayer1].amountPlayer1 + betStructs[passPlayer1].amountPlayer2;
        uint amount = betStructs[passPlayer1].amountWinner;
        require(amount != 0);
        betStructs[passPlayer1].amountWinner = 0;
        LogAwardBet(amount, msg.sender);
        betStructs[passPlayer1].winner.transfer(amount);
        return true;    
    }
}