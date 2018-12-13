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
    }
    
    struct WinnerBox {
        address winner;
        uint amountWinner;
    }
    
    // for every uint there is a BetBox and those namespaces (struct) will conform a mapping named betStructs
    mapping (bytes32 => BetBox) public betStructs; 
    mapping (bytes32 => WinnerBox) public winnerStructs;
    
    event LogCreateBet(address caller, uint amount, uint duration);
    event LogJoinBet(address caller, uint amount, uint now);
    event LogAwardWinner (address caller, address winner);
    event LogAwardBet(uint amount, address winner);
    
    function RockPaperScissors() public {
        owner = msg.sender;
    }
    
    function getHashToBet(bytes32 passPlayer1, bytes32 passPlayer2) public pure returns(bytes32 hashToBet) {
        return keccak256(passPlayer1, passPlayer2);
    }
    
    function createBet(bytes32 hashToBet, address player2, uint duration) public payable returns(bool success) {
        require(betStructs[hashToBet].amountPlayer1 == 0);
        require(betStructs[hashToBet].player1 != player2); 
        betStructs[hashToBet].player1 = msg.sender;
        betStructs[hashToBet].player2 = player2;
        betStructs[hashToBet].deadline = duration + block.number;
        betStructs[hashToBet].amountPlayer1 = msg.value;
        LogCreateBet(msg.sender, msg.value, duration);
        msg.sender.transfer(msg.value);
        return true;
    }
    
    function joinBet(bytes32 hashToBet) public payable returns(bool success) {
        require(betStructs[hashToBet].amountPlayer2 == 0);
        require(betStructs[hashToBet].deadline < now);
        require(betStructs[hashToBet].player2 == msg.sender); 
        require(betStructs[hashToBet].amountPlayer1 == msg.value);
        if (betStructs[hashToBet].amountPlayer1 != betStructs[hashToBet].amountPlayer2) revert();
        betStructs[hashToBet].amountPlayer2 = msg.value;
        LogJoinBet(msg.sender, msg.value, now);
        msg.sender.transfer(msg.value);
        return true;
    }
    
    function playBet(Bet betPlayer1, Bet betPlayer2) public pure returns(uint winningPlayer) {
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
        assert(false, "We should never have reached here");
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

    function awardBetToWinner(bytes32 hashToAward, bytes32 hashToBet) public returns(bool success) {
        require(winnerStructs[hashToAward].winner == msg.sender);
        betStructs[hashToBet].amountWinner = betStructs[hashToBet].amountPlayer1 + betStructs[hashToBet].amountPlayer2;
        uint amount = betStructs[hashToBet].amountWinner;
        LogAwardBet(amount, msg.sender);
        msg.sender.transfer(amount);
        return true;    
    }
}

//pending1: assign Winner to betStructs box and assign amountWinner to winnerStructs box
//pending2: create a cancelBet() to return money to players if there is a tie. 