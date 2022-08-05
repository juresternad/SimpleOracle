// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract JureIVOracle {
    //====================================================================
    // Errors
    //====================================================================
    string internal constant NOT_OWNER = "You are not the owner";
    string internal constant ERR_COMMIT_NOT_ACTIVE =
        "Commit phase for chosen round not active";
    string internal constant ERR_REVEAL_NOT_ACTIVE =
        "Reveal phase for chosen round not active";
    string internal constant ERR_HASH_DOES_NOT_MATCH =
        "Hash doesn't match with vote and salt";
    string internal constant ERR_PREVIOUS_ROUND_STILL_ACTIVE =
        "Previous round still active";
    string internal constant ERR_ALREADY_VOTED =
        "You have already voted for this round";
    string internal constant ERR_COMMIT_NO_WEIGHT =
        "You are not allowed to vote";

    //====================================================================
    // Structures
    //====================================================================

    uint256 public currentRound = 0; // globalna spremenljivka, ki belezi stevilo trenutnega runde

    struct Round {
        uint256 commitEndDate; // koncni cas za commit
        uint256 revealEndDate; // koncni cas za reveal
        mapping(address => Vote) votes;
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

    function commitVote(bytes32 _voteHash, uint256 roundNumber) public {
        // funkcija za commit
        require(activeCommit(roundNumber), ERR_COMMIT_NOT_ACTIVE); // preveri, ali je trenutno se odprt cas za glasovanje
        require(weights[msg.sender] != 0, ERR_COMMIT_NO_WEIGHT);
        require(
            rounds[roundNumber].votes[msg.sender].voteHash == 0,
            ERR_ALREADY_VOTED
        ); // preveri ali je ze glasoval
        rounds[currentRound].votes[msg.sender].voteHash = _voteHash;
    }

    function revealVote(
        uint256 _vote,
        uint256 _salt,
        uint256 roundNumber
    ) public {
        require(activeReveal(roundNumber), ERR_REVEAL_NOT_ACTIVE);
        bytes32 voteHash = rounds[roundNumber].votes[msg.sender].voteHash;

        require(
            keccak256(abi.encodePacked(_vote, _salt, msg.sender)) == voteHash,
            ERR_HASH_DOES_NOT_MATCH
        );

        rounds[roundNumber].votes[msg.sender].vote = _vote;
        rounds[roundNumber].votes[msg.sender].weight = weights[msg.sender];
        rounds[roundNumber].votes[msg.sender].voteHash = 0;

        rounds[roundNumber].revealedVoters.push(msg.sender);
    }

    //====================================================================
    // Rounds
    //====================================================================

    function startRound(uint256 commitTime, uint256 revealTime)
        public
        onlyOwner
    {
        require(
            rounds[currentRound].revealEndDate <= block.timestamp,
            ERR_PREVIOUS_ROUND_STILL_ACTIVE
        ); // Preveri, da je commitEndDate prejsnje runde manjsi od trenutnega casa.
        currentRound += 1;
        rounds[currentRound].commitEndDate =
            block.timestamp +
            commitTime *
            1 seconds;
        rounds[currentRound].revealEndDate =
            rounds[currentRound].commitEndDate +
            revealTime *
            1 seconds;
    }

    function activeCommit(uint256 roundNumber)
        public
        view
        returns (bool active)
    {
        if (block.timestamp <= rounds[roundNumber].commitEndDate)
            // Preveri, da je trenutni cas manjsi od casa commitEndDate v tej rundi.
            return true;
    }

    function activeReveal(uint256 roundNumber)
        public
        view
        returns (bool active)
    {
        if (rounds[roundNumber].commitEndDate <= block.timestamp)
            if (block.timestamp <= rounds[roundNumber].revealEndDate)
                //
                // Preveri, da je trenutni cas manjsi od casa revealEndDate v tej rundi.
                return true;
    }

    function getPrice(uint256 roundNumber) public returns (uint256 price) {
        if (rounds[roundNumber].revealedVoters.length == 0) {
            return 0;
        }
        if (rounds[roundNumber].weightedMedianPrice == 0) {
            uint256 count = rounds[roundNumber].revealedVoters.length;
            uint256[] memory index = new uint256[](count);
            uint256[] memory indexedPrices = new uint256[](count);
            uint256[] memory indexedWeights = new uint256[](count);

            for (uint256 i = 0; i < count; i++) {
                index[i] = i;
                address revealedVoter = rounds[roundNumber].revealedVoters[i];
                indexedPrices[i] = rounds[roundNumber]
                    .votes[revealedVoter]
                    .vote;
                indexedWeights[i] = rounds[roundNumber]
                    .votes[revealedVoter]
                    .weight;
            }
            price = finalizePrice(count, index, indexedPrices, indexedWeights);
            rounds[roundNumber].weightedMedianPrice = price;
        }
        return rounds[roundNumber].weightedMedianPrice;
    }

    //====================================================================
    // Voters
    //====================================================================

    function addOrUpdate(address voter, uint128 weight) public onlyOwner {
        if (weight == 0) {
            weights[voter] = 0;
            for (uint256 i; i < voters.length; i++) {
                if (voters[i] == voter) {
                    voters[i] = voters[voters.length - 1];
                    voters.pop();
                    return;
                }
            }
        }
        if (weights[voter] != 0) {
            weights[voter] = weight;
        } else {
            voters.push(voter);
            weights[voter] = weight;
        }
    }

    // ====================================================================
    // WeightedMedian
    // ====================================================================

    struct Data {
        uint256 medianIndex;
        uint256 leftSum;
        uint256 rightSum;
        uint256 medianWeight;
        uint256 finalMedianPrice;
    }

    struct Variables {
        uint256 leftSum;
        uint256 rightSum;
        uint256 newLeftSum;
        uint256 newRightSum;
        uint256 pivotWeight;
        uint256 leftMedianWeight;
        uint256 rightMedianWeight;
    }

    struct Positions {
        uint256 pos;
        uint256 left;
        uint256 right;
        uint256 pivotId;
    }

    function finalizePrice(
        uint256 count,
        uint256[] memory index,
        uint256[] memory indexedPrices,
        uint256[] memory indexedWeights
    ) internal view returns (uint256 price) {
        Data memory data;

        (data.medianIndex, data.leftSum, data.rightSum) = modifiedQuickSelect(
            0,
            count - 1,
            0,
            0,
            index,
            indexedPrices,
            indexedWeights
        );

        data.medianWeight = indexedWeights[index[data.medianIndex]];
        uint256 totalSum = data.medianWeight + data.leftSum + data.rightSum;
        data.finalMedianPrice = indexedPrices[index[data.medianIndex]];
        if (
            data.leftSum + data.medianWeight == totalSum / 2 && totalSum % 2 == 0
        ) {
            data.finalMedianPrice = (data.finalMedianPrice +indexedPrices[index[data.medianIndex + 1]])/2;
        }

        return data.finalMedianPrice;
    }

    function modifiedQuickSelect(
        uint256 start,
        uint256 end,
        uint256 leftSumInit,
        uint256 rightSumInit,
        uint256[] memory index,
        uint256[] memory indexedPrices,
        uint256[] memory indexedWeights
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        if (start == end) {
            return (start, leftSumInit, rightSumInit);
        }
        Variables memory vars;
        Positions memory pos;

        vars.leftSum = leftSumInit;
        vars.rightSum = rightSumInit;
        pos.left = start;
        pos.right = end;
        uint256 random = uint256(
            keccak256(abi.encode(block.difficulty, block.timestamp))
        );
        uint256 totalSum;
        while (true) {
            (pos.pos, vars.newLeftSum, vars.newRightSum) = partition(
                pos.left,
                pos.right,
                (random % (pos.right - pos.left + 1)) + pos.left,
                vars.leftSum,
                vars.rightSum,
                index,
                indexedPrices,
                indexedWeights
            );

            pos.pivotId = index[pos.pos];
            vars.pivotWeight = indexedWeights[pos.pivotId];
            totalSum = vars.pivotWeight + vars.newLeftSum + vars.newRightSum;

            vars.leftMedianWeight = totalSum / 2 + (totalSum % 2);
            vars.rightMedianWeight = totalSum - vars.leftMedianWeight;
            if (
                vars.newLeftSum >= vars.leftMedianWeight &&
                vars.leftMedianWeight > leftSumInit
            ) {
                pos.right = pos.pos - 1;
                vars.rightSum = vars.pivotWeight + vars.newRightSum;
            } else if (
                vars.newRightSum > vars.rightMedianWeight &&
                vars.rightMedianWeight > rightSumInit
            ) {
                pos.left = pos.pos + 1;
                vars.leftSum = vars.pivotWeight + vars.newLeftSum;
            } else {
                return (pos.pos, vars.newLeftSum, vars.newRightSum);
            }
        }

        assert(false);
        return (0, 0, 0);
    }

    function partition(
        uint256 left0,
        uint256 right0,
        uint256 pivotId,
        uint256 leftSum0,
        uint256 rightSum0,
        uint256[] memory index,
        uint256[] memory indexedPrices,
        uint256[] memory indexedWeights
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 pivotValue = indexedPrices[index[pivotId]];
        uint256[] memory sums = new uint256[](2);
        sums[0] = leftSum0;
        sums[1] = rightSum0;
        uint256 left = left0;
        uint256 right = right0;
        swap(pivotId, right, index);
        uint256 storeIndex = left;
        for (uint256 i = left; i < right; i++) {
            uint256 eltId = index[i];
            if (indexedPrices[eltId] < pivotValue) {
                sums[0] += indexedWeights[eltId];
                swap(storeIndex, i, index);
                storeIndex++;
            } else {
                sums[1] += indexedWeights[eltId];
            }
        }
        swap(right, storeIndex, index);
        return (storeIndex, sums[0], sums[1]);
    }

    function swap(
        uint256 i,
        uint256 j,
        uint256[] memory index
    ) internal pure {
        if (i == j) return;
        (index[i], index[j]) = (index[j], index[i]);
    }



}
