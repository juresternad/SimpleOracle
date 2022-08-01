// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract JureOracle {


//====================================================================
// Structures
//====================================================================

uint256 currentRound = 0; // globalna spremenljivka, ki belezi stevilo trenutnega runde

struct Round {
    uint commitEndDate; // koncni cas za commit
    uint revealEndDate; // koncni cas za reveal

    mapping (uint256 => Vote) votes; 

    uint256 allWeight;
    uint256[] prices;
    uint256[] indexedVoters;
    
    mapping (uint256 => uint256) changeWeights;

    uint256 oraclePrice; // izracunana povprecje ustreznih glasov
    uint256 oraclePowerPrice; // izracunano tehtano povprecje ustreznih glasov
} 

struct Vote { 
    bytes32 voteHash;
    uint256 vote;
    uint256 salt;
}

struct Voter {
    uint256 weight; // njegova utez
    uint256 currentWeight;
}

Voter[] public voters;

Voter[] public newVoters;

mapping(address => uint256) public mapVoters;
mapping(uint256 => Round) public rounds; // slovar, ki stevilo runde poveze z rundo



address private owner;
  
constructor() {
        owner = msg.sender;
    }

modifier onlyOwner() {
    require(msg.sender == owner);
    _;
}

                                                       
//====================================================================
// Commit/ Reveal
//====================================================================

function commitVote(bytes32 voteHash, uint256 vote, uint256 salt, uint256 roundNumber) public { // funkcija za commit
    uint256 sender = mapVoters[msg.sender];
    require(activeCommit(roundNumber),"Prepozno"); // preveri, ali je trenutno se odprt cas za glasovanje
    require(rounds[roundNumber].votes[sender].voteHash == 0, "Ze glasoval"); // preveri ali je ze glasoval
    rounds[currentRound].votes[sender] =Vote(
            voteHash,
            vote,
            salt
        );
}
    

function revealVote(uint256 roundNumber) public {
    require(activeReveal(roundNumber),"Prepozno");
    uint256 sender = mapVoters[msg.sender];

    bytes32 voteHash = rounds[roundNumber-1].votes[sender].voteHash;
    uint256 salt = rounds[roundNumber-1].votes[sender].salt;
    uint256 vote = rounds[roundNumber].votes[sender].vote;

    if(currentRound>1){
    require(keccak256(abi.encodePacked(vote, salt, msg.sender)) == voteHash,
    "Se ne ujema"); 
    }
    rounds[roundNumber].allWeight += voters[sender].weight;

    rounds[roundNumber].prices.push(vote);
    rounds[roundNumber].indexedVoters.push(sender);
}



function hashh(uint256 ocena, uint256 salt) public view returns (bytes32 khash) { // pomozna funkcija za testiranje
    return keccak256(abi.encodePacked(ocena, salt, msg.sender));
}


//====================================================================
// Rounds
//====================================================================


function startRound(uint256 commitTime, uint256 revealTime) public {
    require (rounds[currentRound].revealEndDate <= block.timestamp); // Preveri, da je commitEndDate prejsnje runde manjsi od trenutnega casa.
    uint256 n = voters.length;
    for (uint i = 0; i < n; i++) {
        if(rounds[currentRound].changeWeights[i] != 0)
        {
            voters[i].weight = rounds[currentRound].changeWeights[i];
        }
        voters[i].currentWeight = voters[i].weight;
    }
    uint256 m = newVoters.length;
    for (uint i = 0; i < m; i++) {
        voters.push(newVoters[i]);
    }
    delete newVoters;
    currentRound += 1;
    rounds[currentRound].commitEndDate = block.timestamp + commitTime * 1 seconds;
    rounds[currentRound].revealEndDate = rounds[currentRound].commitEndDate + revealTime * 1 seconds;
    rounds[currentRound].allWeight = 0;
}


function activeCommit (uint256 roundNumber) public view returns (bool active) {
    require(block.timestamp <= rounds[roundNumber].commitEndDate); // Preveri, da je trenutni cas manjsi od casa commitEndDate v tej rundi.
    return true; 
}


function activeReveal (uint256 roundNumber) public view returns (bool active) {
    require(rounds[roundNumber].commitEndDate <= block.timestamp); //
    require(block.timestamp <= rounds[roundNumber].revealEndDate);  // Preveri, da je trenutni cas manjsi od casa revealEndDate v tej rundi.
    return true;
}


                                          
                                                                                             
                                                                                                
//====================================================================
// OraclePrice (roundNumber)
//====================================================================


