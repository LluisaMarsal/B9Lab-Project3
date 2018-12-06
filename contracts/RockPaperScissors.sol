pragma solidity ^0.4.19;
 
contract RockPaperScissors {
    
    address public owner;
    
    enum Bet {ROCK, PAPER, SCISSORS}
    
    struct BetBox {
       address player1;
       address player2;
       Bet betPlayer1;
       Bet betPlayer2;
       uint amountPlayer1;
       uint amountPlayer2;
       uint sumAmounts; 
       uint deadline; 
    }
    
    // for every uint there is a BetBox and those namespaces (struct) will conform a mapping named wagerStructs
    mapping (bytes32 => BetBox) public betStructs; 
    
    event LogCreateBet(address caller, uint amount, uint duration);
    event LogSeeBet(address caller, uint amount, uint now);
    event LogPlayBet(address winner, uint sumAmounts, uint now);
    
    function RockPaperScissors() public {
        owner = msg.sender;
    }
    
    function gethashToBet(bytes32 passPlayer1, bytes32 passPlayer2) public pure returns(bytes32 hashToBet) {
        return keccak256(passPlayer1, passPlayer2);
    }
    
    function createBet(bytes32 hashToBet, address player2, uint duration) public payable returns(bool success) {
        if(betStructs[hashToBet].sumAmounts != 0) revert();
        require(betStructs[hashToBet].player1 != player2); 
        betStructs[hashToBet].deadline = duration + block.number;
        betStructs[hashToBet].amountPlayer1 = amount;
        uint amount = betStructs[hashToBet].amountPlayer1;
        LogCreateBet(msg.sender, msg.value, duration);
        return true;
    }
    
    function seeBet(bytes32 hashToBet, address player1) public payable returns(bool success) {
        if(betStructs[hashToBet].sumAmounts != 0) revert();
        require(betStructs[hashToBet].player2 != player1); 
        require(betStructs[hashToBet].deadline < now);
    //QUESTION TO REVIEWERS: this require() does not work as it allows player2 to bet below player1, why isn't working?
        require(betStructs[hashToBet].amountPlayer1 == betStructs[hashToBet].amountPlayer2);
        betStructs[hashToBet].amountPlayer2 = amount;
        uint amount = betStructs[hashToBet].amountPlayer2;
        LogSeeBet(msg.sender, msg.value, now);
        return true;
    }
    
    function playBet(bytes32 passPlayer1, bytes32 passPlayer2, Bet betPlayer1, Bet betPlayer2) public returns(address winner) {
        bytes32 hashToBet = gethashToBet(passPlayer1, passPlayer2);
        BetBox memory b = betStructs[hashToBet];
        require(b.amountPlayer1 + b.amountPlayer2 == b.sumAmounts);
        if (b.player1 == b.player2) revert();
        if (b.betPlayer1 == b.betPlayer2) revert();
        if ((betPlayer1 == Bet.PAPER && betPlayer2 == Bet.ROCK)||
            (betPlayer1 == Bet.ROCK && betPlayer2 == Bet.SCISSORS)||
            (betPlayer1 == Bet.SCISSORS && betPlayer2 == Bet.PAPER)||
            (betPlayer1 == Bet.ROCK && betPlayer2 == Bet.SCISSORS)||
            (betPlayer1 == Bet.PAPER && betPlayer2 == Bet.ROCK)||
            (betPlayer1 == Bet.SCISSORS && betPlayer2 == Bet.PAPER))
            return b.player1;
        if ((betPlayer2 == Bet.PAPER && betPlayer1 == Bet.ROCK)||
            (betPlayer2 == Bet.ROCK && betPlayer1 == Bet.SCISSORS)||
            (betPlayer2 == Bet.SCISSORS && betPlayer1 == Bet.PAPER)||
            (betPlayer2 == Bet.ROCK && betPlayer1 == Bet.SCISSORS)||
            (betPlayer2 == Bet.PAPER && betPlayer1 == Bet.ROCK)||
            (betPlayer2 == Bet.SCISSORS && betPlayer1 == Bet.PAPER))
            return b.player2;    
        LogPlayBet(winner, b.sumAmounts, now);
        winner.transfer(b.sumAmounts);
    }
}