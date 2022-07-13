// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

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

Round[] public rounds;
Voter[] public voters;

///////////////////////////////////////////////////////////////////////////////////////////////
function commitVote{}


function revealVote{}
















}