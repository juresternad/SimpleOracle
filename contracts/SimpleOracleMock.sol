// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./SimpleOracle.sol";

contract SimpleOracleMock is SimpleOracle {
    function getVoteHash(uint256 roundNumber, address voter) external view returns (bytes32 voteHash) {
        return rounds[roundNumber].votes[voter].voteHash;
    }

}
