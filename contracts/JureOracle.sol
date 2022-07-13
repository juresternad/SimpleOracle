// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract JureOracle {

struct Round {
    uint commitEndDate;    
    uint revealEndDate;  

    mapping (address => bytes32) hashes; // shranjuje dodan hash posameznega naslova
    mapping (address => bool) hashCommiters; // shranjuje true za naslov, ki je ze dal hash

    mapping (address => bool) doesMatch; // shranjuje true za naslov, kateremu se ujemata hash in glas
    mapping (address => bool) doesnotMatch; // shranjuje vrednosti glasov, ki se ne ujemajo
    mapping (address => uint256) correctVotes; // shranjuje vrednosti glasov, ki se ujemajo 

    mapping (address => uint256) votes; // shranjuje dodan glas posameznega naslova
    mapping (address => bool) voteCommiters; // shranjuje true za naslov, ki je ze dal glas

    uint256 oraclePrice; // izracunana cena (tehtano povprecje) ustreznih glasov
} 

struct Voter {
    uint256 weight;
    mapping (uint256 => bytes32) hashes;
    mapping (uint256 => uint256) votes;
}


mapping(uint256 => Round) public rounds;
mapping(address => Voter) public voters;

// Round[] public rounds;
// Voter[] public voters;

///////////////////////////////////////////////////////////////////////////////////////////////
function commitVote(bytes32 voteHash, uint256 roundNumber) public {
    require(activeCommit(roundNumber));
    require(voters[msg.sender].hashes[roundNumber] == 0);
    voters[msg.sender].hashes[roundNumber] = voteHash;
    rounds[roundNumber].hashes[msg.sender] = voteHash;
}
    

function revealVote(uint256 vote, uint256 salt, uint256 roundNumber) public {
    require(activeReveal(roundNumber));
    require(voters[msg.sender].votes[roundNumber] == 0);
    require(keccak256(abi.encodePacked(vote, salt)) == rounds[roundNumber].hashes[msg.sender],
    "Se ne ujema"); 
    rounds[roundNumber].doesMatch[msg.sender] = true;
    voters[msg.sender].votes[roundNumber] = vote;
    rounds[roundNumber].votes[msg.sender] = vote;
}

function hashh(uint256 ocena, uint256 salt) public pure returns (bytes32 khash) {
    return keccak256(abi.encodePacked(ocena, salt));
}

///////////////////////////////////////////////////////////////////////////////////////////////
function startRound(uint256 roundNumber, uint256 commitTime, uint revealTime) public {
    rounds[roundNumber].commitEndDate = block.timestamp + commitTime * 1 seconds;
    rounds[roundNumber].revealEndDate = rounds[roundNumber].commitEndDate + revealTime * 1 seconds;

}


function activeCommit (uint roundNumber) public view returns (bool active) {
    require(block.timestamp <= rounds[roundNumber].commitEndDate); // Preveri, da je trenutni cas manjsi od casa commitEndDate v tej rundi.
    require (rounds[roundNumber-1].commitEndDate <= block.timestamp); // Preveri, da je commitEndDate prejsnje runde manjsi od trenutnega casa.
    return true;
}


function activeReveal (uint roundNumber) public view returns (bool active) {
    require (block.timestamp <= rounds[roundNumber].revealEndDate);  // Preveri, da je trenutni cas manjsi od casa revealEndDate v tej rundi.
    require (rounds[roundNumber-1].revealEndDate <= block.timestamp); // Preveri, da je revealEndDate prejsnje runde manjsi od trenutnega casa.
    return true;
}
///////////////////////////////////////////////////////////////////////////////////////////////
















}