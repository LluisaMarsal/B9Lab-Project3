pragma solidity ^0.4.19;
 
contract RockPaperScissors {
    
    address public owner;
    
    struct BetBox {
       address player1;
       address player2;
       uint amount;
       uint deadline; 
    }
    
    // for every uint there is a BetBox and those namespaces (struct) will conform a mapping named wagerStructs
    mapping (bytes32 => BetBox) public wagerStructs; 
    
    //event Log
    //event Log
    
    function RockPaperScissors() public {
        owner = msg.sender;
    }
    
    function createBet(bytes32 bet1, bytes32 bet2) public pure returns(bytes32 hashedBet) {
        return keccak256(bet1, bet2);
    }
    
    function resolveBet(bytes32 bet1, bytes32 bet2, address player1, address player2) public {
        bytes32 hashedBet = createBet(bet1, bet2);
        require(wagerStructs[hashedBet].player1 == player1);
        require(wagerStructs[hashedBet].player2 == player2);
        if(hashedBet = 0x62b68a23e06d3238a6c5fd1b3f1ae7a7a7131a02fb0185d6ec4f5c529a1ad3ad) {
        }
        //Log
        //return
    }
}