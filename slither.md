Summary
 - [weak-prng](#weak-prng) (1 results) (High)
 - [incorrect-equality](#incorrect-equality) (1 results) (Medium)
 - [uninitialized-local](#uninitialized-local) (4 results) (Medium)
 - [timestamp](#timestamp) (4 results) (Low)
 - [costly-loop](#costly-loop) (1 results) (Informational)
 - [solc-version](#solc-version) (3 results) (Informational)
 - [naming-convention](#naming-convention) (12 results) (Informational)
## weak-prng
Impact: High
Confidence: Medium
 - [ ] ID-0
[JureIVOracle._modifiedQuickSelect(uint256,uint256,uint256,uint256,uint256[],uint256[],uint256[])](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L283-L343) uses a weak PRNG: "[(_pos.pos,_vars.newLeftSum,_vars.newRightSum) = _partition(_pos.left,_pos.right,(random % (_pos.right - _pos.left + 1)) + _pos.left,_vars.leftSum,_vars.rightSum,_index,_indexedPrices,_indexedWeights)](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L309-L318)" 

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L283-L343


## incorrect-equality
Impact: Medium
Confidence: High
 - [ ] ID-1
[JureIVOracle._swap(uint256,uint256,uint256[])](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L384-L387) uses a dangerous strict equality:
	- [i == j](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L385)

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L384-L387


## uninitialized-local
Impact: Medium
Confidence: Medium
 - [ ] ID-2
[JureIVOracle._finalizePrice(uint256,uint256[],uint256[],uint256[])._data](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L258) is a local variable never initialized

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L258


 - [ ] ID-3
[JureIVOracle.addOrUpdate(address,uint128).i](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L89) is a local variable never initialized

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L89


 - [ ] ID-4
[JureIVOracle._modifiedQuickSelect(uint256,uint256,uint256,uint256,uint256[],uint256[],uint256[])._vars](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L297) is a local variable never initialized

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L297


 - [ ] ID-5
[JureIVOracle._modifiedQuickSelect(uint256,uint256,uint256,uint256,uint256[],uint256[],uint256[])._pos](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L298) is a local variable never initialized

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L298


## timestamp
Impact: Low
Confidence: Medium
 - [ ] ID-6
[JureIVOracle._swap(uint256,uint256,uint256[])](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L384-L387) uses timestamp for comparisons
	Dangerous comparisons:
	- [i == j](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L385)

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L384-L387


 - [ ] ID-7
[JureIVOracle.activeCommit(uint256)](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L130-L132) uses timestamp for comparisons
	Dangerous comparisons:
	- [block.timestamp <= rounds[_roundNumber].commitEndDate](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L131)

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L130-L132


 - [ ] ID-8
[JureIVOracle.startRound(uint256,uint256)](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L116-L123) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(rounds[currentRound].revealEndDate <= block.timestamp,ERR_PREVIOUS_ROUND_STILL_ACTIVE)](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L118)

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L116-L123


 - [ ] ID-9
[JureIVOracle.activeReveal(uint256)](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L139-L143) uses timestamp for comparisons
	Dangerous comparisons:
	- [rounds[_roundNumber].commitEndDate <= block.timestamp](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L140)
	- [block.timestamp <= rounds[_roundNumber].revealEndDate](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L141)

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L139-L143


## costly-loop
Impact: Informational
Confidence: Medium
 - [ ] ID-10
[JureIVOracle.addOrUpdate(address,uint128)](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L85-L105) has costly operations inside a loop:
	- [voters.pop()](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L92)

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L85-L105


## solc-version
Impact: Informational
Confidence: High
 - [ ] ID-11
Pragma version[^0.8.0](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracleMock.sol#L2) allows old versions

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracleMock.sol#L2


 - [ ] ID-12
Pragma version[^0.8.0](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L3) allows old versions

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L3


 - [ ] ID-13
solc-0.8.9 is not recommended for deployment

## naming-convention
Impact: Informational
Confidence: High
 - [ ] ID-14
Parameter [JureIVOracle.activeReveal(uint256)._roundNumber](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L139) is not in mixedCase

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L139


 - [ ] ID-15
Parameter [JureIVOracle.revealVote(uint256,uint256,uint256)._roundNumber](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L201) is not in mixedCase

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L201


 - [ ] ID-16
Parameter [JureIVOracle.addOrUpdate(address,uint128)._voter](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L85) is not in mixedCase

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L85


 - [ ] ID-17
Parameter [JureIVOracle.startRound(uint256,uint256)._revealTime](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L116) is not in mixedCase

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L116


 - [ ] ID-18
Parameter [JureIVOracle.revealVote(uint256,uint256,uint256)._vote](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L201) is not in mixedCase

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L201


 - [ ] ID-19
Parameter [JureIVOracle.startRound(uint256,uint256)._commitTime](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L116) is not in mixedCase

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L116


 - [ ] ID-20
Parameter [JureIVOracle.revealVote(uint256,uint256,uint256)._salt](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L201) is not in mixedCase

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L201


 - [ ] ID-21
Parameter [JureIVOracle.activeCommit(uint256)._roundNumber](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L130) is not in mixedCase

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L130


 - [ ] ID-22
Parameter [JureIVOracle.commitVote(bytes32,uint256)._roundNumber](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L184) is not in mixedCase

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L184


 - [ ] ID-23
Parameter [JureIVOracle.commitVote(bytes32,uint256)._voteHash](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L184) is not in mixedCase

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L184


 - [ ] ID-24
Parameter [JureIVOracle.getPrice(uint256)._roundNumber](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L150) is not in mixedCase

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L150


 - [ ] ID-25
Parameter [JureIVOracle.addOrUpdate(address,uint128)._weight](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L85) is not in mixedCase

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L85


orac_dipl analyzed (2 contracts with 78 detectors), 26 result(s) found
juresternad@jures-MBP Desktop % 
