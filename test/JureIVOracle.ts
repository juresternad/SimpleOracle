import { artifacts, ethers, web3 } from "hardhat";

const { expect } = require("chai");
const keccak256 = require('keccak256');
const {
  time, BN, submitHash, get
} = require('@openzeppelin/test-helpers');

const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

const JureIVOracleMock = artifacts.require("./JureIVOracleMock.sol")



describe("JureIVOracle.sol", function () {


  async function deployOracleFixture() {
    const Oracle = await ethers.getContractFactory("JureIVOracle");
    const [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();
    const hardhatOracle = await Oracle.deploy();
    await hardhatOracle.deployed();
    return { Oracle, hardhatOracle, owner, addr1, addr2, addr3, addr4 };
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
      await hardhatOracle.connect(owner).addOrUpdate(addr1.address, weight);
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
      await expect(hardhatOracle.connect(addr1).addOrUpdate(addr2.address, weight)).to.be.revertedWith("You are not the owner");
    });

    it("Should let the owner to update voter's weight and correctly store it", async function () {
      const { hardhatOracle, owner, addr1 } = await loadFixture(deployOracleFixture);
      const weight = 10;
      await hardhatOracle.connect(owner).addOrUpdate(addr1.address, weight);
      const secondWeight = 20;
      await hardhatOracle.connect(owner).addOrUpdate(addr1.address, secondWeight);
      const voter = await hardhatOracle.voters(0);
      const voterWeight = await hardhatOracle.weights(voter);
      expect(
        (await voter)).to.equal(addr1.address);
      expect(
        secondWeight).to.equal(voterWeight);
    });

    it("Should let the owner to delet voter (by setting the weight to 0)", async function () {
      const { hardhatOracle, owner, addr1 } = await loadFixture(deployOracleFixture);
      const weight1 = 10;
      await hardhatOracle.connect(owner).addOrUpdate(addr1.address, weight1);
      const weight2 = 0;
      await hardhatOracle.connect(owner).addOrUpdate(addr1.address, weight2);
      const tm1 = 10;
      await time.increase(tm1);
      await expect(hardhatOracle.voters(0)).to.be.reverted;

      
    });


  });





  describe("Starting new round", function () {

    it("Should let the owner to start a new round and correctly set it's commit/reveal ending timings", async function () {
      const { hardhatOracle, owner } = await loadFixture(deployOracleFixture);
      await hardhatOracle.connect(owner).startRound(20, 20);
      const currentRound = await hardhatOracle.currentRound();
      const round = await hardhatOracle.rounds(currentRound);
      const now = time.latest();
      expect(
        (await now)).to.equal(BigInt(round.commitEndDate) - BigInt(20));
      expect(
        (await now)).to.equal(BigInt(round.revealEndDate) - BigInt(40));

    });

    it("Shouldn't let any non-owner to start a new round", async function () {
      const { hardhatOracle, addr1 } = await loadFixture(deployOracleFixture);
      await expect(hardhatOracle.connect(addr1).startRound(20, 20)).to.be.revertedWith("You are not the owner");


    });

    it("Shouldn't let owner to start a new round before previous round has ended", async function () {
      const { hardhatOracle, owner } = await loadFixture(deployOracleFixture);
      await hardhatOracle.connect(owner).startRound(20, 20);
      const currentRound = await hardhatOracle.currentRound();
      const round = await hardhatOracle.rounds(currentRound);
      const now = time.latest();
      const tm1 = 10;
      await time.increase(tm1);
      await expect(hardhatOracle.connect(owner).startRound(20, 20)).to.be.revertedWith("Previous round still active");

    });

  });

  describe("Commiting", function () {


    it("Should let voter to commit hash and store it correctly", async function () {
      const { hardhatOracle, owner, addr1 } = await loadFixture(deployOracleFixture);
      const Mock = await ethers.getContractFactory("JureIVOracleMock");
      const hardhatOracleMock = await Mock.deploy();
      const weight = 10;
      await hardhatOracleMock.connect(owner).addOrUpdate(addr1.address, weight);
      await hardhatOracleMock.connect(owner).startRound(20, 20);
      const currentRound = await hardhatOracleMock.currentRound();
      const voteHash = ethers.utils.keccak256(ethers.utils.defaultAbiCoder.encode(["uint256"], [10]));
      await hardhatOracleMock.connect(addr1).commitVote(voteHash, currentRound);
      const submitedHash = await hardhatOracleMock.getVoteHash(currentRound, addr1.address);
      expect(submitedHash).to.equal(voteHash);

    });

    it("Shouldn't let non-voter (0 weight) to commit hash", async function () {
      const { hardhatOracle, owner, addr1 } = await loadFixture(deployOracleFixture);
      await hardhatOracle.connect(owner).startRound(20, 20);
      const currentRound = await hardhatOracle.currentRound();
      const voteHash = ethers.utils.keccak256(ethers.utils.defaultAbiCoder.encode(["uint256"], [10]));
      await expect(hardhatOracle.connect(addr1).commitVote(voteHash, currentRound)).to.be.revertedWith("You are not allowed to vote");;


    });

    it("Shouldn't let voter to commit hash for the same round twice", async function () {
      const { hardhatOracle, owner, addr1 } = await loadFixture(deployOracleFixture);
      const weight = 10;
      await hardhatOracle.connect(owner).addOrUpdate(addr1.address, weight);
      await hardhatOracle.connect(owner).startRound(20, 20);
      const currentRound = await hardhatOracle.currentRound();
      const voteHash = ethers.utils.keccak256(ethers.utils.defaultAbiCoder.encode(["uint256"], [10]));
      await hardhatOracle.connect(addr1).commitVote(voteHash, currentRound);
      await expect(hardhatOracle.connect(addr1).commitVote(voteHash, currentRound)).to.be.revertedWith("You have already voted for this round");;


    });

    it("Shouldn't let voter to commit hash for round that isn't commit-active", async function () {
      const { hardhatOracle, owner, addr1 } = await loadFixture(deployOracleFixture);
      const weight = 10;
      await hardhatOracle.connect(owner).addOrUpdate(addr1.address, weight);
      await hardhatOracle.connect(owner).startRound(20, 20);
      const currentRound = await hardhatOracle.currentRound();
      const voteHash = ethers.utils.keccak256(ethers.utils.defaultAbiCoder.encode(["uint256"], [10]));
      const tm1 = 30;
      await time.increase(tm1);
      await expect(hardhatOracle.connect(addr1).commitVote(voteHash, currentRound)).to.be.revertedWith("Commit phase for chosen round not active");
    });

  });


  describe("Revealing", function () {

    it("Shouldn't let non-voter (0 weight) to reveal vote", async function () {
      const { hardhatOracle, owner, addr1 } = await loadFixture(deployOracleFixture);
      await hardhatOracle.connect(owner).startRound(0, 20);
      const currentRound = await hardhatOracle.currentRound();
      const vote = 10;
      const salt = 11;
      await expect(hardhatOracle.connect(addr1).revealVote(vote, salt, currentRound)).to.be.revertedWith("Hash doesn't match with vote and salt");


    });

    it("Shouldn't let voter to reveal vote for round that isn't reveal-active", async function () {
      const { hardhatOracle, owner, addr1 } = await loadFixture(deployOracleFixture);
      const weight = 10;
      await hardhatOracle.connect(owner).addOrUpdate(addr1.address, weight);
      await hardhatOracle.connect(owner).startRound(20, 20);
      const currentRound = await hardhatOracle.currentRound();
      const vote = 10;
      const salt = 11;
      await expect(hardhatOracle.connect(addr1).revealVote(vote, salt, currentRound + 1)).to.be.revertedWith("Reveal phase for chosen round not active");
    });


    it("Should let voter to reveal vote, store it correctly and remove voteHash (store value as 0)", async function () {
      const { owner, addr1 } = await loadFixture(deployOracleFixture);
      const Mock = await ethers.getContractFactory("JureIVOracleMock");
      const hardhatOracleMock = await Mock.deploy();
      const weight = 10;
      await hardhatOracleMock.connect(owner).addOrUpdate(addr1.address, weight);
      await hardhatOracleMock.connect(owner).startRound(30, 40);
      const currentRound = await hardhatOracleMock.currentRound();
      const vote = 10;
      const salt = 11;
      const voteHash = ethers.utils.solidityKeccak256(["uint256", "uint256", "address"], [vote, salt, addr1.address]);
      const tm1 = 10;
      await time.increase(tm1);
      await hardhatOracleMock.connect(addr1).commitVote(voteHash, currentRound);
      const submitedHash = await hardhatOracleMock.getVoteHash(currentRound, addr1.address);
      expect(submitedHash).to.equal(voteHash);
      const tm2 = 30;
      await time.increase(tm2);
      await hardhatOracleMock.connect(addr1).revealVote(vote, salt, currentRound);
      // also covers the case of double revealing the vote 
      const submitedHash2 = await hardhatOracleMock.getVoteHash(currentRound, addr1.address);
      expect(submitedHash2).to.equal("0x0000000000000000000000000000000000000000000000000000000000000000");


    });
    it("Shouldn't let voter to reveal vote that doesn't match with same-round voteHash", async function () {
      const { owner, addr1 } = await loadFixture(deployOracleFixture);
      const Mock = await ethers.getContractFactory("JureIVOracleMock");
      const hardhatOracleMock = await Mock.deploy();
      const weight = 10;
      await hardhatOracleMock.connect(owner).addOrUpdate(addr1.address, weight);
      await hardhatOracleMock.connect(owner).startRound(20, 20);
      const currentRound = await hardhatOracleMock.currentRound();
      const vote = 10;
      const salt = 11;
      const voteHash = ethers.utils.keccak256(ethers.utils.defaultAbiCoder.encode(["uint256", "uint256", "address"], [vote, salt, addr1.address]));


      const vote2 = 111;
      await hardhatOracleMock.connect(addr1).commitVote(voteHash, currentRound);
      const submitedHash = await hardhatOracleMock.getVoteHash(currentRound, addr1.address);
      expect(submitedHash).to.equal(voteHash);
      const tm2 = 20;
      await time.increase(tm2);
      await expect(hardhatOracleMock.connect(addr1).revealVote(vote2, salt, currentRound)).to.be.revertedWith("Hash doesn't match with vote and salt");


    });

    describe("Weighted median", function () {


      it("MedianPrice1", async function () {
        const { owner, addr1, addr2, addr3, addr4 } = await loadFixture(deployOracleFixture);
        const Mock = await ethers.getContractFactory("JureIVOracleMock");
        const hardhatOracleMock = await Mock.deploy();
        const weights = [10, 20, 30, 40];
        const signers = [addr1, addr2, addr3, addr4]
        const addresses = [addr1.address, addr2.address, addr3.address, addr4.address]
        const votes = [80, 50, 40, 10];
        const salt = [10, 20, 30, 40];

        await hardhatOracleMock.connect(owner).startRound(20, 20)
        for (var i = 0; i < 4; i++) {
          await hardhatOracleMock.connect(owner).addOrUpdate(addresses[i], weights[i]);
        }
        const currentRound = await hardhatOracleMock.currentRound();

        var voteHash = new Array();
        for (var i = 0; i < 4; i++) {
          voteHash.push(ethers.utils.solidityKeccak256(["uint256", "uint256", "address"], [votes[i], salt[i], addresses[i]]));
        }
        for (var i = 0; i < 4; i++) {
          await hardhatOracleMock.connect(signers[i]).commitVote(voteHash[i], currentRound);
        }
        const tm = 20;
        await time.increase(tm);
        for (var i = 0; i < 4; i++) {
          await hardhatOracleMock.connect(signers[i]).revealVote(votes[i], salt[i], currentRound);
        }
        await hardhatOracleMock.connect(owner).getPrice(currentRound);
        const round = await hardhatOracleMock.rounds(currentRound);
        await expect(round.weightedMedianPrice).to.equal(40);

      });

      it("MedianPrice2", async function () {
        const { owner, addr1, addr2, addr3, addr4 } = await loadFixture(deployOracleFixture);
        const Mock = await ethers.getContractFactory("JureIVOracleMock");
        const hardhatOracleMock = await Mock.deploy();
        const weights = [100, 50, 200, 60];
        const signers = [addr1, addr2, addr3, addr4]
        const addresses = [addr1.address, addr2.address, addr3.address, addr4.address]
        const votes = [45, 42, 100, 10];
        const salt = [10, 20, 30, 40];

        await hardhatOracleMock.connect(owner).startRound(20, 20)
        for (var i = 0; i < 4; i++) {
          await hardhatOracleMock.connect(owner).addOrUpdate(addresses[i], weights[i]);
        }
        const currentRound = await hardhatOracleMock.currentRound();

        var voteHash = new Array();
        for (var i = 0; i < 4; i++) {
          voteHash.push(ethers.utils.solidityKeccak256(["uint256", "uint256", "address"], [votes[i], salt[i], addresses[i]]));
        }
        for (var i = 0; i < 4; i++) {
          await hardhatOracleMock.connect(signers[i]).commitVote(voteHash[i], currentRound);
        }
        const tm = 20;
        await time.increase(tm);
        for (var i = 0; i < 4; i++) {
          await hardhatOracleMock.connect(signers[i]).revealVote(votes[i], salt[i], currentRound);
        }
        await hardhatOracleMock.connect(owner).getPrice(currentRound);
        const round = await hardhatOracleMock.rounds(currentRound);
        await expect(round.weightedMedianPrice).to.equal(45);

      });

      it("MedianPrice in the middle, totalSum % 2 == 0, should return average of middle prices", async function () {
        const { owner, addr1, addr2, addr3, addr4 } = await loadFixture(deployOracleFixture);
        const Mock = await ethers.getContractFactory("JureIVOracleMock");
        const hardhatOracleMock = await Mock.deploy();
        const weights = [10, 10, 10, 10];
        const signers = [addr1, addr2, addr3, addr4]
        const addresses = [addr1.address, addr2.address, addr3.address, addr4.address]
        const votes = [10, 10, 20, 20];
        const salt = [10, 20, 30, 40];

        await hardhatOracleMock.connect(owner).startRound(20, 20)
        for (var i = 0; i < 4; i++) {
          await hardhatOracleMock.connect(owner).addOrUpdate(addresses[i], weights[i]);
        }
        const currentRound = await hardhatOracleMock.currentRound();
        const tm1 = 5;
        await time.increase(tm1);
        var voteHash = new Array();
        for (var i = 0; i < 4; i++) {
          voteHash.push(ethers.utils.solidityKeccak256(["uint256", "uint256", "address"], [votes[i], salt[i], addresses[i]]));
        }
        for (var i = 0; i < 4; i++) {
          await hardhatOracleMock.connect(signers[i]).commitVote(voteHash[i], currentRound);
        }
        const tm2 = 20;
        await time.increase(tm2);
        for (var i = 0; i < 4; i++) {
          await hardhatOracleMock.connect(signers[i]).revealVote(votes[i], salt[i], currentRound);
        }
        await hardhatOracleMock.connect(owner).getPrice(currentRound);
        const round = await hardhatOracleMock.rounds(currentRound);
        await expect(round.weightedMedianPrice).to.equal(15);

      });

      it("MedianPrice 1 vote", async function () {
        const { owner, addr1 } = await loadFixture(deployOracleFixture);
        const Mock = await ethers.getContractFactory("JureIVOracleMock");
        const hardhatOracleMock = await Mock.deploy();
        const weight = 10;
        await hardhatOracleMock.connect(owner).addOrUpdate(addr1.address, weight);
        await hardhatOracleMock.connect(owner).startRound(30, 40);
        const currentRound = await hardhatOracleMock.currentRound();
        const vote = 10;
        const salt = 11;
        const voteHash = ethers.utils.solidityKeccak256(["uint256", "uint256", "address"], [vote, salt, addr1.address]);
        const tm1 = 10;
        await time.increase(tm1);
        await hardhatOracleMock.connect(addr1).commitVote(voteHash, currentRound);
        const tm2 = 30;
        await time.increase(tm2);
        await hardhatOracleMock.connect(addr1).revealVote(vote, salt, currentRound);
        await hardhatOracleMock.connect(owner).getPrice(currentRound);
        const round = await hardhatOracleMock.rounds(currentRound);
        await expect(round.weightedMedianPrice).to.equal(10);

      });

      it("MedianPrice 0 votes", async function () {
        const { owner, addr1 } = await loadFixture(deployOracleFixture);
        const Mock = await ethers.getContractFactory("JureIVOracleMock");
        const hardhatOracleMock = await Mock.deploy();
        const weight = 10;
        await hardhatOracleMock.connect(owner).startRound(30, 40);
        const currentRound = await hardhatOracleMock.currentRound();
        await hardhatOracleMock.connect(owner).getPrice(currentRound);
        const round = await hardhatOracleMock.rounds(currentRound);
        await expect(round.weightedMedianPrice).to.equal(0);

      });

    });


  });











});