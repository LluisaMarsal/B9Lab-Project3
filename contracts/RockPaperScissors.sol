pragma solidity ^0.4.19;
 
contract RockPaperScissors {
    
    address public owner;
    
    struct BetBox {
       address player1;
       address player2;
       uint betPlayer1;
       uint betPlayer2;
       uint amountPlayer1;
       uint amountPlayer2;
       uint sumAmounts; 
       uint deadline; 
    }
    
    // for every uint there is a BetBox and those namespaces (struct) will conform a mapping named wagerStructs
    mapping (bytes32 => BetBox) public wagerStructs; 
    
    //event Log
    //event Log
    
    function RockPaperScissors() public {
        owner = msg.sender;
    }
    
    function hashBet(bytes32 passPlayer1, bytes32 passPlayer2) public pure returns(bytes32 hashedBet) {
        return keccak256(passPlayer1, passPlayer2);
    }
    
    function playBet(bytes32 passPlayer1, bytes32 passPlayer2, uint betPlayer1, uint betPlayer2) public returns(bool success) {
        bytes32 hashedBet = hashBet(passPlayer1, passPlayer2);
        BetBox memory b = wagerStructs[hashedBet];
        require(b.amountPlayer1 + b.amountPlayer2 == b.sumAmounts);
        if (b.player1 == b.player2) revert();
        if (b.betPlayer1 == b.betPlayer2) revert();
        //my idea here was to assign numbers to the different betting options, (eg.rock = 1, scissors = 2, paper = 3) 
        //then start comparing the bets to find the winner but seems I am not using the right expression, or maybe this 
        //is not the right strategy at all?
        if (b.betPlayer1=1 && b.betPlayer2=2) {
            b.player1.transfer(b.sumAmounts);
        }
        
        //Log
        //return

    }
}