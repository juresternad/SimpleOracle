// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./JureIVOracle.sol";

contract JureIVOracleMock is JureIVOracle {
    function getVoteHash(uint256 roundNumber, address voter) external view returns (bytes32 voteHash) {
        return rounds[roundNumber].votes[voter].voteHash;
    }

}
