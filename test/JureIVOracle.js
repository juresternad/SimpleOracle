
const { expect } = require("chai");
const keccak256 = require('keccak256');
const {
  time,BN,submitHash,get
} = require('@openzeppelin/test-helpers');

const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

const JureIVOracleMock = artifacts.require("./JureIVOracleMock.sol")



describe("JureIVOracle.sol", function () {
    
    
    async function deployOracleFixture() {
      const Oracle = await ethers.getContractFactory("JureIVOracle");
      const [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();
      const hardhatOracle= await Oracle.deploy();
      await hardhatOracle.deployed();
      return { Oracle, hardhatOracle, owner, addr1, addr2, addr3, addr4};
    }


    describe("Ownership", function () {
      it("Should check owner", async function () {
        
        const { hardhatOracle, owner } = await loadFixture(deployOracleFixture);
        expect(await hardhatOracle.owner()).to.equal(owner.address);
      });
    });


    describe("Adding updating voter", function () {

      it("Should let the owner to add a new voter and correctly store the given weight", async function () {
      const { hardhatOracle, owner, addr1 } = await loadFixture(deployOracleFixture);
      const weight = 10;
      await hardhatOracle.connect(owner).addOrUpdate(addr1.address,weight);
      const voter = await hardhatOracle.voters(0);
      const voterWeight = await hardhatOracle.weights(voter);
      expect(
          (await voter)).to.equal(addr1.address);
      expect(
        weight).to.equal(voterWeight);
      });

      it("Shouldn't let any non-owner to add or update a new voter", async function () {
        // also covers the case of restricting non-owners to update the voter's weight
        const { hardhatOracle, addr1, addr2 } = await loadFixture(deployOracleFixture);
        const weight = 10;
        await expect(hardhatOracle.connect(addr1).addOrUpdate(addr2.address,weight)).to.be.revertedWith("You are not the owner");
      });

      it("Should let the owner to update voter's weight and correctly store it", async function () {
        // also covers the case of "deleting" the voter (by setting the weight to 0)
        const { hardhatOracle, owner, addr1 } = await loadFixture(deployOracleFixture);
        const weight = 10;
        await hardhatOracle.connect(owner).addOrUpdate(addr1.address,weight);
        const secondWeight = 20;
        await hardhatOracle.connect(owner).addOrUpdate(addr1.address,secondWeight);
        const voter = await hardhatOracle.voters(0);
        const voterWeight = await hardhatOracle.weights(voter);
        expect(
            (await voter)).to.equal(addr1.address);
        expect(
          secondWeight).to.equal(voterWeight);
      });
  });

  



  describe("Starting new round", function () {

    it("Should let the owner to start a new round and correctly set it's commit/reveal ending timings", async function () {
    const { hardhatOracle, owner } = await loadFixture(deployOracleFixture);
    await hardhatOracle.connect(owner).startRound(20,20);
    const currentRound = await hardhatOracle.currentRound();
    const round = await hardhatOracle.rounds(currentRound);
    const now = time.latest();
    expect(
        (await now )).to.equal(BigInt(round.commitEndDate) - BigInt(20));
    expect(
        (await now )).to.equal(BigInt(round.revealEndDate) - BigInt(40));

 });

  it("Shouldn't let any non-owner to start a new round", async function () {
    const { hardhatOracle, addr1 } = await loadFixture(deployOracleFixture);
    await expect(hardhatOracle.connect(addr1).startRound(20,20)).to.be.revertedWith("You are not the owner");


 });

});

  describe("Commiting", function () {

    
    it("Should let voter to commit hash and store it correctly", async function () {
    const { hardhatOracle, owner, addr1 } = await loadFixture(deployOracleFixture);
    const Mock = await ethers.getContractFactory("JureIVOracleMock");
    const hardhatOracleMock= await Mock.deploy();
    const weight = 10;
    await hardhatOracleMock.connect(owner).addOrUpdate(addr1.address,weight);
    await hardhatOracleMock.connect(owner).startRound(20,20);
    const currentRound = await hardhatOracleMock.currentRound();
    const voteHash =  ethers.utils.keccak256(ethers.utils.defaultAbiCoder.encode([ "uint256" ], [10]));
    await hardhatOracleMock.connect(addr1).commitVote(voteHash, currentRound);
    const submitedHash = await hardhatOracleMock.getVoteHash(currentRound, addr1.address);
    expect(submitedHash).to.equal(voteHash);

  });

  it("Shouldn't let non-voter (0 weight) to commit hash", async function () {
    const { hardhatOracle, owner, addr1 } = await loadFixture(deployOracleFixture);
    await hardhatOracle.connect(owner).startRound(20,20);
    const currentRound = await hardhatOracle.currentRound();
    const voteHash =  ethers.utils.keccak256(ethers.utils.defaultAbiCoder.encode([ "uint256" ], [10]));
    await expect(hardhatOracle.connect(addr1).commitVote(voteHash, currentRound)).to.be.revertedWith("You are not allowed to vote");;


  });

  it("Shouldn't let voter to commit hash for the same round twice", async function () {
    const { hardhatOracle, owner, addr1 } = await loadFixture(deployOracleFixture);
    const weight = 10;
    await hardhatOracle.connect(owner).addOrUpdate(addr1.address,weight);
    await hardhatOracle.connect(owner).startRound(20,20);
    const currentRound = await hardhatOracle.currentRound();
    const voteHash =  ethers.utils.keccak256(ethers.utils.defaultAbiCoder.encode([ "uint256" ], [10]));
    await hardhatOracle.connect(addr1).commitVote(voteHash, currentRound);
    await expect(hardhatOracle.connect(addr1).commitVote(voteHash, currentRound)).to.be.revertedWith("You have already voted for this round");;


  });

  it("Shouldn't let voter to commit hash for round that isn't commit-active", async function () {
    const { hardhatOracle, owner, addr1 } = await loadFixture(deployOracleFixture);
    const weight = 10;
    await hardhatOracle.connect(owner).addOrUpdate(addr1.address,weight);
    await hardhatOracle.connect(owner).startRound(20,20);
    const currentRound = await hardhatOracle.currentRound();
    const voteHash =  ethers.utils.keccak256(ethers.utils.defaultAbiCoder.encode([ "uint256" ], [10]));
    await expect(hardhatOracle.connect(addr1).commitVote(voteHash, currentRound + 1)).to.be.revertedWith("Commit phase for chosen round not active");
  });

});


describe("Revealing", function () {

  it("Shouldn't let non-voter (0 weight) to reveal vote", async function () {
    const { hardhatOracle, owner, addr1 } = await loadFixture(deployOracleFixture);
    await hardhatOracle.connect(owner).startRound(0,20);
    const currentRound = await hardhatOracle.currentRound();
    const vote =  10;
    const salt = 11;
    await expect(hardhatOracle.connect(addr1).revealVote(vote, salt, currentRound)).to.be.revertedWith("You are not allowed to vote");;
  
  
  });

  it("Shouldn't let voter to reveal vote for round that isn't reveal-active", async function () {
    const { hardhatOracle, owner, addr1 } = await loadFixture(deployOracleFixture);
    const weight = 10;
    await hardhatOracle.connect(owner).addOrUpdate(addr1.address,weight);
    await hardhatOracle.connect(owner).startRound(20,20);
    const currentRound = await hardhatOracle.currentRound();
    const vote =  10;
    const salt = 11;
    await expect(hardhatOracle.connect(addr1).revealVote(vote, salt, currentRound + 1)).to.be.revertedWith("Reveal phase for chosen round not active");
  });

    
  it("Should let voter to reveal vote, store it correctly and remove voteHash (store value as 0)", async function () {
  const { owner, addr1 } = await loadFixture(deployOracleFixture);
  const Mock = await ethers.getContractFactory("JureIVOracleMock");
  const hardhatOracleMock= await Mock.deploy();
  const weight = 10;
  await hardhatOracleMock.connect(owner).addOrUpdate(addr1.address,weight);
  await hardhatOracleMock.connect(owner).startRound(20,20);
  const currentRound = await hardhatOracleMock.currentRound();
  const vote =  10;
  const salt = 11;
  const voteHash = web3.utils.soliditySha3(
    {t: 'uint256', v: vote},
    {t: 'uint256', v: salt},
    {t: 'address', v: addr1.address},
  );
  await hardhatOracleMock.connect(addr1).commitVote(voteHash, currentRound);
  const submitedHash = await hardhatOracleMock.getVoteHash(currentRound, addr1.address);
  expect(submitedHash).to.equal(voteHash);
  await hardhatOracleMock.connect(owner).forceRevealPhase(currentRound);
  await hardhatOracleMock.connect(addr1).revealVote(vote, salt, currentRound);
  // also covers the case of double revealing the vote 
  const submitedHash2 = await hardhatOracleMock.getVoteHash(currentRound, addr1.address);
  expect(submitedHash2).to.equal("0x0000000000000000000000000000000000000000000000000000000000000000");
  
  
  });
  it("Shouldn't let voter to reveal vote that doesn't match with same-round voteHash", async function () {
    const { owner, addr1 } = await loadFixture(deployOracleFixture);
    const Mock = await ethers.getContractFactory("JureIVOracleMock");
    const hardhatOracleMock= await Mock.deploy();
    const weight = 10;
    await hardhatOracleMock.connect(owner).addOrUpdate(addr1.address,weight);
    await hardhatOracleMock.connect(owner).startRound(20,20);
    const currentRound = await hardhatOracleMock.currentRound();
    const vote =  10;
    const salt = 11;
    const voteHash = web3.utils.soliditySha3(
      {t: 'uint256', v: vote},
      {t: 'uint256', v: salt},
      {t: 'address', v: addr1.address},
    );

    const vote2 = 111;
    await hardhatOracleMock.connect(addr1).commitVote(voteHash, currentRound);
    const submitedHash = await hardhatOracleMock.getVoteHash(currentRound, addr1.address);
    expect(submitedHash).to.equal(voteHash);
    await hardhatOracleMock.connect(owner).forceRevealPhase(currentRound);
    await expect(hardhatOracleMock.connect(addr1).revealVote(vote2, salt, currentRound)).to.be.revertedWith("Hash doesn't match with vote and salt");

  
  });
  });











  });