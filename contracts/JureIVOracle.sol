// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract JureIVOracle {
    
    //====================================================================
    // Errors
    //====================================================================
    string internal constant NOT_OWNER = "You are not the owner";
    string internal constant ERR_TOO_MANY_VOTERS = "There are already 100 voters";
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
        uint128 vote;
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
     * @param _voter                 Voter's address
     * @param _weight                New weight
     */
    function addOrUpdate(address _voter, uint128 _weight) external onlyOwner {
        if (_weight == 0) {
            // case of deleting the voter
            weights[_voter] = 0;
            for (uint256 i; i < voters.length; i++) {
                if (voters[i] == _voter) {
                    voters[i] = voters[voters.length - 1];
                    voters.pop();
                    return;
                }
            }
        }
        require(voters.length <= 100, ERR_TOO_MANY_VOTERS);
        if (weights[_voter] != 0) {
            // case of updating the existing voter's weight
            weights[_voter] = _weight;
        } else {
            // case of adding a new voter
            voters.push(_voter);
            weights[_voter] = _weight;
        }
    }

    //====================================================================
    // Rounds
    //====================================================================

    /**
     * @notice Starts a new round
     * @param _commitTime              Duration of the commit phase
     * @param _revealTime              Duration of the reveal phase (starts "immediately" after the commit phase)
     */
    function startRound(uint256 _commitTime, uint256 _revealTime) external onlyOwner {
        // Previous round's reveal phase must have ended
        require(rounds[currentRound].revealEndDate <= block.timestamp, ERR_PREVIOUS_ROUND_STILL_ACTIVE);
        currentRound += 1;
        // Sets the end dates
        rounds[currentRound].commitEndDate = block.timestamp + _commitTime * 1 seconds;
        rounds[currentRound].revealEndDate = rounds[currentRound].commitEndDate + _revealTime * 1 seconds;
    }

    /**
     * @notice Checks whether the round's commit phase is active
     * @param _roundNumber              Number of the round
     * @return _active                  Boolean indicating whether the round's commit phase is active
     */
    function activeCommit(uint256 _roundNumber) public view returns (bool _active) {
        if (block.timestamp <= rounds[_roundNumber].commitEndDate) return true;
    }

    /**
     * @notice Checks whether the round's reveal phase is active
     * @param _roundNumber              Number of the round
     * @return _active                  Boolean indicating whether the round's reveal phase is active
     */
    function activeReveal(uint256 _roundNumber) public view returns (bool _active) {
        if (rounds[_roundNumber].commitEndDate <= block.timestamp)
        if (block.timestamp <= rounds[_roundNumber].revealEndDate)
        return true;
    }

    /**
     * @notice Returns the weightedMedianPrice of the round
     * @param _roundNumber              Number of the round
     * @return _price                   Weighted median price of the round
     */
    function getPrice(uint256 _roundNumber) external returns (uint256 _price) {
        if (rounds[_roundNumber].revealedVoters.length == 0) {
            // case of 0 successfully revealed votes
            return 0;
        }
        if (rounds[_roundNumber].weightedMedianPrice == 0) {
            // case of weightedMedianPrice of the round not yet been computed
            uint256 count = rounds[_roundNumber].revealedVoters.length;
            // prepares the memory arrays
            uint256[] memory index = new uint256[](count);
            uint256[] memory indexedPrices = new uint256[](count);
            uint256[] memory indexedWeights = new uint256[](count);
            for (uint256 i = 0; i < count; i++) {
                index[i] = i;
                address revealedVoter = rounds[_roundNumber].revealedVoters[i];
                indexedPrices[i] = uint256(rounds[_roundNumber].votes[revealedVoter].vote);
                indexedWeights[i] = rounds[_roundNumber].votes[revealedVoter].weight;
            }
            // uses finalizePrice and updates the round's weightedMedianPrice
            _price = _finalizePrice(count, index, indexedPrices, indexedWeights);
            rounds[_roundNumber].weightedMedianPrice = _price;
        }
        return rounds[_roundNumber].weightedMedianPrice;
    }

    //====================================================================
    // Commit/ Reveal
    //====================================================================

    /**
     * @notice Commits voter's hash
     * @param _voteHash                Voter's hash of the vote
     * @param _roundNumber              Number of the round
     */
    function commitVote(bytes32 _voteHash, uint256 _roundNumber) external {
        // Checks round's commit-phase activity
        require(activeCommit(_roundNumber), ERR_COMMIT_NOT_ACTIVE);
        // Prevents non-voters from commiting the hash
        require(weights[msg.sender] != 0, ERR_COMMIT_NO_WEIGHT);
        // Prevents double-commit
        require(rounds[_roundNumber].votes[msg.sender].voteHash == 0, ERR_ALREADY_VOTED);
        // Sets voter's hash in the round
        rounds[currentRound].votes[msg.sender].voteHash = _voteHash;
    }

    /**
     * @notice Reveals voter's hash
     * @param _vote                     Voter's vote
     * @param _salt                     Salt he used of the hash
     * @param _roundNumber              Number of the round
     */
    function revealVote(uint128 _vote, uint256 _salt, uint256 _roundNumber) external {
        // Checks round's reveal-phase activity
        require(activeReveal(_roundNumber), ERR_REVEAL_NOT_ACTIVE);
        // Finds the voter's hash
        bytes32 voteHash = rounds[_roundNumber].votes[msg.sender].voteHash;
        // Checks matching of the vote's hash, vote, salt and msg.sender
        require(keccak256(abi.encodePacked(uint256(_vote), _salt, msg.sender)) == voteHash, ERR_HASH_DOES_NOT_MATCH);
        // Updates voter's vote, weight and hash in the round
        rounds[_roundNumber].votes[msg.sender].vote = _vote;
        rounds[_roundNumber].votes[msg.sender].weight = weights[msg.sender];
        rounds[_roundNumber].votes[msg.sender].voteHash = 0;
        // Adds voter to the revealedVoters array of the round
        rounds[_roundNumber].revealedVoters.push(msg.sender);
    }

    // ====================================================================
    // Weighted Median
    // ====================================================================

    struct Data {                   // Used for storing the results of weighted median calculation
        uint256 medianIndex;        // Index of the median price (in memory array index)
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
        uint256 pos;                // Position index (in memory array index)
        uint256 left;               // Index left to the position index (in memory array index)
        uint256 right;              // Index right to the position index (in memory array index)
        uint256 pivotId;            // Pivot index (in memory array index)
    }
    
    /**
     * @notice Reveals voter's hash
     * @param _index                    Permutation of indices of the input arrays that determines the sorting of indexed prices
     * @param _indexedPrices            Positional memory array of indexed prices
     * @param _indexedWeights           Positional memory array of indexed weights
     * @return price                    Weighted median price of the round
     */
    function _finalizePrice(
        uint256 count,
        uint256[] memory _index,
        uint256[] memory _indexedPrices,
        uint256[] memory _indexedWeights
    ) internal view returns (uint256 price) {
        Data memory _data;
        // Performs modified quick select algorithm
        (_data.medianIndex, _data.leftSum, _data.rightSum) = _modifiedQuickSelect(
            0,
            count - 1,
            0,
            0,
            _index,
            _indexedPrices,
            _indexedWeights
        );
        _data.medianWeight = _indexedWeights[_index[_data.medianIndex]];
        uint256 totalSum = _data.medianWeight + _data.leftSum + _data.rightSum;
        _data.finalMedianPrice = _indexedPrices[_index[_data.medianIndex]];
        if (_data.leftSum + _data.medianWeight == totalSum / 2 && totalSum % 2 == 0) {
            // Case of the median price being in the middle between two prices
            // Takes their awerage
            _data.finalMedianPrice = (_data.finalMedianPrice + _indexedPrices[_index[_data.medianIndex + 1]]) / 2;
        }
        return _data.finalMedianPrice;
    }
    
    /**
     * @notice Performs modified quick select algorithm
     */
    function _modifiedQuickSelect(
        uint256 _start,
        uint256 _end,
        uint256 _leftSumInit,
        uint256 _rightSumInit,
        uint256[] memory _index,
        uint256[] memory _indexedPrices,
        uint256[] memory _indexedWeights
    )
        internal view returns ( uint256, uint256, uint256 )
    {
        if (_start == _end) {
            return (_start, _leftSumInit, _rightSumInit);
        }
        Variables memory _vars;
        Positions memory _pos;

        _vars.leftSum = _leftSumInit;
        _vars.rightSum = _rightSumInit;
        _pos.left = _start;
        _pos.right = _end;
        uint256 random = uint256(
            keccak256(abi.encode(block.difficulty, block.timestamp))
        );
        uint256 totalSum;
        while (true) {
            (_pos.pos, _vars.newLeftSum, _vars.newRightSum) = _partition(
                _pos.left,
                _pos.right,
                (random % (_pos.right - _pos.left + 1)) + _pos.left,
                _vars.leftSum,
                _vars.rightSum,
                _index,
                _indexedPrices,
                _indexedWeights
            );

            _pos.pivotId = _index[_pos.pos];
            _vars.pivotWeight = _indexedWeights[_pos.pivotId];
            totalSum = _vars.pivotWeight + _vars.newLeftSum + _vars.newRightSum;

            _vars.leftMedianWeight = totalSum / 2 + (totalSum % 2);
            _vars.rightMedianWeight = totalSum - _vars.leftMedianWeight;
            if (
                _vars.newLeftSum >= _vars.leftMedianWeight && _vars.leftMedianWeight > _leftSumInit
            ) {
                _pos.right = _pos.pos - 1;
                _vars.rightSum = _vars.pivotWeight + _vars.newRightSum;
            } else if (
                _vars.newRightSum > _vars.rightMedianWeight && _vars.rightMedianWeight > _rightSumInit
            ) {
                _pos.left = _pos.pos + 1;
                _vars.leftSum = _vars.pivotWeight + _vars.newLeftSum;
            } else {
                return (_pos.pos, _vars.newLeftSum, _vars.newRightSum);
            }
        }

        assert(false);
        return (0, 0, 0);
    }

    /**
     * @notice Partitions the memory array index according to the pivot
     */
    function _partition(
        uint256 _left0,
        uint256 _right0,
        uint256 _pivotId,
        uint256 _leftSum0,
        uint256 _rightSum0,
        uint256[] memory _index,
        uint256[] memory _indexedPrices,
        uint256[] memory _indexedWeights
    )
        internal pure returns ( uint256, uint256, uint256 )
    {
        uint256 pivotValue = _indexedPrices[_index[_pivotId]];
        uint256[] memory sums = new uint256[](2);
        sums[0] = _leftSum0;
        sums[1] = _rightSum0;
        uint256 left = _left0;
        uint256 right = _right0;
        _swap(_pivotId, right, _index);
        uint256 storeIndex = left;
        for (uint256 i = left; i < right; i++) {
            uint256 eltId = _index[i];
            if (_indexedPrices[eltId] < pivotValue) {
                sums[0] += _indexedWeights[eltId];
                _swap(storeIndex, i, _index);
                storeIndex++;
            } else {
                sums[1] += _indexedWeights[eltId];
            }
        }
        _swap(right, storeIndex, _index);
        return (storeIndex, sums[0], sums[1]);
    }
    /**
     * @notice Swaps indices `i` and `j` in the memory array index
     */
    function _swap(uint256 i, uint256 j, uint256[] memory _index) internal pure {
        if (i == j) return;
        (_index[i], _index[j]) = (_index[j], _index[i]);
    }
}


