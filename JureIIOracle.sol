// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract JureOracle {

// █▀ ▀█▀ █▀█ █░█ █▄▀ ▀█▀ █░█ █▀█ █▀▀
// ▄█ ░█░ █▀▄ █▄█ █░█ ░█░ █▄█ █▀▄ ██▄

uint256 currentRound = 0; // globalna spremenljivka, ki belezi stevilo trenutnega runde

struct Round {
    uint commitEndDate; // koncni cas za commit
    uint revealEndDate; // koncni cas za reveal

    mapping (address => bytes32) hashes; // shranjuje dodan hash posameznega naslova
    mapping (address => bool) hashCommiters; // shranjuje true za naslov, ki je ze dal hash

    mapping (address => uint256) votes; // shranjuje dodan glas posameznega naslova
    address[] correctVoteCommiters; // tabela tistih, ki so pravilno glasovali
    mapping (address => bool) doesMatch; // shranjuje true za naslov, kateremu se ujemata hash in glas


    mapping(uint256 => address) priceToVoter; // slovar, ki poveze ceno na glasovalca
    uint256[] prices; // tabela cen
    mapping (address => uint256) currentVotePowerOfThisVoter; // trenutna moc glasovalca

    uint256 allWeight; // celotna moc (utez) runde

    uint256 oraclePrice; // izracunana povprecje ustreznih glasov
    uint256 oraclePowerPrice; // izracunano tehtano povprecje ustreznih glasov
} 

struct Voter {
    uint256 weight; // njegova utez
    mapping (uint256 => bytes32) hashes; // njegovi commiti
    mapping (uint256 => uint256) votes; // njegovi reveali
    mapping (address => uint256) delegators; // njegovi delegatorji
}

mapping(uint256 => Round) public rounds; // slovar, ki stevilo runde poveze z rundo
mapping(address => Voter) public voters; // slovar, ki racun glasovalca poveze z glasovalcem
mapping(address => bool) public isVoter; // slovar, ki pove ali je nekdo glasovalec

                                                       
// █▀▀ █▀█ █▀▄▀█ █▀▄▀█ █ ▀█▀ ░░▄▀ █▀█ █▀▀ █░█ █▀▀ ▄▀█ █░░
// █▄▄ █▄█ █░▀░█ █░▀░█ █ ░█░ ▄▀░░ █▀▄ ██▄ ▀▄▀ ██▄ █▀█ █▄▄

function commitVote(bytes32 voteHash) public { // funkcija za commit
    require(isVoter[msg.sender], "Ni voter"); // preveri ali je glasovalec
    require(activeCommit(),"Prepozno"); // preveri, ali je trenutno se odprt cas za glasovanje
    require(voters[msg.sender].hashes[currentRound] == 0, "Ze glasoval"); // preveri ali je ze glasoval
    voters[msg.sender].hashes[currentRound] = voteHash; // glasovalcu doda commit
    rounds[currentRound].hashes[msg.sender] = voteHash; // rundi doda commit
}
    

function revealVote(uint256 vote, uint256 salt) public {
    require(isVoter[msg.sender],"Ni voter");
    require(activeReveal(),"Prepozno");
    require(voters[msg.sender].votes[currentRound] == 0, "Ze glasoval");
    require(keccak256(abi.encodePacked(vote, salt)) == rounds[currentRound].hashes[msg.sender],
    "Se ne ujema"); 
    rounds[currentRound].doesMatch[msg.sender] = true;
    voters[msg.sender].votes[currentRound] = vote;
    rounds[currentRound].votes[msg.sender] = vote;
    rounds[currentRound].correctVoteCommiters.push(msg.sender);
    rounds[currentRound].allWeight += voters[msg.sender].weight;
    rounds[currentRound].priceToVoter[vote] = msg.sender;
    rounds[currentRound].currentVotePowerOfThisVoter[msg.sender] = voters[msg.sender].weight;
    rounds[currentRound].prices.push(vote);
}

function hashh(uint256 ocena, uint256 salt) public pure returns (bytes32 khash) { // pomozna funkcija za testiranje
    return keccak256(abi.encodePacked(ocena, salt));
}


// █▀█ █▀█ █░█ █▄░█ █▀▄ █▀
// █▀▄ █▄█ █▄█ █░▀█ █▄▀ ▄█


function startRound(uint256 commitTime, uint256 revealTime) public {
    currentRound += 1;
    rounds[currentRound].commitEndDate = block.timestamp + commitTime * 1 seconds;
    rounds[currentRound].revealEndDate = rounds[currentRound].commitEndDate + revealTime * 1 seconds;
    rounds[currentRound].allWeight = 0;
}


function activeCommit () public view returns (bool active) {
    require(block.timestamp <= rounds[currentRound].commitEndDate); // Preveri, da je trenutni cas manjsi od casa commitEndDate v tej rundi.
    require (rounds[currentRound-1].commitEndDate <= block.timestamp); // Preveri, da je commitEndDate prejsnje runde manjsi od trenutnega casa.
    return true; 
}


function activeReveal () public view returns (bool active) {
    require (block.timestamp <= rounds[currentRound].revealEndDate);  // Preveri, da je trenutni cas manjsi od casa revealEndDate v tej rundi.
    require (rounds[currentRound-1].revealEndDate <= block.timestamp); // Preveri, da je revealEndDate prejsnje runde manjsi od trenutnega casa.
    return true;
}
                                          
                                                                                             
                                                                                                
