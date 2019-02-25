pragma solidity ^0.4.19;
 
contract RockPaperScissors {
    
    address private owner;
    uint constant maxNumberOfBlocks = 1 days / 15;
    uint constant minNumberOfBlocks = 1 hours / 15;
    uint constant maxNextNumberOfBlocks = 1 days / 15;
    uint constant minNextNumberOfBlocks = 1 hours / 15;
    uint constant maxblockDifferenceToPassBets = 1 days / 15;
    uint constant minblockDifferenceToPassBets = 1 hours / 15;
    uint constant maxblockDifferenceToAward = 1 days / 15;
    uint constant minblockDifferenceToAward = 1 hours / 15;
    
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
       uint writeHashedBetDeadline;
       uint writeClearBetDeadline; 
    }
    
    mapping (bytes32 => BetBox) public betStructs; 
    
    event LogCreateBet(bytes32 gameID, address caller, uint amount, uint numberOfBlocks, uint nextNumberOfBlocks, uint blockDifferenceToPassBets, uint blockDifferenceToAward);
    event LogJoinBet(bytes32 gameID, address caller, uint amount);
    event LogWritePlayerHashedMove(bytes32 gameID, bytes32 hashedPlayerMove, address caller);
    event LogWritePlayerMove(bytes32 gameID, bytes32 passPlayer, Bet betPlayer, address caller);
    event LogAwardWinner(bytes32 gameID, address caller, address winner);
    event LogAwardBet(bytes32 gameID, uint amount, address caller);
    event LogCancelBet(bytes32 gameID, uint amount, address caller);
    
    function RockPaperScissors() public {
        owner = msg.sender;
    }
    
    function getGameID(bytes32 passCreateBet, address player1) public pure returns(bytes32 gameID) {
        return keccak256(passCreateBet, player1);
    }
    
    function createBet(bytes32 gameID, address player2, uint numberOfBlocks, uint nextNumberOfBlocks, uint blockDifferenceToPassBets, uint blockDifferenceToAward) public payable returns(bool success) {
        BetBox storage betBox = betStructs[gameID];
        require(betBox.player1 == 0);
        require(betBox.amountPlayer1 == 0);
        require(msg.sender != player2); 
        require(numberOfBlocks < maxNumberOfBlocks);
        require(numberOfBlocks > minNumberOfBlocks);
        require(nextNumberOfBlocks < maxNextNumberOfBlocks);
        require(nextNumberOfBlocks > minNextNumberOfBlocks);
        require(blockDifferenceToPassBets < maxblockDifferenceToPassBets);
        require(blockDifferenceToPassBets > minblockDifferenceToPassBets);
        require(blockDifferenceToAward < maxblockDifferenceToAward);
        require(blockDifferenceToAward > minblockDifferenceToAward);
        require(block.number > 10);
        betBox.player1 = msg.sender;
        betBox.player2 = player2;
        betBox.joinDeadline = block.number + numberOfBlocks;
        betBox.playersNextMoveDeadline = block.number + nextNumberOfBlocks;
        betBox.writeHashedBetDeadline = block.number + blockDifferenceToPassBets;
        betBox.writeClearBetDeadline = block.number + blockDifferenceToAward;
        betBox.amountPlayer1 = msg.value;
        LogCreateBet(gameID, msg.sender, msg.value, numberOfBlocks, nextNumberOfBlocks, blockDifferenceToPassBets, blockDifferenceToAward);
        return true;
    }
    
    function joinBet(bytes32 gameID) public payable returns(bool success) {
        BetBox storage betBox = betStructs[gameID];
        require(betBox.amountPlayer2 == 0);
        require(betBox.joinDeadline > block.number);
        require(betBox.player2 == msg.sender); 
        require(betBox.amountPlayer1 == msg.value);
        betBox.joinDeadline = 0;
        betBox.amountPlayer2 = msg.value;
        LogJoinBet(gameID, msg.sender, msg.value);
        return true;
    }
    
    function hashPlayerMove(bytes32 passPlayer, Bet betPlayer) public pure returns(bytes32 hashedPlayerMove) {
        return keccak256(passPlayer, betPlayer);
    }
    
    function writePlayerHashedMove(bytes32 gameID, bytes32 hashedPlayerMove) public returns(bool success) {
        BetBox storage betBox = betStructs[gameID];
        require(betBox.playersNextMoveDeadline > block.number);
        if (betBox.player1 == msg.sender) {
            betBox.hashedPlayer1Move = hashedPlayerMove;
        } else if (betBox.player2 == msg.sender) {
            betBox.hashedPlayer2Move = hashedPlayerMove;
        } else {
            assert(false);
        }
        LogWritePlayerHashedMove(gameID, hashedPlayerMove, msg.sender);
        return true;
    }

    function writePlayerMove(bytes32 gameID, bytes32 passPlayer, Bet betPlayer) public returns(bool success) {
        bytes32 hashedPlayerMove = hashPlayerMove(passPlayer, betPlayer);
        BetBox storage betBox = betStructs[gameID];
        require(betPlayer == Bet.ROCK || betPlayer == Bet.PAPER || betPlayer == Bet.SCISSORS);
        require(betBox.writeHashedBetDeadline > block.number);
        if (betBox.player1 == msg.sender && betBox.hashedPlayer1Move == hashedPlayerMove) {
            betBox.betPlayer1 = betPlayer;
        } else if (betBox.player2 == msg.sender && betBox.hashedPlayer2Move == hashedPlayerMove) {
            betBox.betPlayer2 = betPlayer;
        } else {
            assert(false);
        }
        LogWritePlayerMove(gameID, passPlayer, betPlayer, msg.sender);
        return true;
    }
    
    function playBet(bytes32 passCreateBet, address player1) public view returns(uint winningPlayer) {
        bytes32 gameID = getGameID(passCreateBet, player1);
        BetBox storage betBox = betStructs[gameID];
        if (betBox.betPlayer1 == betBox.betPlayer2) return 0;
        if ((betBox.betPlayer1 == Bet.PAPER && betBox.betPlayer2 == Bet.ROCK)||
            (betBox.betPlayer1 == Bet.ROCK && betBox.betPlayer2 == Bet.SCISSORS)||
            (betBox.betPlayer1 == Bet.SCISSORS && betBox.betPlayer2 == Bet.PAPER)||
            (betBox.betPlayer1 == Bet.ROCK && betBox.betPlayer2 == Bet.SCISSORS)||
            (betBox.betPlayer1 == Bet.PAPER && betBox.betPlayer2 == Bet.ROCK)||
            (betBox.betPlayer1 == Bet.SCISSORS && betBox.betPlayer2 == Bet.PAPER)) return 1;
        if ((betBox.betPlayer2 == Bet.PAPER && betBox.betPlayer1 == Bet.ROCK)||
            (betBox.betPlayer2 == Bet.ROCK && betBox.betPlayer1 == Bet.SCISSORS)||
            (betBox.betPlayer2 == Bet.SCISSORS && betBox.betPlayer1 == Bet.PAPER)||
            (betBox.betPlayer2 == Bet.ROCK && betBox.betPlayer1 == Bet.SCISSORS)||
            (betBox.betPlayer2 == Bet.PAPER && betBox.betPlayer1 == Bet.ROCK)||
            (betBox.betPlayer2 == Bet.SCISSORS && betBox.betPlayer1 == Bet.PAPER)) return 2; 
        assert(false);
    }
    
    function awardWinner(bytes32 passCreateBet, address player1) public returns(bool success) {
        uint winningPlayer = playBet(passCreateBet, player1);
        bytes32 gameID = getGameID(passCreateBet, player1);
        BetBox storage betBox = betStructs[gameID];
        address winner;
        if (winningPlayer == 1) {
            winner = betBox.player1;
        } else if (winningPlayer == 2) {
            winner = betBox.player2;
        } else if (winningPlayer == 0) {
            assert(false);
        } else {
            assert(false);
        }
        betBox.winner = winner;
        LogAwardWinner(gameID, msg.sender, winner);
        return true;
    }

    function awardBetToWinner(bytes32 gameID) public returns(bool success) {
        BetBox storage betBox = betStructs[gameID];
        require(betBox.winner == msg.sender);
        require(betBox.writeClearBetDeadline > block.number);
        betBox.amountWinner = betBox.amountPlayer1 + betBox.amountPlayer2;
        uint amount = betBox.amountWinner;
        require(amount != 0);
        betBox.amountWinner = 0;
        betBox.amountPlayer1 = 0;
        betBox.amountPlayer2 = 0;
        betBox.player1 = 0x0;
        betBox.player2 = 0x0;
        betBox.winner = 0x0;
        betBox.playersNextMoveDeadline = 0;
        betBox.writeHashedBetDeadline = 0;
        betBox.writeClearBetDeadline = 0; 
        LogAwardBet(gameID, amount, msg.sender);
        msg.sender.transfer(amount);
        return true;    
    }
    
    function cancelBet(bytes32 gameID) public returns(bool success) {
        BetBox storage betBox = betStructs[gameID];
        require(betBox.player1 == msg.sender || betBox.player2 == msg.sender);
        require(((betBox.betPlayer1 == Bet.ROCK) && (betBox.betPlayer2 == Bet.ROCK)) || 
                ((betBox.betPlayer1 == Bet.PAPER) && (betBox.betPlayer2 == Bet.PAPER)) || 
                ((betBox.betPlayer1 == Bet.SCISSORS) && (betBox.betPlayer2 == Bet.SCISSORS)));
        uint amountPlayer1 = betBox.amountPlayer1;
        uint amountPlayer2 = betBox.amountPlayer2;
        uint amount = (amountPlayer1 + amountPlayer2) / 2;
        if (betBox.player1 == msg.sender) {
            betBox.player1 = 0x0;
            betBox.amountPlayer1 = 0;
        } else if (betBox.player2 == msg.sender) {
            betBox.player2 = 0x0;
            betBox.amountPlayer2 = 0;
        } else {
            assert(false);
        }      
        betBox.playersNextMoveDeadline = 0;
        betBox.writeHashedBetDeadline = 0;
        betBox.writeClearBetDeadline = 0; 
        LogCancelBet(gameID, amount, msg.sender);
        msg.sender.transfer(amount);
        return true;
    }
}