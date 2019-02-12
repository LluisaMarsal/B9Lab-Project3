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
        BetBox storage b = betStructs[gameID];
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
        BetBox storage b = betStructs[gameID];
        require(b.amountPlayer2 == 0);
        require(b.joinDeadline > block.number);
        require(b.player2 == msg.sender); 
        require(b.amountPlayer1 == msg.value);
        require(nextNumberOfBlocks < maxNextNumberOfBlocks);
        require(nextNumberOfBlocks > minNextNumberOfBlocks);
        b.joinDeadline = 0;
        b.playersNextMoveDeadline = block.number + nextNumberOfBlocks;
        b.amountPlayer2 = msg.value;
        LogJoinBet(msg.sender, msg.value, nextNumberOfBlocks);
        return true;
    }
    
    function hashPlayerMove(bytes32 passPlayer, Bet betPlayer) public pure returns(bytes32 hashedPlayerMove) {
        return keccak256(passPlayer, betPlayer);
    }
    
    function writePlayerHashedMove(bytes32 hashedPlayerMove, bytes32 gameID) public returns(bool success) {
        BetBox storage b = betStructs[gameID];
        require(b.playersNextMoveDeadline > block.number);
        if (b.player1 == msg.sender) {
            b.hashedPlayer1Move = hashedPlayerMove;
        } else if (b.player2 == msg.sender) {
            b.hashedPlayer2Move = hashedPlayerMove;
        } else {
            assert(false);
        }
        return true;
    }

    function writePlayerMove(bytes32 passPlayer, Bet betPlayer, bytes32 gameID) public returns(bool success) {
        bytes32 hashedPlayerMove = hashPlayerMove(passPlayer, betPlayer);
        BetBox storage b = betStructs[gameID];
        require(betPlayer == Bet.ROCK || betPlayer == Bet.PAPER || betPlayer == Bet.SCISSORS);
        require(b.playersNextMoveDeadline > block.number);
        if (b.player1 == msg.sender && b.hashedPlayer1Move == hashedPlayerMove) {
            b.betPlayer1 = betPlayer;
        } else if (b.player2 == msg.sender && b.hashedPlayer2Move == hashedPlayerMove) {
            b.betPlayer2 = betPlayer;
        } else {
            assert(false);
        }
        return true;
    }
    
    function playBet(bytes32 passCreateBet, address player1) public view returns(uint winningPlayer) {
        bytes32 gameID = getGameID(passCreateBet, player1);
        BetBox storage b = betStructs[gameID];
        if (b.betPlayer1 == b.betPlayer2) revert();
        if ((b.betPlayer1 == Bet.PAPER && b.betPlayer2 == Bet.ROCK)||
            (b.betPlayer1 == Bet.ROCK && b.betPlayer2 == Bet.SCISSORS)||
            (b.betPlayer1 == Bet.SCISSORS && b.betPlayer2 == Bet.PAPER)||
            (b.betPlayer1 == Bet.ROCK && b.betPlayer2 == Bet.SCISSORS)||
            (b.betPlayer1 == Bet.PAPER && b.betPlayer2 == Bet.ROCK)||
            (b.betPlayer1 == Bet.SCISSORS && b.betPlayer2 == Bet.PAPER)) return 1;
        if ((b.betPlayer2 == Bet.PAPER && b.betPlayer1 == Bet.ROCK)||
            (b.betPlayer2 == Bet.ROCK && b.betPlayer1 == Bet.SCISSORS)||
            (b.betPlayer2 == Bet.SCISSORS && b.betPlayer1 == Bet.PAPER)||
            (b.betPlayer2 == Bet.ROCK && b.betPlayer1 == Bet.SCISSORS)||
            (b.betPlayer2 == Bet.PAPER && b.betPlayer1 == Bet.ROCK)||
            (b.betPlayer2 == Bet.SCISSORS && b.betPlayer1 == Bet.PAPER)) return 2; 
        assert(false);
    }
    
    function awardWinner(bytes32 passCreateBet, address player1, bytes32 gameID) public returns(bool success) {
        uint winningPlayer = playBet(passCreateBet, player1);
        BetBox storage b = betStructs[gameID];
        address winner;
        if (winningPlayer == 1) {
            winner = b.player1;
        } else if (winningPlayer == 2) {
            winner = b.player2;
        } else {
            assert(false);
        }
        b.winner = winner;
        LogAwardWinner(msg.sender, winner);
        return true;
    }

    function awardBetToWinner(bytes32 gameID) public returns(bool success) {
        BetBox storage b = betStructs[gameID];
        require(b.winner == msg.sender);
        b.amountWinner = b.amountPlayer1 + b.amountPlayer2;
        uint amount = b.amountWinner;
        require(amount != 0);
        b.amountWinner = 0;
        b.amountPlayer1 = 0;
        b.amountPlayer2 = 0;
        b.player1 = 0x0;
        b.player2 = 0x0;
        b.winner = 0x0; 
        b.playersNextMoveDeadline = 0;
        LogAwardBet(amount, msg.sender);
        b.winner.transfer(amount);
        return true;    
    }
}