Summary
 - [weak-prng](#weak-prng) (1 results) (High)
 - [incorrect-equality](#incorrect-equality) (1 results) (Medium)
 - [uninitialized-local](#uninitialized-local) (4 results) (Medium)
 - [timestamp](#timestamp) (4 results) (Low)
 - [costly-loop](#costly-loop) (1 results) (Informational)
 - [naming-convention](#naming-convention) (12 results) (Informational)
## weak-prng
Impact: High
Confidence: Medium
 - [ ] ID-0
[JureIVOracle._modifiedQuickSelect(uint256,uint256,uint256,uint256,uint256[],uint256[],uint256[])](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L285-L345) uses a weak PRNG: "[(_pos.pos,_vars.newLeftSum,_vars.newRightSum) = _partition(_pos.left,_pos.right,(random % (_pos.right - _pos.left + 1)) + _pos.left,_vars.leftSum,_vars.rightSum,_index,_indexedPrices,_indexedWeights)](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L311-L320)" 

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L285-L345


## incorrect-equality
Impact: Medium
Confidence: High
 - [ ] ID-1
[JureIVOracle._swap(uint256,uint256,uint256[])](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L386-L389) uses a dangerous strict equality:
	- [i == j](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L387)

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L386-L389


## uninitialized-local
Impact: Medium
Confidence: Medium
 - [ ] ID-2
[JureIVOracle._finalizePrice(uint256,uint256[],uint256[],uint256[])._data](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L260) is a local variable never initialized

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L260


 - [ ] ID-3
[JureIVOracle.addOrUpdate(address,uint128).i](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L90) is a local variable never initialized

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L90


 - [ ] ID-4
[JureIVOracle._modifiedQuickSelect(uint256,uint256,uint256,uint256,uint256[],uint256[],uint256[])._vars](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L299) is a local variable never initialized

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L299


 - [ ] ID-5
[JureIVOracle._modifiedQuickSelect(uint256,uint256,uint256,uint256,uint256[],uint256[],uint256[])._pos](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L300) is a local variable never initialized

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L300


## timestamp
Impact: Low
Confidence: Medium
 - [ ] ID-6
[JureIVOracle.activeReveal(uint256)](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L141-L145) uses timestamp for comparisons
	Dangerous comparisons:
	- [rounds[_roundNumber].commitEndDate <= block.timestamp](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L142)
	- [block.timestamp <= rounds[_roundNumber].revealEndDate](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L143)

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L141-L145


 - [ ] ID-7
[JureIVOracle.activeCommit(uint256)](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L132-L134) uses timestamp for comparisons
	Dangerous comparisons:
	- [block.timestamp <= rounds[_roundNumber].commitEndDate](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L133)

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L132-L134


 - [ ] ID-8
[JureIVOracle._swap(uint256,uint256,uint256[])](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L386-L389) uses timestamp for comparisons
	Dangerous comparisons:
	- [i == j](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L387)

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L386-L389


 - [ ] ID-9
[JureIVOracle.startRound(uint256,uint256)](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L118-L125) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(rounds[currentRound].revealEndDate <= block.timestamp,ERR_PREVIOUS_ROUND_STILL_ACTIVE)](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L120)

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L118-L125


## costly-loop
Impact: Informational
Confidence: Medium
 - [ ] ID-10
[JureIVOracle.addOrUpdate(address,uint128)](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L86-L107) has costly operations inside a loop:
	- [voters.pop()](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L93)

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L86-L107


## naming-convention
Impact: Informational
Confidence: High
 - [ ] ID-11
Parameter [JureIVOracle.revealVote(uint128,uint256,uint256)._roundNumber](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L203) is not in mixedCase

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L203


 - [ ] ID-12
Parameter [JureIVOracle.activeReveal(uint256)._roundNumber](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L141) is not in mixedCase

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L141


 - [ ] ID-13
Parameter [JureIVOracle.addOrUpdate(address,uint128)._voter](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L86) is not in mixedCase

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L86


 - [ ] ID-14
Parameter [JureIVOracle.startRound(uint256,uint256)._revealTime](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L118) is not in mixedCase

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L118


 - [ ] ID-15
Parameter [JureIVOracle.revealVote(uint128,uint256,uint256)._salt](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L203) is not in mixedCase

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L203


 - [ ] ID-16
Parameter [JureIVOracle.startRound(uint256,uint256)._commitTime](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L118) is not in mixedCase

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L118


 - [ ] ID-17
Parameter [JureIVOracle.revealVote(uint128,uint256,uint256)._vote](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L203) is not in mixedCase

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L203


 - [ ] ID-18
Parameter [JureIVOracle.activeCommit(uint256)._roundNumber](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L132) is not in mixedCase

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L132


 - [ ] ID-19
Parameter [JureIVOracle.commitVote(bytes32,uint256)._roundNumber](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L186) is not in mixedCase

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L186


 - [ ] ID-20
Parameter [JureIVOracle.commitVote(bytes32,uint256)._voteHash](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L186) is not in mixedCase

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L186


 - [ ] ID-21
Parameter [JureIVOracle.getPrice(uint256)._roundNumber](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L152) is not in mixedCase

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L152


 - [ ] ID-22
Parameter [JureIVOracle.addOrUpdate(address,uint128)._weight](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L86) is not in mixedCase

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L86


orac_dipl analyzed (2 contracts with 78 detectors), 23 result(s) found