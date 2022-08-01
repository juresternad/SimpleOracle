// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract JureOracle {


    // unused old storage slots (genesis contract upgrade)
uint256[16] private gap;

// Signalling block.coinbase value
address public constant SIGNAL_COINBASE = address(0x00000000000000000000000000000000000DEaD1);
// November 5th, 2021
uint256 public constant BUFFER_TIMESTAMP_OFFSET = 1636070400 seconds;
// Amount of time a buffer is active before cycling to the next one
uint256 public constant BUFFER_WINDOW = 90 seconds;
// {Requests, Votes, Reveals}
uint256 public constant TOTAL_STORED_BUFFERS = 3;
// Store a proof for one week
uint256 public constant TOTAL_STORED_PROOFS = (1 weeks) / BUFFER_WINDOW;
// Cold wallet address => Hot wallet address
mapping(address => address) public attestorAddressMapping;



// Voting round consists of 4 sequential buffer windows: collect, commit, reveal, finalize
// Round ID is the buffer number of the window of the collect phase
struct Vote { // Struct for Vote in buffer number 'N'
    // Hash of the Merkle root (+ random number and msg.sender) that contains valid requests from 'Round ID = N-1' 
    bytes32 commitHash;
    // Merkle root for 'Round ID = N-2' used for commitHash in buffer number 'N-1'
    uint256 vote;
    // Random number for 'Round ID = N-2' used for commitHash in buffer number 'N-1'
    uint256 salt;
}
struct Buffers {
    // {Requests, Votes, Reveals}
    Vote[] votes;
    // The latest buffer number that this account has voted on, used for determining relevant votes
    uint256 latestVote;
}
mapping(address => Buffers) public buffers;

uint256 public totalBuffers;


function submitAttestation(
        uint256 _bufferNumber,
        bytes32 _commitHash,
        bytes32 _merkleRoot,
        bytes32 _randomNumber
    ) 
        external returns (
            bool _isInitialBufferSlot
        )
    {
        require(_bufferNumber == (block.timestamp - BUFFER_TIMESTAMP_OFFSET) / BUFFER_WINDOW, "wrong bufferNumber");
        buffers[msg.sender].latestVote = _bufferNumber;
        buffers[msg.sender].votes[_bufferNumber % TOTAL_STORED_BUFFERS] = Vote(
            _commitHash,
            _merkleRoot,
            _randomNumber
        );
        // Determine if this is the first attestation submitted in a new buffer round.
        // If so, the golang code will automatically finalise the previous round using finaliseRound()
        if (_bufferNumber > totalBuffers) {
            return true;
        }
        return false;
    }

function getAttestation(uint256 _bufferNumber) external view returns (bytes32 _merkleRoot) {
    address attestor = attestorAddressMapping[msg.sender];
    if (attestor == address(0)) {
        attestor = msg.sender;
    }
    require(_bufferNumber > 1);
    uint256 prevBufferNumber = _bufferNumber - 1;
    require(buffers[attestor].latestVote >= prevBufferNumber);
    bytes32 commitHash = buffers[attestor].votes[(prevBufferNumber - 1) % TOTAL_STORED_BUFFERS].commitHash;
    _merkleRoot = buffers[attestor].votes[prevBufferNumber % TOTAL_STORED_BUFFERS].merkleRoot;
    bytes32 randomNumber = buffers[attestor].votes[prevBufferNumber % TOTAL_STORED_BUFFERS].randomNumber;
    require(commitHash == keccak256(abi.encode(_merkleRoot, randomNumber, attestor)));
}

function finaliseRound(uint256 _bufferNumber, bytes32 _merkleRoot) external {
    require(_bufferNumber > 3);
    require(_bufferNumber == (block.timestamp - BUFFER_TIMESTAMP_OFFSET) / BUFFER_WINDOW);
    require(_bufferNumber > totalBuffers);
    // The following region can only be called from the golang code
    if (msg.sender == block.coinbase && block.coinbase == SIGNAL_COINBASE) {
        totalBuffers = _bufferNumber;
        merkleRoots[(_bufferNumber - 3) % TOTAL_STORED_PROOFS] = _merkleRoot;
        emit RoundFinalised(_bufferNumber - 3, _merkleRoot);
    }
}

function lastFinalizedRoundId() external view returns (uint256 _roundId) {
    require(totalBuffers >= 3, "totalBuffers < 3");
    return totalBuffers - 3;
}


// █▀ ▀█▀ █▀█ █░█ █▄▀ ▀█▀ █░█ █▀█ █▀▀
// ▄█ ░█░ █▀▄ █▄█ █░█ ░█░ █▄█ █▀▄ ██▄

uint256 currentRound = 0; // globalna spremenljivka, ki belezi stevilo trenutnega runde

struct Round {
    uint commitEndDate; // koncni cas za commit
    uint revealEndDate; // koncni cas za reveal

