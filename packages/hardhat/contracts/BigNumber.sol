// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "@fhenixprotocol/cofhe-contracts/FHE.sol";

contract BigNumber {
    address public owner;
    address public player1;
    address public player2;


// store encrypted player input
    euint32 public number1;
    euint32 public number2;
 

    euint32 public difference;
    euint32 public winnerEncrypted;

    constructor() {
        owner = msg.sender;
    }


// Accepts already-encrypted input (from frontend using cofhejs)
function submitNumber(InEuint32 calldata encryptedInput) external {
    require(player1==address(0) || player2==address(0), "Game already started");
    require(msg.sender !=player1 && msg.sender!=player2, "Already submitted");

    if(player1== address(0)){
        player1==msg.sender;
        number1=FHE.asEuint32(encryptedInput);
        FHE.allowThis(number1); // grant contract access
    } else {
        player2==msg.sender;
        number2=FHE.asEuint32(encryptedInput);
        FHE.allowThis(number2); // grant contract access

        computeWinner(); //move logic to internal function 
    }
}


function computeWinner() internal {
    // use FHE comparison encrypted domain
     ebool isP1Greater = FHE.gt(number1, number2);
        ebool isP2Greater = FHE.lt(number1, number2);

               // Difference is also calculated without leaking values
               difference = FHE.sub(FHE.max(number1,number2),FHE.min(number1,number2));

               winnerEncrypted=FHE.select(
                isP1Greater,
                FHE.asEuint32(1),
                FHE.select(isP2Greater,FHE.asEuint32(2),FHE.asEuint32(0))
               );

               FHE.allowSender(difference);
               FHE.allowSender(winnerEncrypted);

}


function getEncryptedResult()external view returns(euint32,euint32){

          require(msg.sender == player1 || msg.sender == player2, "Not a player");

            // Encrypted winner and diff can be unsealed client-side using cofhejs
        return (winnerEncrypted, difference);

}

}