function oraclePriceByRoundNumber (uint roundNumber) public view returns(uint256 price) {
    uint256 n = voters.length;
    uint256 computedPrice = 0;
    for (uint i = 0; i < n; i++) {
        computedPrice += rounds[roundNumber].votes[i].vote * voters[i].weight;
    }
    computedPrice = computedPrice/rounds[roundNumber].allWeight;
    return computedPrice;

}

function oraclePriceByPowerByRoundNumber (uint roundNumber) public returns(uint256 price) {
    uint256 n = voters.length;
    uint256 quarter = rounds[roundNumber].allWeight /4;
    uint256 newWeight = rounds[roundNumber].allWeight - 2 * quarter;
    uint256 downBound = quarter;
    uint256 upBound = quarter; 
    uint256[] memory sortedVoters = sort(rounds[roundNumber].prices, rounds[roundNumber].indexedVoters);
    uint256 i = 0;
    uint256 j = n-1;
    while (downBound != 0) {
        uint256 voterOfThisPrice = sortedVoters[i];
        uint256 PowerOfThisVoter = voters[voterOfThisPrice].weight;
        if (PowerOfThisVoter >= downBound) {
            voters[voterOfThisPrice].currentWeight = PowerOfThisVoter - downBound;
            downBound = 0;
        }
        else {
            voters[voterOfThisPrice].currentWeight = 0;
            downBound -= PowerOfThisVoter;
            i +=1;
        }

    }
    while (upBound != 0) {
        uint256 voterOfThisPrice = sortedVoters[j];
        uint256 PowerOfThisVoter = voters[voterOfThisPrice].weight;
        if (PowerOfThisVoter >= downBound) {
            voters[voterOfThisPrice].currentWeight = PowerOfThisVoter - upBound;
            upBound = 0;
        }
        else {
            voters[voterOfThisPrice].currentWeight = 0;
            upBound -= PowerOfThisVoter;
            j -= 1;
        }   

    }
    uint256 computedPowerPrice = 0;
    for (uint k = 0; k < n; k++) {
        computedPowerPrice += rounds[roundNumber].votes[k].vote * voters[k].currentWeight;
    }
    computedPowerPrice = computedPowerPrice/newWeight;
    rounds[roundNumber].oraclePowerPrice = computedPowerPrice;
    return computedPowerPrice;

}


//====================================================================
// Voters
//====================================================================

function addVoter (address voter, uint256 weight) public onlyOwner {
    require(mapVoters[voter] == 0, "Voter already exists");
    uint256 i = voters.length;
    newVoters.push(Voter(weight, weight));
    mapVoters[voter] = i;
}

function changeWeight (uint256 voterIndex, uint256 weight) public onlyOwner {
    require(voters.length >= voterIndex, "Voter doesn't exist");
    rounds[currentRound].changeWeights[voterIndex]= weight;
}
                                 
//====================================================================
// Quicksort
//====================================================================
// sposojeno iz https://ethereum.stackexchange.com/a/1518

function quickSort(uint256[] memory _prices, uint256[] memory _indexedVoters, int left, int right) public {
    int i = left;
    int j = right;
    if (i == j) return;
    uint256 pivot = _prices[uint256(left + (right - left) / 2)];
    while (i <= j) {
        while (_prices[uint256(i)] < pivot) i++;
        while (pivot < _prices[uint256(j)]) j--;
        if (i <= j) {
            (_prices[uint256(i)], _prices[uint256(j)]) = (_prices[uint256(j)], _prices[uint256(i)]);
            (_indexedVoters[uint256(i)], _indexedVoters[uint256(j)]) = (_indexedVoters[uint256(j)], _indexedVoters[uint256(i)]);
            i++;
            j--;
        }
    }
    if (left < j)
        quickSort(_prices, _indexedVoters, left, j);
    if (i < right)
        quickSort(_prices, _indexedVoters, i, right);
}

function sort(uint256[] memory dataPrices, uint256[] memory dataVoters) public returns (uint256[] memory) {
    quickSort(dataPrices, dataVoters, int(0), int(dataPrices.length - 1));
    return (dataVoters);
}














}









                                   