// █▀█ █▀█ ▄▀█ █▀▀ █░░ █▀▀ █▀█ █▀█ █ █▀▀ █▀▀  ▄▀ █▀█ █▀█ █░█ █▄░█ █▀▄  █▄░█ █░█ █▀▄▀█ █▄▄ █▀▀ █▀█ ▀▄
// █▄█ █▀▄ █▀█ █▄▄ █▄▄ ██▄ █▀▀ █▀▄ █ █▄▄ ██▄  ▀▄ █▀▄ █▄█ █▄█ █░▀█ █▄▀  █░▀█ █▄█ █░▀░█ █▄█ ██▄ █▀▄ ▄▀


function oraclePriceByRoundNumber (uint roundNumber) public view returns(uint256 price) {
    uint256 n = rounds[roundNumber].correctVoteCommiters.length;
    uint256 computedPrice = 0;
    for (uint i = 0; i < n; i++) {
        address voter = rounds[roundNumber].correctVoteCommiters[i];
        computedPrice += rounds[roundNumber].votes[voter];
    }
    computedPrice = computedPrice/n;
    return computedPrice;

}

function oraclePriceByPowerByRoundNumber (uint roundNumber) public returns(uint256 price) {
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

// █▀█ █▀█ ▄▀█ █▀▀ █░░ █▀▀ █▀█ █▀█ █ █▀▀ █▀▀  ▄▀ █▀▀ █░█ █▀█ █▀█ █▀▀ █▄░█ ▀█▀  █▀█ █▀█ █░█ █▄░█ █▀▄ ▀▄
// █▄█ █▀▄ █▀█ █▄▄ █▄▄ ██▄ █▀▀ █▀▄ █ █▄▄ ██▄  ▀▄ █▄▄ █▄█ █▀▄ █▀▄ ██▄ █░▀█ ░█░  █▀▄ █▄█ █▄█ █░▀█ █▄▀ ▄▀

function oraclePriceByCurrentRound() public view returns(uint256 price) {
    
    uint256 n = rounds[currentRound].correctVoteCommiters.length;
    uint256 computedPrice = 0;
    for (uint i = 0; i < n; i++) {
        address voter = rounds[currentRound].correctVoteCommiters[i];
        computedPrice += rounds[currentRound].votes[voter];
    }
    computedPrice = computedPrice/n;
    return computedPrice;

}

function oraclePriceByPowerByCurrentRound () public returns(uint256 price) {
    uint256 n = rounds[currentRound].correctVoteCommiters.length;
    uint256 quarter = rounds[currentRound].allWeight /4;
    uint256 newWeight = rounds[currentRound].allWeight - 2 * quarter;
    uint256 downBound = quarter;
    uint256 upBound = quarter;
    uint256[] memory sortedPrices = sort(rounds[currentRound].prices);
    uint256 i = 0;
    uint256 j = n-1;
    while (downBound != 0) {
        uint256 candidatePrice = sortedPrices[i];
        address voterOfThisPrice = rounds[currentRound].priceToVoter[candidatePrice];
        uint256 PowerOfThisVoter = rounds[currentRound].currentVotePowerOfThisVoter[voterOfThisPrice];
        if (PowerOfThisVoter >= downBound) {
            rounds[currentRound].currentVotePowerOfThisVoter[voterOfThisPrice] = PowerOfThisVoter - downBound;
            downBound = 0;
        }
        else {
            rounds[currentRound].currentVotePowerOfThisVoter[voterOfThisPrice] = 0;
            downBound -= PowerOfThisVoter;
            i +=1;
        }

    }
    while (upBound != 0) {
        uint256 candidatePrice = sortedPrices[j];
        address voterOfThisPrice = rounds[currentRound].priceToVoter[candidatePrice];
        uint256 PowerOfThisVoter = rounds[currentRound].currentVotePowerOfThisVoter[voterOfThisPrice];
        if (PowerOfThisVoter >= downBound) {
            rounds[currentRound].currentVotePowerOfThisVoter[voterOfThisPrice] = PowerOfThisVoter - upBound;
            upBound = 0;
        }
        else {
            rounds[currentRound].currentVotePowerOfThisVoter[voterOfThisPrice] = 0;
            upBound -= PowerOfThisVoter;
            j -= 1;
        }   

    }
    uint256 computedPowerPrice = 0;
    for (uint k = 0; k < n; k++) {
        address voter = rounds[currentRound].correctVoteCommiters[k];
        computedPowerPrice += rounds[currentRound].votes[voter] * rounds[currentRound].currentVotePowerOfThisVoter[voter];
    }
    computedPowerPrice = computedPowerPrice/newWeight;
    rounds[currentRound].oraclePowerPrice = computedPowerPrice;
    return computedPowerPrice;

}


                                                                   
// █░█ █▀█ ▀█▀ █▀▀ █▀█ █▀ ░░▄▀  █▀▄ █▀▀ █░░ █▀▀ █▀▀ ▄▀█ ▀█▀ █▀█ █▀█ █▀
// ▀▄▀ █▄█ ░█░ ██▄ █▀▄ ▄█ ▄▀░░  █▄▀ ██▄ █▄▄ ██▄ █▄█ █▀█ ░█░ █▄█ █▀▄ ▄█

function becomeVoter () public {
    require(isVoter[msg.sender] == false, "Voter already exists");
    isVoter[msg.sender] = true;
    voters[msg.sender].weight = 0;
}

function delegateVotes (uint256 votePower, address voterAddress) public {
    voters[voterAddress].weight += votePower;
    voters[voterAddress].delegators[msg.sender] = votePower;
}


                                 
// █▀█ █░█ █ █▀▀ █▄▀ █▀ █▀█ █▀█ ▀█▀
// ▀▀█ █▄█ █ █▄▄ █░█ ▄█ █▄█ █▀▄ ░█░
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









                                   
