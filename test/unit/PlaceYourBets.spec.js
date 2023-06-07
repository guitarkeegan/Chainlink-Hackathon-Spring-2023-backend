const { assert, expect } = require("chai")
const { network, deployments, ethers } = require("hardhat")
const { developmentChains, networkConfig } = require("../../helper-hardhat-config")

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("unit tests for PlaceYourBets", async function () {
          let accounts, streamer, placeYourBetsContract, poolCreator, randoUser
          beforeEach(async () => {
              accounts = await ethers.getSigners() // could also do with getNamedAccounts
              //   deployer = accounts[0]
              streamer = accounts[1]
              randoUser = accounts[2]
              placeYourBetsContract = await ethers.getContractFactory("PlaceYourBets")
              poolCreator = await placeYourBetsContract.connect(accounts[0]).deploy()
          })

          describe("createBetPool", function () {
              it("emits an event after successfully creating a new betting pool", async () => {
                  await expect(
                      poolCreator.createBetPool(
                          "Ultimate Battle",
                          "My team is going to destroy the other team!!",
                          "K's team",
                          "O's team",
                          ethers.utils.parseEther("0.01") // 0.01 ETH
                      )
                  ).to.emit(poolCreator, "PoolCreated")
              })
          })

          describe("poolExists", function () {
              it("should return true of pool exists, and revert if it does not exist", async () => {
                  await poolCreator.createBetPool(
                      "Ultimate Battle",
                      "My team is going to destroy the other team!!",
                      "K's team",
                      "O's team",
                      ethers.utils.parseEther("0.01") // 0.01 ETH
                  )
                  expect(await poolCreator.poolExists(0)).to.be.true
              })

              it("should return false if the betpool does not exist", async () => {
                  await poolCreator.createBetPool(
                      "Ultimate Battle",
                      "My team is going to destroy the other team!!",
                      "K's team",
                      "O's team",
                      ethers.utils.parseEther("0.01") // 0.01 ETH
                  )
                  expect(await poolCreator.poolExists(4)).to.be.false
              })
          })

          describe("placeBet", function () {
              it("should return the title of the bet pool", async () => {
                  await poolCreator.createBetPool(
                      "Ultimate Battle",
                      "My team is going to destroy the other team!!",
                      "K's team",
                      "O's team",
                      ethers.utils.parseEther("0.01") // 0.01 ETH
                  )
                  // TODO: placeBet with other signer than deployer
                  expect(
                      await poolCreator.placeBet(
                          0,
                          1,
                          {
                              value: ethers.utils.parseEther("0.01"),
                          } /**index , choice .. include value of bet */
                      )
                  ).to.emit(poolCreator, "BetCreated")
              })
          })
          describe("getBetAmount", function () {
              it("should get the bet amount for the given pool", async () => { await poolCreator.createBetPool(
                      "Ultimate Battle",
                      "My team is going to destroy the other team!!",
                      "K's team",
                      "O's team",
                      ethers.utils.parseEther("0.01") // 0.01 ETH
                  )
                  await poolCreator.placeBet(
                      0,
                      1,
                      {
                          value: ethers.utils.parseEther("0.01"),
                      } /**index , choice .. include value of bet */
                  )
                  expect(await poolCreator.getBetAmount(0)).to.equal(ethers.utils.parseEther("0.01"));
              })
              
              it("should not match the test amount for the given pool", async () => { await poolCreator.createBetPool(
                      "Ultimate Battle",
                      "My team is going to destroy the other team!!",
                      "K's team",
                      "O's team",
                      ethers.utils.parseEther("0.01") // 0.01 ETH
                  )
                  await poolCreator.placeBet(
                      0,
                      1,
                      {
                          value: ethers.utils.parseEther("0.01"),
                      } /**index , choice .. include value of bet */
                  )
                  expect(await poolCreator.getBetAmount(0)).to.not.equal(ethers.utils.parseEther("12"));
              })
          })
          describe("getOpenBets", function(){
            it("should return an array of indecies for all open bets", async () => {
                await poolCreator.createBetPool(
                    "Ultimate Battle",
                    "My team is going to destroy the other team!!",
                    "K's team",
                    "O's team",
                    ethers.utils.parseEther("0.01") // 0.01 ETH
                );
                const indexArr = await poolCreator.getOpenBets(1);
                assert(indexArr.length === 1);
                expect(await poolCreator.poolExists(0)).to.be.true;
            });
          })
          describe("getBetPoolData", function(){
            it("should return the pool data from the given betPool", async ()=>{
                await poolCreator.createBetPool(
                    "Ultimate Battle",
                    "My team is going to destroy the other team!!",
                    "K's team",
                    "O's team",
                    ethers.utils.parseEther("0.01") // 0.01 ETH
                );
                const betData = await poolCreator.getBetPoolData(0);
                expect(betData.title).to.equal("Ultimate Battle");
                expect(betData.description).to.equal("My team is going to destroy the other team!!");
                expect(betData.choice1).to.equal("K's team");
                expect(betData.choice2).to.equal("O's team");
                expect(betData.betAmount).to.equal(ethers.utils.parseEther("0.01"));
                console.log(betData);
            })
          })
          describe("checkUpkeep", function(){
            it("should return false if there are no in-progress events", () =>{
                // stuff
            })
          })
      })
