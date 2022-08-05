// SPDX-License-Identifier: MIT

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
    // Data Structures
    //====================================================================

    // Current round number
    uint256 public currentRound = 0;

    // Array of eligible voters
    address[] public voters;

    // Mapping that associates voter to his weight
    mapping(address => uint128) public weights;

    struct Vote { // Struct for vote in specific round
        // Hash of the vote (+ salt and msg.sender)
        bytes32 voteHash;
        // Successfully revealed vote
        uint256 vote;
        // Weight of vote's voter
        uint128 weight;
    }

    struct Round { // Struct for the specific round
        // End date of the round's commit phase
        uint256 commitEndDate;
        // End date of the round's reveal phase
        uint256 revealEndDate;
        // Mapping that associates voter to his vote
        mapping(address => Vote) votes;
        // Array of voters who successfully revealed their vote
        address[] revealedVoters;
        // weighted median price
        uint256 weightedMedianPrice;
    }

    // Mapping that associates round number to its round
    mapping(uint256 => Round) public rounds;

    // owner's address
    address public owner;

    //====================================================================
    // Constructor
    //====================================================================

    constructor() {
        owner = msg.sender; // sets the owner of the contract
    }

    //====================================================================
    // Modifier
    //====================================================================

    modifier onlyOwner() {
        require(msg.sender == owner, NOT_OWNER); // checks ownership
        _;
    }

    //====================================================================
    // Voters
    //====================================================================

    /**
     * @notice Adds, updates voter's weights or deletes the voter
     * @param voter                 Voter's address
     * @param weight                New weight
     */
    function addOrUpdate(address voter, uint128 weight) public onlyOwner {
        if (weight == 0) {
            // case of deleting the voter
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
            // case of updating the existing voter's weight
            weights[voter] = weight;
        } else {
            // case of adding a new voter
            voters.push(voter);
            weights[voter] = weight;
        }
    }

    //====================================================================
    // Rounds
    //====================================================================

    /**
     * @notice Starts a new round
     * @param commitTime              Duration of the commit phase
     * @param revealTime              Duration of the reveal phase (starts "immediately" after the commit phase)
     */
    function startRound(
        uint256 commitTime,
        uint256 revealTime
    )
        public
        onlyOwner
    {
        // Previous round's reveal phase must have ended
        require(rounds[currentRound].revealEndDate <= block.timestamp, ERR_PREVIOUS_ROUND_STILL_ACTIVE);
        currentRound += 1;
        // Sets the end dates
        rounds[currentRound].commitEndDate = block.timestamp + commitTime * 1 seconds;
        rounds[currentRound].revealEndDate = rounds[currentRound].commitEndDate + revealTime * 1 seconds;
    }

    /**
     * @notice Checks whether the round's commit phase is active
     * @param roundNumber              Number of the round
     * @return active                  Boolean indicating whether the round's commit phase is active
     */
    function activeCommit(uint256 roundNumber) public view returns (bool active) {
        if (block.timestamp <= rounds[roundNumber].commitEndDate) return true;
    }

    /**
     * @notice Checks whether the round's reveal phase is active
     * @param roundNumber              Number of the round
     * @return active                  Boolean indicating whether the round's reveal phase is active
     */
    function activeReveal(uint256 roundNumber) public view returns (bool active) {
        if (rounds[roundNumber].commitEndDate <= block.timestamp)
        if (block.timestamp <= rounds[roundNumber].revealEndDate)
        return true;
    }

    /**
     * @notice Returns the weightedMedianPrice of the round
     * @param roundNumber              Number of the round
     * @return price                   Weighted median price of the round
     */
    function getPrice(uint256 roundNumber) public returns (uint256 price) {
        if (rounds[roundNumber].revealedVoters.length == 0) {
            // case of 0 successfully revealed votes
            return 0;
        }
        if (rounds[roundNumber].weightedMedianPrice == 0) {
            // case of weightedMedianPrice of the round not yet been computed
            uint256 count = rounds[roundNumber].revealedVoters.length;
            // sets the memory arrays
            uint256[] memory index = new uint256[](count);
            uint256[] memory indexedPrices = new uint256[](count);
            uint256[] memory indexedWeights = new uint256[](count);
            for (uint256 i = 0; i < count; i++) {
                index[i] = i;
                address revealedVoter = rounds[roundNumber].revealedVoters[i];
                indexedPrices[i] = rounds[roundNumber] .votes[revealedVoter] .vote;
                indexedWeights[i] = rounds[roundNumber] .votes[revealedVoter] .weight;
            }
            // uses finalizePrice and updates the round's weightedMedianPrice
            price = finalizePrice(count, index, indexedPrices, indexedWeights);
            rounds[roundNumber].weightedMedianPrice = price;
        }
        return rounds[roundNumber].weightedMedianPrice;
    }

    //====================================================================
    // Commit/ Reveal
    //====================================================================

    /**
     * @notice Commits voter's hash
     * @param _voteHash                Voter's hash of the vote
     * @param roundNumber              Number of the round
     */
    function commitVote(bytes32 _voteHash, uint256 roundNumber) public {
        // Checks round's commit-phase activity
        require(activeCommit(roundNumber), ERR_COMMIT_NOT_ACTIVE);
        // Prevents non-voters from commiting the hash
        require(weights[msg.sender] != 0, ERR_COMMIT_NO_WEIGHT);
        // Prevents double-commit
        require(rounds[roundNumber].votes[msg.sender].voteHash == 0, ERR_ALREADY_VOTED);
        // Sets voter's hash in the round
        rounds[currentRound].votes[msg.sender].voteHash = _voteHash;
    }

    /**
     * @notice Reveals voter's hash
     * @param _vote                    Voter's vote
     * @param _salt                    Salt he used of the hash
     * @param roundNumber              Number of the round
     */
    function revealVote(
        uint256 _vote,
        uint256 _salt,
        uint256 roundNumber
    ) public {
        // Checks round's reveal-phase activity
        require(activeReveal(roundNumber), ERR_REVEAL_NOT_ACTIVE);
        // Finds the voter's hash
        bytes32 voteHash = rounds[roundNumber].votes[msg.sender].voteHash;
        // Checks matching of the vote's hash, vote, salt and msg.sender
        require(keccak256(abi.encodePacked(_vote, _salt, msg.sender)) == voteHash, ERR_HASH_DOES_NOT_MATCH);
        // Updates voter's vote, weight and hash in the round
        rounds[roundNumber].votes[msg.sender].vote = _vote;
        rounds[roundNumber].votes[msg.sender].weight = weights[msg.sender];
        rounds[roundNumber].votes[msg.sender].voteHash = 0;
        // Adds voter to the revealedVoters array of the round
        rounds[roundNumber].revealedVoters.push(msg.sender);
    }

    // ====================================================================
    // Weighted Median
    // ====================================================================

    struct Data {                   // Used for storing the results of weighted median calculation
        uint256 medianIndex;        // Index of the median price (in array index)
        uint256 leftSum;            // Auxiliary sum of weights left from the median price
        uint256 rightSum;           // Auxiliary sum of weights right from the median price
        uint256 medianWeight;       // Weight of the voter's whose vote is the median price
        uint256 finalMedianPrice;   // Final median price
    }

    struct Variables {              // Used for storing variables in modified quick select algorithm
        uint256 leftSum;            // Sum of values left to the current position
        uint256 rightSum;           // Sum of values right to the current position
        uint256 newLeftSum;         // Updated sum of values left to the current position
        uint256 newRightSum;        // Updated sum of values right to the current position
        uint256 pivotWeight;        // Weight associated with the pivot index
        uint256 leftMedianWeight;   // Sum of weights left to the median
        uint256 rightMedianWeight;  // Sum of weights right to the median
    }

    struct Positions {              // Used for storing positions in modified quick select algorithm
        uint256 pos;                // Position index (in array index)
        uint256 left;               // Index left to the position index (in array index)
        uint256 right;              // Index right to the position index (in array index)
        uint256 pivotId;            // Pivot index (in array index)
    }
    
    /**
     * @notice Reveals voter's hash
     * @param index                    Permutation of indices of the input arrays that determines the sorting of indexed prices
     * @param indexedPrices            Positional array of indexed prices
     * @param indexedWeights           Positional array of indexed weights
     * @return price                   Weighted median price of the round
     */
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
        if (data.leftSum + data.medianWeight == totalSum / 2 && totalSum % 2 == 0) {
            data.finalMedianPrice = (data.finalMedianPrice + indexedPrices[index[data.medianIndex + 1]]) / 2;
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
