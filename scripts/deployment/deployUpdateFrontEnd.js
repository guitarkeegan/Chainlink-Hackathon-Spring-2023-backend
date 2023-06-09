const { ethers, network } = require("hardhat")
const fs = require("fs")

const FRONT_END_ADDRESSES_FILE =
    "../../../hackathon-spring-2023-frontend/my-app/constants/contractAddresses.json"
const FRONT_END_ABI_FILE = "../../../hackathon-spring-2023-frontend/my-app/constants/abiFile.json"

async function updateFrontend(chainId) {
    if (process.env.UPDATE_FRONT_END) {
        console.log("Updateing Front End...")
        updateContractAddresses()
        updateAbi()
    }
}

async function updateAbi() {
    const pyb = await ethers.getContract("PlaceYourBets")
    fs.writeFileSync(FRONT_END_ABI_FILE, pyb.interface.format(ethers.utils.FormatTypes.json))
}

async function updateContractAddresses() {
    const pyb = await ethers.getContract("PlaceYourBets")
    const chainId = network.config.chainId.toString()
    const currentAddress = JSON.parse(fs.readFileSync(FRONT_END_ADDRESSES_FILE, "utf8"))
    if (chainId in currentAddress) {
        if (!currentAddress[chainId].includes(pyb.address)) {
            currentAddress[chainId].push(pyb.address)
        }
    }
    {
        currentAddress[chainId] = [pyb.address]
    }
    fs.writeFileSync(FRONT_END_ADDRESSES_FILE, JSON.stringify(currentAddress))
}
module.exports = { updateFrontend }
module.exports.tags = ["all", "frontend"]
