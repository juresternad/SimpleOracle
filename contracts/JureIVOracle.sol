// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract JureIVOracle {


//====================================================================
// Errors
//====================================================================
string internal constant NOT_OWNER = "You are not the owner";
string internal constant ERR_COMMIT_NOT_ACTIVE = "Commit phase for chosen round not active";
string internal constant ERR_REVEAL_NOT_ACTIVE = "Reveal phase for chosen round not active";
string internal constant ERR_HASH_DOES_NOT_MATCH = "Hash doesn't match with vote and salt";
string internal constant ERR_PREVIOUS_ROUND_STILL_ACTIVE = "Previous round still active";
string internal constant ERR_ALREADY_VOTED = "You have already voted for this round";
string internal constant ERR_COMMIT_NO_WEIGHT = "You are not allowed to vote";

//====================================================================
// Structures
//====================================================================

uint256 public currentRound = 0; // globalna spremenljivka, ki belezi stevilo trenutnega runde

struct Round {
    uint commitEndDate; // koncni cas za commit
    uint revealEndDate; // koncni cas za reveal

    mapping (address => Vote) votes; 
    
    uint256 weightedMedianPrice;

    address[] revealedVoters; 

} 

struct Vote { 
    bytes32 voteHash;
    uint256 vote;
    uint128 weight;
}

// struct Voter {
//     uint256 weight; // njegova utez
//     uint256 currentWeight;
// }

// Voter[] public newVoters;

// mapping(address => uint256) public mapVoters;
mapping(uint256 => Round) public rounds; // slovar, ki stevilo runde poveze z rundo

mapping(address => uint128) public weights;

address[] public voters;

address public owner;
  
constructor() {
        owner = msg.sender;
    }

modifier onlyOwner() {
    require(msg.sender == owner, NOT_OWNER);
    _;
}

                                                       
//====================================================================
// Commit/ Reveal
//====================================================================

function commitVote(bytes32 _voteHash, uint256 roundNumber) public { // funkcija za commit
    require(activeCommit(roundNumber),ERR_COMMIT_NOT_ACTIVE); // preveri, ali je trenutno se odprt cas za glasovanje
    require(weights[msg.sender] != 0,ERR_COMMIT_NO_WEIGHT);
    require(rounds[roundNumber].votes[msg.sender].voteHash == 0, ERR_ALREADY_VOTED); // preveri ali je ze glasoval
    rounds[currentRound].votes[msg.sender].voteHash = _voteHash;
}
    

function revealVote(uint256 _vote, uint256 _salt, uint256 roundNumber) public {
    require(activeReveal(roundNumber),ERR_REVEAL_NOT_ACTIVE);
    require(weights[msg.sender] != 0,ERR_COMMIT_NO_WEIGHT);
    bytes32 voteHash = rounds[roundNumber].votes[msg.sender].voteHash;

    require(keccak256(abi.encodePacked(_vote, _salt, msg.sender)) == voteHash,
    ERR_HASH_DOES_NOT_MATCH); 


    rounds[roundNumber].votes[msg.sender].vote = _vote;
    rounds[roundNumber].votes[msg.sender].weight = weights[msg.sender];
    rounds[roundNumber].votes[msg.sender].voteHash = 0;

    rounds[roundNumber].revealedVoters.push(msg.sender);



}



function hashh(uint128 ocena, uint128 salt) public view returns (bytes32 khash) { // pomozna funkcija za testiranje
    return keccak256(abi.encodePacked(ocena, salt, msg.sender));
}


//====================================================================
// Rounds
//====================================================================


function startRound(uint256 commitTime, uint256 revealTime) public onlyOwner {
    require (rounds[currentRound].revealEndDate <= block.timestamp, ERR_PREVIOUS_ROUND_STILL_ACTIVE); // Preveri, da je commitEndDate prejsnje runde manjsi od trenutnega casa.
    currentRound += 1;
    rounds[currentRound].commitEndDate = block.timestamp + commitTime * 1 seconds;
    rounds[currentRound].revealEndDate = rounds[currentRound].commitEndDate + revealTime * 1 seconds;
}


function activeCommit (uint256 roundNumber) public view returns (bool active) {
    if(block.timestamp <= rounds[roundNumber].commitEndDate) // Preveri, da je trenutni cas manjsi od casa commitEndDate v tej rundi.
    return true; 
}


function activeReveal (uint256 roundNumber) public view returns (bool active) {
    if(rounds[roundNumber].commitEndDate <= block.timestamp) //
    if(block.timestamp <= rounds[roundNumber].revealEndDate)  // Preveri, da je trenutni cas manjsi od casa revealEndDate v tej rundi.
    return true;
}

//====================================================================
// Voters
//====================================================================

function addOrUpdate (address voter, uint128 weight) public onlyOwner {
    if(weight == 0){
        weights[voter] = 0;
        for (uint256 i; i<voters.length; i++) {
            if (voters[i] == voter) {
                voters[i] = voters[voters.length - 1];
                voters.pop();
                break;
            }
        }
    }
    if(weights[voter] != 0) {
        weights[voter] = weight;
    }
    else {
        voters.push(voter);
        weights[voter] = weight;
    }

}                           

