pragma solidity ^0.4.19;
 
contract RockPaperScissors {
    
    address private owner;
    uint constant maxNumberOfBlocks = 1 days / 15;
    uint constant minNumberOfBlocks = 1 hours / 15;
    uint constant maxNextNumberOfBlocks = 1 days / 15;
    uint constant minNextNumberOfBlocks = 1 hours / 15;
    
    enum Bet {NULL, ROCK, PAPER, SCISSORS}
    
    struct BetBox {
       address player1;
       address player2;
       address winner;
       Bet betPlayer1;
       Bet betPlayer2;
       bytes32 hashedPlayer1Move;
       bytes32 hashedPlayer2Move;
       uint amountPlayer1;
       uint amountPlayer2;
       uint amountWinner;
       uint joinDeadline; 
       uint playersNextMoveDeadline;
    }
    
    mapping (bytes32 => BetBox) public betStructs; 
    
    event LogCreateBet(address caller, uint amount, uint numberOfBlocks);
    event LogJoinBet(address caller, uint amount, uint nextNumberOfBlocks);
    event LogPlayBet(address caller, Bet betPlayer1, Bet betPlayer2);
    event LogAwardWinner (address caller, address winner);
    event LogAwardBet(uint amount, address winner);
    
    function RockPaperScissors() public {
        owner = msg.sender;
    }
    
    function getGameID(bytes32 passCreateBet, address player1) public pure returns(bytes32 gameID) {
        return keccak256(passCreateBet, player1);
    }
    
    function createBet(bytes32 gameID, address player2, uint numberOfBlocks) public payable returns(bool success) {
        BetBox memory b = betStructs[gameID];  
        require(b.player1 == 0);
        require(b.amountPlayer1 == 0);
        require(msg.sender != player2); 
        require(numberOfBlocks < maxNumberOfBlocks);
        require(numberOfBlocks > minNumberOfBlocks);
        b.player1 = msg.sender;
        b.player2 = player2;
        b.joinDeadline = block.number + numberOfBlocks;
        b.amountPlayer1 = msg.value;
        LogCreateBet(msg.sender, msg.value, numberOfBlocks);
        return true;
    }
    
    function joinBet(bytes32 gameID, uint nextNumberOfBlocks) public payable returns(bool success) {
        require(betStructs[gameID].amountPlayer2 == 0);
        require(betStructs[gameID].joinDeadline > block.number);
        require(betStructs[gameID].player2 == msg.sender); 
        require(betStructs[gameID].amountPlayer1 == msg.value);
        require(nextNumberOfBlocks < maxNextNumberOfBlocks);
        require(nextNumberOfBlocks > minNextNumberOfBlocks);
        betStructs[gameID].joinDeadline = 0;
        betStructs[gameID].playersNextMoveDeadline = block.number + nextNumberOfBlocks;
        betStructs[gameID].amountPlayer2 = msg.value;
        LogJoinBet(msg.sender, msg.value, nextNumberOfBlocks);
        return true;
    }
    
    function hashPlayerMove(bytes32 passPlayer, Bet betPlayer) public pure returns(bytes32 hashedPlayerMove) {
        return keccak256(passPlayer, betPlayer);
    }
    
    function writePlayerHashedMove(bytes32 hashedPlayerMove, bytes32 gameID) public returns(bool success) {
        require(betStructs[gameID].playersNextMoveDeadline > block.number);
        if (betStructs[gameID].player1 == msg.sender) {
            betStructs[gameID].hashedPlayer1Move = hashedPlayerMove;
        } else if (betStructs[gameID].player2 == msg.sender) {
            betStructs[gameID].hashedPlayer2Move = hashedPlayerMove;
        } else {
            assert(false);
        }
        return true;
    }

    function writePlayerMove(bytes32 passPlayer, Bet betPlayer, bytes32 gameID) public returns(bool success) {
        bytes32 hashedPlayerMove = hashPlayerMove(passPlayer, betPlayer);
        require(betPlayer == Bet.ROCK || betPlayer == Bet.PAPER || betPlayer == Bet.SCISSORS);
        require(betStructs[gameID].playersNextMoveDeadline > block.number);
        if (betStructs[gameID].player1 == msg.sender && betStructs[gameID].hashedPlayer1Move == hashedPlayerMove) {
            betStructs[gameID].betPlayer1 = betPlayer;
        } else if (betStructs[gameID].player2 == msg.sender && betStructs[gameID].hashedPlayer2Move == hashedPlayerMove) {
            betStructs[gameID].betPlayer2 = betPlayer;
        } else {
            assert(false);
        }
        return true;
    }
    
    function playBet(bytes32 passCreateBet, address player1) public view returns(uint winningPlayer) {
        bytes32 gameID = getGameID(passCreateBet, player1);
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
    
    function awardWinner(bytes32 passCreateBet, address player1, bytes32 gameID) public returns(bool success) {
        uint winningPlayer = playBet(passCreateBet, player1);
        address winner;
        if (winningPlayer == 1) {
            winner = betStructs[gameID].player1;
        } else if (winningPlayer == 2) {
            winner = betStructs[gameID].player2;
        } else {
            assert(false);
        }
        betStructs[gameID].winner = winner;
        LogAwardWinner(msg.sender, winner);
        return true;
    }

    function awardBetToWinner(bytes32 gameID) public returns(bool success) {
        require(betStructs[gameID].winner == msg.sender);
        betStructs[gameID].amountWinner = betStructs[gameID].amountPlayer1 + betStructs[gameID].amountPlayer2;
        uint amount = betStructs[gameID].amountWinner;
        require(amount != 0);
        betStructs[gameID].amountWinner = 0;
        betStructs[gameID].amountPlayer1 = 0;
        betStructs[gameID].amountPlayer2 = 0;
        betStructs[gameID].player1 = 0x0;
        betStructs[gameID].player2 = 0x0;
        betStructs[gameID].winner = 0x0; 
        betStructs[gameID].playersNextMoveDeadline = 0;
        LogAwardBet(amount, msg.sender);
        betStructs[gameID].winner.transfer(amount);
        return true;    
    }
}