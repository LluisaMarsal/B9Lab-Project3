pragma solidity ^0.4.19;
 
contract RockPaperScissors {
    
    address public owner;
    //uint winningPlayer returns 1, winner is player1
    //uint winningPlayer returns 2, winner is player2
    
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
    event LogAwardBet(uint amount, address winner);
    
    function RockPaperScissors() public {
        owner = msg.sender;
    }
    
    function gethashToBet(bytes32 passPlayer1, bytes32 passPlayer2) public pure returns(bytes32 hashToBet) {
        return keccak256(passPlayer1, passPlayer2);
    }
    
    function createBet(bytes32 hashToBet, address player2, uint duration) public payable returns(bool success) {
        require(betStructs[hashToBet].amountPlayer1 == 0);
        require(betStructs[hashToBet].player1 != player2); 
        betStructs[hashToBet].player2 = player2;
        betStructs[hashToBet].deadline = duration + block.number;
        betStructs[hashToBet].amountPlayer1 = msg.value;
        betStructs[hashToBet].sumAmounts = betStructs[hashToBet].amountPlayer1 + betStructs[hashToBet].amountPlayer2;
        LogCreateBet(msg.sender, msg.value, duration);
        msg.sender.transfer(msg.value);
        return true;
    }
    
    function seeBet(bytes32 hashToBet, address player1) public payable returns(bool success) {
        require(betStructs[hashToBet].amountPlayer2 == 0);
        require(betStructs[hashToBet].deadline < now);
        require(betStructs[hashToBet].player2 == msg.sender); 
        require(betStructs[hashToBet].amountPlayer1 == msg.value);
        betStructs[hashToBet].amountPlayer2 = msg.value;
        betStructs[hashToBet].sumAmounts = betStructs[hashToBet].amountPlayer1 + betStructs[hashToBet].amountPlayer2;
        betStructs[hashToBet].player1 = player1;
        LogSeeBet(msg.sender, msg.value, now);
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
    }
    
    function gethashToAward(bytes32 passOwner, bytes32 passWinner) public pure returns(bytes32 hashToAward) {
        return keccak256(passOwner, passWinner);
    }
    
//this last function compiles but it throws an error when testing it in remix. I can not see the reason

    function awardBet(bytes32 passOwner, bytes32 passWinner, bytes32 hashToBet) public returns(bool success) {
        bytes32 hashToAward = gethashToBet(passOwner, passWinner);
        require(hashToAward != hashToBet);
        require(owner != msg.sender);
        uint amount = betStructs[hashToBet].sumAmounts;
        LogAwardBet(amount, msg.sender);
        msg.sender.transfer(amount);
        return true;    
    }
}