//====================================================================
// WeightedMedian
//====================================================================

// struct Vars {            
//     uint256 leftSum;            
//     uint256 rightSum;           
//     uint256 newLeftSum;         
//     uint256 newRightSum;        
//     uint256 pivotWeight;        
//     uint256 pos;                
//     uint256 left;               
//     uint256 right;              
//     uint256 pivotId;            
//     uint256 leftMedianWeight;   
//     uint256 rightMedianWeight; 
// }

// function weightedMedian() public returns (uint256 weightedMedianPrice){
//     if(rounds[currentRound].weightedMedianPrice != 0) {
//         return rounds[currentRound].weightedMedianPrice;
//     }
//     uint256 count = rounds[currentRound].indexedPrices.length;
//     for (uint256 i = 0; i < count; i++) {
//         rounds[currentRound].index[i] = i;
//     }
//     (uint256 medianIndex, uint256 leftSum, uint256 rightSum) = modifiedQuickSelect(
//         0,
//         count - 1,
//         0,
//         0
//     );
//     uint256 medianWeight = rounds[currentRound].indexedWeights[rounds[currentRound].index[medianIndex]];
//     uint256 totalSum = medianWeight + leftSum + rightSum;
//     uint256 finalMedianPrice = rounds[currentRound].indexedPrices[rounds[currentRound].index[medianIndex]];
//     if (leftSum + medianWeight == totalSum / 2 && totalSum % 2 == 0) {
//         finalMedianPrice =
//             (finalMedianPrice + rounds[currentRound].indexedPrices[rounds[currentRound].index[medianIndex + 1]]) / 2;
//     }
//     return finalMedianPrice;
// }

// function modifiedQuickSelect(
//     uint256 start,
//     uint256 end,
//     uint256 leftSumInit,
//     uint256 rightSumInit
//     )
//     internal view returns (uint256, uint256, uint256)
//     {
//     if (start == end) {
//         return (start, leftSumInit, rightSumInit);
//     }
//     Vars memory s;
//     s.leftSum = leftSumInit;
//     s.rightSum = rightSumInit;
//     s.left = start;
//     s.right = end;
//     uint256 random = uint256(keccak256(abi.encode(block.difficulty, block.timestamp)));
//     uint256 totalSum; 
//     while (true) {
//         (s.pos,s.newLeftSum,s.newRightSum) = partition(
//             s.left,
//             s.right,
//             (random % (s.right - s.left + 1)) + s.left,
//             s.leftSum,
//             s.rightSum
//         );
        
//         s.pivotId = rounds[currentRound].index[s.pos];
//         s.pivotWeight = rounds[currentRound].indexedWeights[s.pivotId];
//         totalSum = s.pivotWeight + s.newLeftSum + s.newRightSum;

//         s.leftMedianWeight = totalSum / 2 + (totalSum % 2);  
//         s.rightMedianWeight = totalSum - s.leftMedianWeight; 
//         if (s.newLeftSum >= s.leftMedianWeight && s.leftMedianWeight > s.leftSum) { 
//             s.right = s.pos - 1;
//             s.rightSum = s.pivotWeight + s.newRightSum;
//         } else if (s.newRightSum > s.rightMedianWeight && s.rightMedianWeight > s.rightSum) {
//             s.left = s.pos + 1;
//             s.leftSum = s.pivotWeight + s.newLeftSum;
//         } else {
//             return (s.pos, s.newLeftSum, s.newRightSum);
//         }

//     }

//     return (0, 0, 0);
// }

// function partition(
//     uint256 left0,
//     uint256 right0,
//     uint256 pivotId,
//     uint256 leftSum0, 
//     uint256 rightSum0

// )
//     internal view returns (uint256, uint256, uint256)
// {
//     uint256[] memory sums = new uint256[](2);
//     sums[0] = leftSum0;
//     sums[1] = rightSum0;
//     uint256 left = left0;
//     uint256 right = right0;
//     uint256 pivotValue = rounds[currentRound].indexedPrices[rounds[currentRound].index[pivotId]];
//     swap(pivotId, right, rounds[currentRound].index);
//     uint256 storeIndex = left;
//     for (uint256 i = left; i < right; i++) {
//         uint256 eltId = rounds[currentRound].index[i];
//         if (rounds[currentRound].indexedPrices[eltId] < pivotValue) {
//             sums[0] += rounds[currentRound].indexedWeights[eltId];
//             swap(storeIndex, i, rounds[currentRound].index);
//             storeIndex++;
//         } else {
//             sums[1] += rounds[currentRound].indexedWeights[eltId];
//         }
//     }
//     swap(right, storeIndex, rounds[currentRound].index);
//     return (storeIndex, sums[0], sums[1]);
// }

// function swap(uint256 i, uint256 j, uint256[] memory index) internal pure {
//     if (i == j) return;
//     (index[i], index[j]) = (index[j], index[i]);
// }


}