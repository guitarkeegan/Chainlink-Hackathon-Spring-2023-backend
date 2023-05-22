const { assert, expect } = require("chai")
const { network, deployments, ethers } = require("hardhat")
const { developmentChains, networkConfig } = require("../../helper-hardhat-config")


!developmentChains.includes(network.name)
    ? describe.skip
    : describe("unit tests for PlaceYourBets", async function () {
        let accounts, streamer, placeYourBetsContract, poolCreator;
        beforeEach(async () => {
            accounts = await ethers.getSigners() // could also do with getNamedAccounts
            //   deployer = accounts[0]
            streamer = accounts[1]; 
            placeYourBetsContract = await ethers.getContractFactory("PlaceYourBets")
            poolCreator = await placeYourBetsContract 
                .connect(streamer)
                .deploy()
        });

        describe("createBetPool", function() {
           it("emits an event after successfully creating a new betting pool", async ()=>{
            await expect(poolCreator.createBetPool(
                "Ultimate Battle",
                "My team is going to destroy the other team!!",
                "K's team",
                "O's team",
                ethers.utils.parseEther("0.01") // 0.01 ETH 
            )).to.emit(
                poolCreator,
                "PoolCreated"
            );
           });
        });
    });

        // string memory _title,
        // string memory _description,
        // string memory _choice1,
        // string memory _choice2,
        // uint256 _betAmount