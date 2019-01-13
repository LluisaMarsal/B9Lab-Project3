pragma solidity ^0.4.19;
 
contract RockPaperScissors {
    
    address private owner;
    uint constant maxNextNumberOfBlocks = 1 days / 15;
    uint constant minNextNumberOfBlocks = 1 hours / 15;
    //if uint winningPlayer in playBet() returns 1, winner is player1
    //if uint winningPlayer in playBet() returns 2, winner is player2
    
    enum Bet {NULL, ROCK, PAPER, SCISSORS}
    
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
    
    function getGameID(bytes32 passPlayer1, bytes32 passPlayer2) public pure returns(bytes32 gameID) {
        return keccak256(passPlayer1, passPlayer2);
    }
    
    function createBet(bytes32 gameID, address player2, uint numberOfBlocks) public payable returns(bool success) {
        require(betStructs[gameID].amountPlayer1 == 0);
        require(msg.sender != player2); 
        betStructs[gameID].player1 = msg.sender;
        betStructs[gameID].player2 = player2;
        betStructs[gameID].joinDeadline = block.number + numberOfBlocks;
        betStructs[gameID].amountPlayer1 = msg.value;
        LogCreateBet(msg.sender, msg.value, numberOfBlocks);
        return true;
    }
    
    function joinBet(bytes32 gameID, uint nextNumberOfBlocks) public payable returns(bool success) {
        require(betStructs[gameID].amountPlayer2 == 0);
        require(betStructs[gameID].joinDeadline > block.number);
        require(betStructs[gameID].player2 == msg.sender); 
        require(betStructs[gameID].amountPlayer1 == msg.value);
        require(nextNumberOfBlocks < 1 days / 15);
        require(nextNumberOfBlocks > 1 hours / 15);
        betStructs[gameID].joinDeadline = 0;
        betStructs[gameID].playersNextMoveDeadline = block.number + nextNumberOfBlocks;
        betStructs[gameID].amountPlayer2 = msg.value;
        LogJoinBet(msg.sender, msg.value, nextNumberOfBlocks);
        return true;
    }
    
    function player1Move(bytes32 gameID, Bet betPlayer1) public returns(bool success) {
        require(betStructs[gameID].player1 == msg.sender);
        require(Bet(betPlayer1) == Bet.ROCK || Bet(betPlayer1) == Bet.PAPER || Bet(betPlayer1) == Bet.SCISSORS);
        require(Bet(betPlayer1) != Bet.NULL); 
        require(betStructs[gameID].playersNextMoveDeadline > block.number);
        betStructs[gameID].betPlayer1 = Bet(betPlayer1);
        LogPlayer1Move(msg.sender, betPlayer1);
        return true;
    }
    
    function player2Move(bytes32 gameID, Bet betPlayer2) public returns(bool success) {
        require(betStructs[gameID].player2 == msg.sender);
        require(Bet(betPlayer2) == Bet.ROCK || Bet(betPlayer2) == Bet.PAPER || Bet(betPlayer2) == Bet.SCISSORS);
        require(Bet(betPlayer2) != Bet.NULL); 
        require(betStructs[gameID].playersNextMoveDeadline > block.number);
        betStructs[gameID].betPlayer2 = Bet(betPlayer2);
        LogPlayer2Move(msg.sender, betPlayer2);
        return true;
    }
    
    function playBet(bytes32 gameID) public view returns(uint winningPlayer) {
        if (betStructs[gameID].betPlayer1 == betStructs[gameID].betPlayer2) revert();
        if ((betStructs[gameID].betPlayer1 == Bet.PAPER && betStructs[gameID].betPlayer2 == Bet.ROCK)||
            (betStructs[gameID].betPlayer1 == Bet.ROCK && betStructs[gameID].betPlayer2 == Bet.SCISSORS)||
            (betStructs[gameID].betPlayer1 == Bet.SCISSORS && betStructs[gameID].betPlayer2 == Bet.PAPER)||
            (betStructs[gameID].betPlayer1 == Bet.ROCK && betStructs[gameID].betPlayer2 == Bet.SCISSORS)||
            (betStructs[gameID].betPlayer1 == Bet.PAPER && betStructs[gameID].betPlayer2 == Bet.ROCK)||
            (betStructs[gameID].betPlayer1 == Bet.SCISSORS && betStructs[gameID].betPlayer2 == Bet.PAPER)) return 1;
        if ((betStructs[gameID].betPlayer2 == Bet.PAPER && betStructs[gameID].betPlayer1 == Bet.ROCK)||
            (betStructs[gameID].betPlayer2 == Bet.ROCK && betStructs[gameID].betPlayer1 == Bet.SCISSORS)||
            (betStructs[gameID].betPlayer2 == Bet.SCISSORS && betStructs[gameID].betPlayer1 == Bet.PAPER)||
            (betStructs[gameID].betPlayer2 == Bet.ROCK && betStructs[gameID].betPlayer1 == Bet.SCISSORS)||
            (betStructs[gameID].betPlayer2 == Bet.PAPER && betStructs[gameID].betPlayer1 == Bet.ROCK)||
            (betStructs[gameID].betPlayer2 == Bet.SCISSORS && betStructs[gameID].betPlayer1 == Bet.PAPER)) return 2;  
        assert(false);
    }
    
    function awardWinner(bytes32 gameID, address winner) public returns(bool success) {
        require(owner == msg.sender);
        betStructs[gameID].winner = winner;
        betStructs[gameID].playersNextMoveDeadline = 0;
        LogAwardWinner(msg.sender, winner);
        return true;
    }

    function awardBetToWinner(bytes32 passPlayer1, bytes32 passPlayer2) public returns(bool success) {
        bytes32 gameID = getGameID(passPlayer1, passPlayer2);
        betStructs[gameID].amountWinner = betStructs[passPlayer1].amountPlayer1 + betStructs[passPlayer1].amountPlayer2;
        uint amount = betStructs[gameID].amountWinner;
        require(amount != 0);
        betStructs[gameID].amountWinner = 0;
        betStructs[gameID].amountPlayer1 = 0;
        betStructs[gameID].amountPlayer2 = 0;
        betStructs[gameID].player1 = 0x0;
        betStructs[gameID].player2 = 0x0;
        betStructs[gameID].winner = 0x0; 
        LogAwardBet(amount, msg.sender);
        betStructs[gameID].winner.transfer(amount);
        return true;    
    }
}