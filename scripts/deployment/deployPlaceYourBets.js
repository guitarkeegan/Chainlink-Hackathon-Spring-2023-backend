const { network, ethers, run } = require("hardhat")
const {
    networkConfig,
    developmentChains,
    VERIFICATION_BLOCK_CONFIRMATIONS,
} = require("../../helper-hardhat-config")
const { verify } = require("../../helper-functions")

async function deployPlaceYourBets(chainId) {
    console.log("running script...")

    if (developmentChains.includes(network.name)) {
        const placeYourBetsFactory = await ethers.getContractFactory("PlaceYourBets")
        const placeYourBets = await placeYourBetsFactory.deploy()

        console.log(`PlaceYourBets deployed to ${placeYourBets.address} on ${network.name}`)
    }

    // Verify the deployment
    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        log("Verifying...")
        await verify(placeYourBets.address, arguments)
    }
}

module.exports = {
    deployPlaceYourBets,
}
module.exports.tags = ["all", "placeYourBets"]
