Summary
 - [weak-prng](#weak-prng) (1 results) (High)
 - [incorrect-equality](#incorrect-equality) (1 results) (Medium)
 - [uninitialized-local](#uninitialized-local) (4 results) (Medium)
 - [timestamp](#timestamp) (6 results) (Low)
 - [assembly](#assembly) (1 results) (Informational)
 - [pragma](#pragma) (1 results) (Informational)
 - [costly-loop](#costly-loop) (1 results) (Informational)
 - [solc-version](#solc-version) (5 results) (Informational)
 - [naming-convention](#naming-convention) (4 results) (Informational)
 - [too-many-digits](#too-many-digits) (1 results) (Informational)
 - [external-function](#external-function) (9 results) (Optimization)
## weak-prng
Impact: High
Confidence: Medium
 - [ ] ID-0
[JureIVOracle.modifiedQuickSelect(uint256,uint256,uint256,uint256,uint256[],uint256[],uint256[])](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L236-L291) uses a weak PRNG: "[(pos.pos,vars.newLeftSum,vars.newRightSum) = partition(pos.left,pos.right,(random % (pos.right - pos.left + 1)) + pos.left,vars.leftSum,vars.rightSum,index,indexedPrices,indexedWeights)](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L261-L270)" 

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L236-L291


## incorrect-equality
Impact: Medium
Confidence: High
 - [ ] ID-1
[JureIVOracle.swap(uint256,uint256,uint256[])](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L328-L331) uses a dangerous strict equality:
	- [i == j](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L329)

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L328-L331


## uninitialized-local
Impact: Medium
Confidence: Medium
 - [ ] ID-2
[JureIVOracle.addOrUpdate(address,uint128).i](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L162) is a local variable never initialized

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L162


 - [ ] ID-3
[JureIVOracle.finalizePrice(uint256,uint256[],uint256[],uint256[]).data](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L213) is a local variable never initialized

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L213


 - [ ] ID-4
[JureIVOracle.modifiedQuickSelect(uint256,uint256,uint256,uint256,uint256[],uint256[],uint256[]).pos](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L252) is a local variable never initialized

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L252


 - [ ] ID-5
[JureIVOracle.modifiedQuickSelect(uint256,uint256,uint256,uint256,uint256[],uint256[],uint256[]).vars](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L251) is a local variable never initialized

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L251


## timestamp
Impact: Low
Confidence: Medium
 - [ ] ID-6
[Lock.withdraw()](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/Lock.sol#L23-L33) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(block.timestamp >= unlockTime,You can't withdraw yet)](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/Lock.sol#L27)

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/Lock.sol#L23-L33


 - [ ] ID-7
[JureIVOracle.activeReveal(uint256)](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L130-L134) uses timestamp for comparisons
	Dangerous comparisons:
	- [rounds[roundNumber].commitEndDate <= block.timestamp](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L131)
	- [block.timestamp <= rounds[roundNumber].revealEndDate](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L132)

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L130-L134


 - [ ] ID-8
[JureIVOracle.startRound(uint256,uint256)](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L115-L121) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(rounds[currentRound].revealEndDate <= block.timestamp,ERR_PREVIOUS_ROUND_STILL_ACTIVE)](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L116)

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L115-L121


 - [ ] ID-9
[JureIVOracle.activeCommit(uint256)](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L124-L127) uses timestamp for comparisons
	Dangerous comparisons:
	- [block.timestamp <= rounds[roundNumber].commitEndDate](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L125)

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L124-L127


 - [ ] ID-10
[JureIVOracle.swap(uint256,uint256,uint256[])](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L328-L331) uses timestamp for comparisons
	Dangerous comparisons:
	- [i == j](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L329)

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L328-L331


 - [ ] ID-11
[Lock.constructor(uint256)](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/Lock.sol#L13-L21) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(block.timestamp < _unlockTime,Unlock time should be in the future)](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/Lock.sol#L14-L17)

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/Lock.sol#L13-L21


## assembly
Impact: Informational
Confidence: High
 - [ ] ID-12
[console._sendLogPayload(bytes)](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/node_modules/hardhat/console.sol#L7-L14) uses assembly
	- [INLINE ASM](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/node_modules/hardhat/console.sol#L10-L13)

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/node_modules/hardhat/console.sol#L7-L14


## pragma
Impact: Informational
Confidence: High
 - [ ] ID-13
Different versions of Solidity are used:
	- Version used: ['>=0.4.22<0.9.0', '^0.8.0', '^0.8.9']
	- [^0.8.0](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L3)
	- [^0.8.0](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracleMock.sol#L2)
	- [^0.8.9](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/Lock.sol#L2)
	- [>=0.4.22<0.9.0](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/node_modules/hardhat/console.sol#L2)

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L3


## costly-loop
Impact: Informational
Confidence: Medium
 - [ ] ID-14
[JureIVOracle.addOrUpdate(address,uint128)](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L159-L178) has costly operations inside a loop:
	- [voters.pop()](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L165)

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L159-L178


## solc-version
Impact: Informational
Confidence: High
 - [ ] ID-15
Pragma version[^0.8.0](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracleMock.sol#L2) allows old versions

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracleMock.sol#L2


 - [ ] ID-16
Pragma version[^0.8.0](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L3) allows old versions

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L3


 - [ ] ID-17
Pragma version[^0.8.9](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/Lock.sol#L2) necessitates a version too recent to be trusted. Consider deploying with 0.6.12/0.7.6/0.8.7

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/Lock.sol#L2


 - [ ] ID-18
Pragma version[>=0.4.22<0.9.0](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/node_modules/hardhat/console.sol#L2) is too complex

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/node_modules/hardhat/console.sol#L2


 - [ ] ID-19
solc-0.8.9 is not recommended for deployment

## naming-convention
Impact: Informational
Confidence: High
 - [ ] ID-20
Contract [console](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/node_modules/hardhat/console.sol#L4-L1532) is not in CapWords

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/node_modules/hardhat/console.sol#L4-L1532


 - [ ] ID-21
Parameter [JureIVOracle.revealVote(uint256,uint256,uint256)._vote](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L82) is not in mixedCase

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L82


 - [ ] ID-22
Parameter [JureIVOracle.revealVote(uint256,uint256,uint256)._salt](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L82) is not in mixedCase

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L82


 - [ ] ID-23
Parameter [JureIVOracle.commitVote(bytes32,uint256)._voteHash](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L74) is not in mixedCase

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L74


## too-many-digits
Impact: Informational
Confidence: Medium
 - [ ] ID-24
[console.slitherConstructorConstantVariables()](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/node_modules/hardhat/console.sol#L4-L1532) uses literals with too many digits:
	- [CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67)](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/node_modules/hardhat/console.sol#L5)

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/node_modules/hardhat/console.sol#L4-L1532


## external-function
Impact: Optimization
Confidence: High
 - [ ] ID-25
revealVote(uint256,uint256,uint256) should be declared external:
	- [JureIVOracle.revealVote(uint256,uint256,uint256)](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L82-L101)

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L82-L101


 - [ ] ID-26
commitVote(bytes32,uint256) should be declared external:
	- [JureIVOracle.commitVote(bytes32,uint256)](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L74-L79)

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L74-L79


 - [ ] ID-27
forceRevealPhase(uint256) should be declared external:
	- [JureIVOracleMock.forceRevealPhase(uint256)](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracleMock.sol#L14-L16)

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracleMock.sol#L14-L16


 - [ ] ID-28
getVoteHash(uint256,address) should be declared external:
	- [JureIVOracleMock.getVoteHash(uint256,address)](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracleMock.sol#L9-L12)

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracleMock.sol#L9-L12


 - [ ] ID-29
addOrUpdate(address,uint128) should be declared external:
	- [JureIVOracle.addOrUpdate(address,uint128)](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L159-L178)

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L159-L178


 - [ ] ID-30
withdraw() should be declared external:
	- [Lock.withdraw()](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/Lock.sol#L23-L33)

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/Lock.sol#L23-L33


 - [ ] ID-31
hashh(uint256,uint256) should be declared external:
	- [JureIVOracle.hashh(uint256,uint256)](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L105-L107)

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L105-L107


 - [ ] ID-32
startRound(uint256,uint256) should be declared external:
	- [JureIVOracle.startRound(uint256,uint256)](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L115-L121)

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L115-L121


 - [ ] ID-33
getPrice(uint256) should be declared external:
	- [JureIVOracle.getPrice(uint256)](https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L136-L153)

https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol/orac_dipl/contracts/JureIVOracle.sol#L136-L153


orac_dipl analyzed (4 contracts with 78 detectors), 34 result(s) found
juresternad@jures-MBP Desktop % slither  --checklist orac_dipl --markdown-root https://github.com/juresternad/orac_dipl/blob/master/contracts/JureIVOracle.sol
