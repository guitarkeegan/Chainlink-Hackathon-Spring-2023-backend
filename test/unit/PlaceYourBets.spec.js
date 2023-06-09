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
                          1,
                          {
                              value: ethers.utils.parseEther("0.01"),
                          } /**index , choice .. include value of bet */
                      )
                  ).to.emit(poolCreator, "PlaceYourBets__BetCreated")
              })
          })
          describe("getBetAmount", function () {
              it("should get the bet amount for the given pool", async () => {
                  await poolCreator.createBetPool(
                      "Ultimate Battle",
                      "My team is going to destroy the other team!!",
                      "K's team",
                      "O's team",
                      ethers.utils.parseEther("0.01") // 0.01 ETH
                  )
                  await poolCreator.placeBet(
                      1,
                      {
                          value: ethers.utils.parseEther("0.01"),
                      } /**index , choice .. include value of bet */
                  )
                  expect(await poolCreator.getBetAmount()).to.equal(ethers.utils.parseEther("0.01"))
              })

              it("should not match the test amount for the given pool", async () => {
                  await poolCreator.createBetPool(
                      "Ultimate Battle",
                      "My team is going to destroy the other team!!",
                      "K's team",
                      "O's team",
                      ethers.utils.parseEther("0.01") // 0.01 ETH
                  )
                  await poolCreator.placeBet(
                      1,
                      {
                          value: ethers.utils.parseEther("0.01"),
                      } /**index , choice .. include value of bet */
                  )
                  expect(await poolCreator.getBetAmount()).to.not.equal(
                      ethers.utils.parseEther("12")
                  )
              })
          })
          describe("resetBetPool", function () {
              // why is this not working???
              it("should fail if the bet status is not completed", async () => {
                  await poolCreator.createBetPool(
                      "Ultimate Battle",
                      "My team is going to destroy the other team!!",
                      "K's team",
                      "O's team",
                      ethers.utils.parseEther("0.01") // 0.01 ETH
                  )
                  await poolCreator.placeBet(
                      1,
                      {
                          value: ethers.utils.parseEther("0.01"),
                      } /**index , choice .. include value of bet */
                  )
                  expect(await poolCreator.resetBetPool()).to.be.revertedWith("PlaceYourBets__PoolNotCompleted")
              })
          })
          describe("checkUpkeep", function () {
              it("should return false if bet pool status not completed", async () => {
                  await poolCreator.createBetPool(
                      "Ultimate Battle",
                      "My team is going to destroy the other team!!",
                      "K's team",
                      "O's team",
                      ethers.utils.parseEther("0.01") // 0.01 ETH
                  )
                  await poolCreator.placeBet(
                      1,
                      {
                          value: ethers.utils.parseEther("0.01"),
                      } /**index , choice .. include value of bet */
                  )
                  const {upkeepNeeded} = await poolCreator.callStatic.checkUpkeep([])
                  assert(!upkeepNeeded)

              })
              it("should return true if bet pool status is completed", async () => {
                  await poolCreator.createBetPool(
                      "Ultimate Battle",
                      "My team is going to destroy the other team!!",
                      "K's team",
                      "O's team",
                      ethers.utils.parseEther("0.01") // 0.01 ETH
                  )
                  await poolCreator.placeBet(
                      1,
                      {
                          value: ethers.utils.parseEther("0.01"),
                      } /**index , choice .. include value of bet */
                  )
                  await poolCreator.selectWinner(1)

                  const {upkeepNeeded} = await poolCreator.callStatic.checkUpkeep([])
                  assert(upkeepNeeded)

              })
          })
          describe("performUpkeep", function(){
            it("will only run if checkUpkeep is true", async () =>{
                  await poolCreator.createBetPool(
                      "Ultimate Battle",
                      "My team is going to destroy the other team!!",
                      "K's team",
                      "O's team",
                      ethers.utils.parseEther("0.01") // 0.01 ETH
                  )
                  await poolCreator.placeBet(
                      1,
                      {
                          value: ethers.utils.parseEther("0.01"),
                      } /**index , choice .. include value of bet */
                  )
                  await poolCreator.startBet();
                  await poolCreator.selectWinner(1)
                  const tx = await poolCreator.performUpkeep([])
                  assert(tx)
            })
          })
          it("reverts when checkUpkeep is false", async function(){
                  await poolCreator.createBetPool(
                      "Ultimate Battle",
                      "My team is going to destroy the other team!!",
                      "K's team",
                      "O's team",
                      ethers.utils.parseEther("0.01") // 0.01 ETH
                  )
                  await poolCreator.placeBet(
                      1,
                      {
                          value: ethers.utils.parseEther("0.01"),
                      } /**index , choice .. include value of bet */
                  )
                  await expect(poolCreator.performUpkeep([])).to.be.revertedWithCustomError(poolCreator, "PlaceYourBets__UpkeepNotNeeded")
        });
        it("emits and event, closes the bet, pays out the bettors and resets the betPool", async () => {
                  await poolCreator.createBetPool(
                      "Ultimate Battle",
                      "My team is going to destroy the other team!!",
                      "K's team",
                      "O's team",
                      ethers.utils.parseEther("0.01") // 0.01 ETH
                  )
                  await poolCreator.placeBet(
                      1,
                      {
                          value: ethers.utils.parseEther("0.01"),
                      } /**index , choice .. include value of bet */
                  )
                  await poolCreator.startBet();
                  await poolCreator.selectWinner(1)
                  const tx = await poolCreator.performUpkeep([])
                  assert(tx)
                  expect(await poolCreator.getBetAmount()).to.equal(0)
                  expect(await poolCreator.getNumberOfPastPools()).to.equal(1)
        })
      })
