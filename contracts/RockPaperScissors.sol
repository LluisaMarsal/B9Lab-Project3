pragma solidity ^0.4.19;
 
contract RockPaperScissors {
    
    address public owner;
    //uint winningPlayer returns 1, winner is player1
    //uint winningPlayer returns 2, winner is player2
    
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
       uint deadline; 
       uint newDeadline;
    }
    
    struct WinnerBox {
        address winner;
        uint amountWinner;
    }
    
    // for every uint there is a BetBox and those namespaces (struct) will conform a mapping named betStructs
    mapping (bytes32 => BetBox) public betStructs; 
    mapping (bytes32 => WinnerBox) public winnerStructs;
    
    event LogCreateBet(address caller, uint amount, uint numberOfBlocks);
    event LogJoinBet(address caller, uint amount, uint newNumberOfBlocks);
    event LogPlayer1Move(address caller, uint betPlayer1);
    event LogPlayer2Move(address caller, uint betPlayer2);
    event LogPlayBet(address caller, uint betPlayer1, uint betPlayer2);
    event LogAwardWinner (address caller, address winner);
    event LogAwardBet(uint amount, address winner);
    
    function RockPaperScissors() public {
        owner = msg.sender;
    }
    
    function getGameID(bytes32 passPlayer1, bytes32 passPlayer2) public pure returns(bytes32 gameID) {
        return keccak256(passPlayer1, passPlayer2);
    }
    
    function createBet(bytes32 passPlayer1, bytes32 gameID, address player2, uint numberOfBlocks) public payable returns(bool success) {
        require(betStructs[gameID].amountPlayer1 == 0);
        require(betStructs[gameID].player1 != player2); 
        betStructs[gameID].player1 = msg.sender;
        betStructs[gameID].player2 = player2;
        betStructs[gameID].deadline = block.number + numberOfBlocks;
        betStructs[gameID].amountPlayer1 = msg.value;
        LogCreateBet(msg.sender, msg.value, numberOfBlocks);
        return true;
    }
    
    function joinBet(bytes32 passPlayer2, bytes32 gameID, uint newNumberOfBlocks) public payable returns(bool success) {
        require(betStructs[gameID].amountPlayer2 == 0);
        require(betStructs[gameID].deadline > block.number);
        require(betStructs[gameID].player2 == msg.sender); 
        require(betStructs[gameID].amountPlayer1 == msg.value);
        betStructs[gameID].newDeadline = block.number + newNumberOfBlocks;
        betStructs[gameID].amountPlayer2 = msg.value;
        LogJoinBet(msg.sender, msg.value, newNumberOfBlocks);
        return true;
    }
    
    function player1Move(bytes32 passPlayer1, bytes32 gameID, Bet betPlayer1) public returns(bool success) {
        require(betStructs[gameID].player1 == msg.sender);
        require(betStructs[gameID].betPlayer1 == 0 || betStructs[gameID].betPlayer1 == 1 || betStructs[gameID].betPlayer1 == 2);
        require(betStructs[gameID].newDeadline > block.number);
        LogPlayer1Move(msg.sender, betPlayer1);
        return true;
    }
    
    function player2Move(bytes32 passPlayer2, bytes32 gameID, Bet betPlayer2) public returns(bool success) {
        require(betStructs[gameID].player2 == msg.sender);
        require(betStructs[gameID].betPlayer2 == 0 || betStructs[gameID].betPlayer2 == 1 || betStructs[gameID].betPlayer2 == 2);
        require(betStructs[gameID].newDeadline > block.number);
        LogPlayer2Move(msg.sender, betPlayer2);
        return true;
    }
    
    function playBet(bytes32 passPlayer1, bytes32 passPlayer2) public view returns(uint winningPlayer) {
        bytes32 gameID = getGameID(passPlayer1, passPlayer2);
        require(owner == msg.sender);
        betStructs[gameID].betPlayer1 = Bet.betPlayer1;
        betStructs[gameID].betPlayer2 = Bet.betPlayer2;
        LogPlayBet(msg.sender, Bet.betPlayer1, Bet.betPlayer2);
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
    
    function getHashToAward(bytes32 passOwner, bytes32 passWinner) public pure returns(bytes32 hashToAward) {
        return keccak256(passOwner, passWinner);
    }
    
    function awardWinner(bytes32 hashToAward, address winner) public returns(bool success) {
        require(owner == msg.sender);
        winnerStructs[hashToAward].winner = winner;
        LogAwardWinner(msg.sender, winner);
        return true;
    }

    function awardBetToWinner(bytes32 hashToAward, bytes32 gameID) public returns(bool success) {
        require(winnerStructs[hashToAward].winner == msg.sender);
        uint amount = betStructs[gameID].amountWinner;
        betStructs[gameID].amountWinner = betStructs[gameID].amountPlayer1 + betStructs[gameID].amountPlayer2;
        require(amount != 0);
        betStructs[gameID].amountWinner = 0;
        LogAwardBet(amount, msg.sender);
        msg.sender.transfer(amount);
        return true;    
    }
}


//pending1: assign Winner to betStructs box and assign amountWinner to winnerStructs box
//pending2: create a cancelBet() to return money to players if there is a tie. 