    mapping (address => bytes32) hashes; // shranjuje dodan hash posameznega naslova
    mapping (uint256 => uint256) votes; // shranjuje dodan glas posameznega naslova

    uint256 allWeight;

    uint256[] prices;

    uint256 oraclePrice; // izracunana povprecje ustreznih glasov
    uint256 oraclePowerPrice; // izracunano tehtano povprecje ustreznih glasov
} 

struct Voter {
    uint256 weight; // njegova utez
}

Voter[] public voters;
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

                                                       
// █▀▀ █▀█ █▀▄▀█ █▀▄▀█ █ ▀█▀ ░░▄▀ █▀█ █▀▀ █░█ █▀▀ ▄▀█ █░░
// █▄▄ █▄█ █░▀░█ █░▀░█ █ ░█░ ▄▀░░ █▀▄ ██▄ ▀▄▀ ██▄ █▀█ █▄▄

function commitVote(bytes32 voteHash) public { // funkcija za commit
    require(activeCommit(),"Prepozno"); // preveri, ali je trenutno se odprt cas za glasovanje
    require(rounds[currentRound].hashes[msg.sender] == 0, "Ze glasoval"); // preveri ali je ze glasoval
    rounds[currentRound].hashes[msg.sender] = voteHash; // rundi doda commit
}
    

function revealVote(uint256 vote, uint256 salt) public {
    uint256 sender = mapVoters[msg.sender];
    require(activeReveal(),"Prepozno");
    require(rounds[currentRound].votes[sender] == 0, "Ze glasoval");
    require(keccak256(abi.encodePacked(vote, salt, msg.sender)) == rounds[currentRound].hashes[msg.sender],
    "Se ne ujema"); 
    rounds[currentRound].votes[sender] = vote;
    rounds[currentRound].allWeight += voters[sender].weight;
}

function hashh(uint256 ocena, uint256 salt) public pure returns (bytes32 khash) { // pomozna funkcija za testiranje
    return keccak256(abi.encodePacked(ocena, salt, msg.sender));
}


// █▀█ █▀█ █░█ █▄░█ █▀▄ █▀
// █▀▄ █▄█ █▄█ █░▀█ █▄▀ ▄█


function startRound(uint256 commitTime, uint256 revealTime) public {
    require (rounds[currentRound].commitEndDate <= block.timestamp); // Preveri, da je commitEndDate prejsnje runde manjsi od trenutnega casa.
    currentRound += 1;
    rounds[currentRound].commitEndDate = block.timestamp + commitTime * 1 seconds;
    rounds[currentRound].revealEndDate = rounds[currentRound].commitEndDate + revealTime * 1 seconds;
    rounds[currentRound].allWeight = 0;
}


function activeCommit () public view returns (bool active) {
    require(block.timestamp <= rounds[currentRound].commitEndDate); // Preveri, da je trenutni cas manjsi od casa commitEndDate v tej rundi.
    return true; 
}


function activeReveal () public view returns (bool active) {
    require(rounds[currentRound].commitEndDate <= block.timestamp); //
    require(block.timestamp <= rounds[currentRound].revealEndDate);  // Preveri, da je trenutni cas manjsi od casa revealEndDate v tej rundi.
    return true;
}
                                          
                                                                                             
                                                                                                
// █▀█ █▀█ ▄▀█ █▀▀ █░░ █▀▀ █▀█ █▀█ █ █▀▀ █▀▀  ▄▀ █▀█ █▀█ █░█ █▄░█ █▀▄  █▄░█ █░█ █▀▄▀█ █▄▄ █▀▀ █▀█ ▀▄
// █▄█ █▀▄ █▀█ █▄▄ █▄▄ ██▄ █▀▀ █▀▄ █ █▄▄ ██▄  ▀▄ █▀▄ █▄█ █▄█ █░▀█ █▄▀  █░▀█ █▄█ █░▀░█ █▄█ ██▄ █▀▄ ▄▀


function oraclePriceByRoundNumber (uint roundNumber) public view returns(uint256 price) {
    require(currentRound <= roundNumber);
    require(rounds[currentRound].commitEndDate <= block.timestamp);
    uint256 n = voters.length;
    uint256 computedPrice = 0;
    for (uint i = 0; i < n; i++) {
        computedPrice += rounds[roundNumber].votes[i] * voters[i].weight;
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
    
    uint256 n = voters.length;
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

// █░█ █▀█ ▀█▀ █▀▀ █▀█ █▀ 
// ▀▄▀ █▄█ ░█░ ██▄ █▀▄ ▄█ 

function addVoter (address voter, uint256 weight) public onlyOwner {
    require(mapVoters[voter] == 0, "Voter already exists");
    uint256 i = voters.length;
    voters[i].weight = weight;
    mapVoters[voter] = i;
}

function changeWeight (uint256 voterIndex, uint256 weight) public onlyOwner {
    require(mapVoters[voters[voterIndex]] != 0, "Voter doesn't exist");
    voters[voterIndex].weight = weight;
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









                                   
