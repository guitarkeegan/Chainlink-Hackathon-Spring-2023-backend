const { assert, expect } = require("chai")
const { getNamedAccounts, ethers, network } = require("hardhat")
const { developmentChains } = require("../../helper.hardhat-config")

developmentChains.includes(network.name)
    ? describe.skip
    : describe("PlaceYourBets Staging Test", function () {
          let pyb, deployer

          beforeEach(async function () {
              deployer = (await getNamedAccounts()).deployer
              pyb = await ethers.getContract("PlaceYourBets", deployer)
          })

          describe("Execute Bet Cycle", function () {
              it("deploys the contract, creates a bet pool, places a bet, starts the bet, ends the bet, chainlink automation triggers the payout", async function () {
                  console.log("Setting up test...")
                  const accounts = await ethers.getSigners()

                  console.log("Setting up Listener...")
                  await new Promise(async (resolve, reject) => {
                      pyb.once("WinnerSelected", async () => {
                          console.log("WinnerSelected event fired!")
                          try {
                              // add our asserts here
                              
                              resolve()
                          } catch (error) {
                              console.log(error)
                              reject(error)
                          }
                      })
                      // Then entering the raffle
                      console.log("Creating bet pool...")
                      const tx = await pyb.createBetPool(
                        "Ultimate Battle",
                          "My team is going to destroy the other team!!",
                          "K's team",
                          "O's team",
                          ethers.utils.parseEther("0.01") // 0.01 ETH/MATIC
                      )
                      await tx.wait(1)
                      console.log("Ok, time to wait...")
                      const creatorStartingBalance = await accounts[0].getBalance()
                      console.log("creatorStartingBalance: ", creatorStartingBalance)

                      // and this code WONT complete until our listener has finished listening!
                  })
              })
          })
      })