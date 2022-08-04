// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract JureOracle {

struct Round {
    uint commitEndDate;    
    uint revealEndDate;  

    mapping (address => bytes32) hashes; // shranjuje dodan hash posameznega naslova
    mapping (address => bool) hashCommiters; // shranjuje true za naslov, ki je ze dal hash

    mapping (address => uint256) votes; // shranjuje dodan glas posameznega naslova
    address[] correctVoteCommiters; // 
    mapping (address => bool) doesMatch; // shranjuje true za naslov, kateremu se ujemata hash in glas


    mapping(uint256 => address) priceToVoter;
    uint256[] prices;
    mapping (address => uint256) currentVotePowerOfThisVoter; // 

    uint256 allWeight;

    uint256 oraclePrice; // izracunana cena (tehtano povprecje) ustreznih glasov
    uint256 oraclePowerPrice;
} 

struct Voter {
    uint256 weight;
    mapping (uint256 => bytes32) hashes;
    mapping (uint256 => uint256) votes;
    mapping (address => uint256) delegators;
}


mapping(uint256 => Round) public rounds;
mapping(address => Voter) public voters;
mapping(address => bool) public isVoter;

// Round[] public rounds;
// Voter[] public voters;

///////////////////////////////////////////////////////////////////////////////////////////////
function commitVote(bytes32 voteHash, uint256 roundNumber) public {
    require(isVoter[msg.sender], "Ni voter");
    require(activeCommit(roundNumber),"Prepozno");
    require(voters[msg.sender].hashes[roundNumber] == 0, "Ze glasoval");
    voters[msg.sender].hashes[roundNumber] = voteHash;
    rounds[roundNumber].hashes[msg.sender] = voteHash;
}
    

function revealVote(uint256 vote, uint256 salt, uint256 roundNumber) public {
    require(isVoter[msg.sender],"Ni voter");
    require(activeReveal(roundNumber),"Prepozno");
    require(voters[msg.sender].votes[roundNumber] == 0, "Ze glasoval");
    require(keccak256(abi.encodePacked(vote, salt)) == rounds[roundNumber].hashes[msg.sender],
    "Se ne ujema"); 
    rounds[roundNumber].doesMatch[msg.sender] = true;
    voters[msg.sender].votes[roundNumber] = vote;
    rounds[roundNumber].votes[msg.sender] = vote;
    rounds[roundNumber].correctVoteCommiters.push(msg.sender);
    rounds[roundNumber].allWeight += voters[msg.sender].weight;
    rounds[roundNumber].priceToVoter[vote] = msg.sender;
    rounds[roundNumber].currentVotePowerOfThisVoter[msg.sender] = voters[msg.sender].weight;
    rounds[roundNumber].prices.push(vote);
}

function hashh(uint256 ocena, uint256 salt) public pure returns (bytes32 khash) { // pomozna funkcija za testiranje
    return keccak256(abi.encodePacked(ocena, salt));
}

///////////////////////////////////////////////////////////////////////////////////////////////
function startRound(uint256 roundNumber, uint256 commitTime, uint256 revealTime) public {
    rounds[roundNumber].commitEndDate = block.timestamp + commitTime * 1 seconds;
    rounds[roundNumber].revealEndDate = rounds[roundNumber].commitEndDate + revealTime * 1 seconds;
    rounds[roundNumber].allWeight = 0;
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

function oraclePrice (uint roundNumber) public view returns(uint256 price) {
    uint256 n = rounds[roundNumber].correctVoteCommiters.length;
    uint256 computedPrice = 0;
    for (uint i = 0; i < n; i++) {
        address voter = rounds[roundNumber].correctVoteCommiters[i];
        computedPrice += rounds[roundNumber].votes[voter];
    }
    computedPrice = computedPrice/n;
    return computedPrice;

}

function oraclePriceByPower (uint roundNumber) public returns(uint256 price) {
    uint256 n = rounds[roundNumber].correctVoteCommiters.length;
    uint256 quarter = rounds[roundNumber].allWeight /4;
    uint256 newWeight = rounds[roundNumber].allWeight - 2 * quarter;
    uint256 downBound = quarter;
    uint256 upBound = quarter;
    uint256[] memory sortedPrices = sort(rounds[roundNumber].prices);
    uint256 i = 0;
    uint256 j = n-1;
    while (downBound != 0) {
        uint256 candidatePrice = sortedPrices[i];
        address voterOfThisPrice = rounds[roundNumber].priceToVoter[candidatePrice];
        uint256 PowerOfThisVoter = rounds[roundNumber].currentVotePowerOfThisVoter[voterOfThisPrice];
        if (PowerOfThisVoter >= downBound) {
            rounds[roundNumber].currentVotePowerOfThisVoter[voterOfThisPrice] = PowerOfThisVoter - downBound;
            downBound = 0;
        }
        else {
            rounds[roundNumber].currentVotePowerOfThisVoter[voterOfThisPrice] = 0;
            downBound -= PowerOfThisVoter;
            i +=1;
        }

    }
    while (upBound != 0) {
        uint256 candidatePrice = sortedPrices[j];
        address voterOfThisPrice = rounds[roundNumber].priceToVoter[candidatePrice];
        uint256 PowerOfThisVoter = rounds[roundNumber].currentVotePowerOfThisVoter[voterOfThisPrice];
        if (PowerOfThisVoter >= downBound) {
            rounds[roundNumber].currentVotePowerOfThisVoter[voterOfThisPrice] = PowerOfThisVoter - upBound;
            upBound = 0;
        }
        else {
            rounds[roundNumber].currentVotePowerOfThisVoter[voterOfThisPrice] = 0;
            upBound -= PowerOfThisVoter;
            j -= 1;
        }   

    }
    uint256 computedPowerPrice = 0;
    for (uint k = 0; k < n; k++) {
        address voter = rounds[roundNumber].correctVoteCommiters[k];
        computedPowerPrice += rounds[roundNumber].votes[voter] * rounds[roundNumber].currentVotePowerOfThisVoter[voter];
    }
    computedPowerPrice = computedPowerPrice/newWeight;
    rounds[roundNumber].oraclePowerPrice = computedPowerPrice;
    return computedPowerPrice;

}


///////////////////////////////////////////////////////////////////////////////////////////////

function becomeVoter () public {
    require(isVoter[msg.sender] == false, "Voter already exists");
    isVoter[msg.sender] = true;
    voters[msg.sender].weight = 0;
}

function delegateVotes (uint256 votePower, address voterAddress) public {
    voters[voterAddress].weight += votePower;
    voters[voterAddress].delegators[msg.sender] = votePower;
}


///////////////////////////////////////////////////////////////////////////////////////////////
// sposojeno iz https://ethereum.stackexchange.com/a/1518

function quickSort(uint256[] memory arr, int left, int right) public {
    int i = left;
    int j = right;
    if (i == j) return;
    uint256 pivot = arr[uint256(left + (right - left) / 2)];
    while (i <= j) {
        while (arr[uint256(i)] < pivot) i++;
        while (pivot < arr[uint256(j)]) j--;
        if (i <= j) {
            (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
            i++;
            j--;
        }
    }
    if (left < j)
        quickSort(arr, left, j);
    if (i < right)
        quickSort(arr, i, right);
}

function sort(uint256[] memory data) public returns (uint256[] memory) {
    quickSort(data, int(0), int(data.length - 1));
    return data;
}















}








