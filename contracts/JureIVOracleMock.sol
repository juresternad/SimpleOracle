// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0; 

import "./JureIVOracle.sol";



contract JureIVOracleMock is JureIVOracle {
    function getVoteHash(uint256 roundNumber, address voter) public view returns (bytes32 voteHash){
        return rounds[roundNumber].votes[voter].voteHash;

    }

    // function forceRevealPhase(uint256 roundNumber) public {
    //     rounds[roundNumber].commitEndDate = block.timestamp + 0 * 1 seconds;
    // }
}