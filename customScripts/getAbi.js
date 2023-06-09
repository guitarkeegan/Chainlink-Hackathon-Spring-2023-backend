require("dotenv").config();
const fs = require("fs")
async function main() {
    console.log("getting contract...")

    try {
    
    const res = await fetch(`https://api.polygonscan.com/api
    ?module=contract
    &action=getabi
    &address=0x08EE4c6a5471332BfcC26A8eAeB50816cf756B78
    &apikey=${process.env.POLYGONSCAN_API_KEY}`)
    const obj = await res.json()
    console.log("json obj: ", obj)

    console.log("writing file...");
    fs.writeFileSync("./abi.json", obj["result"])
    }catch(e){
        console.error(e);
    }

}

main()
    .then(() => console.log("file created!"))
    .catch((e) => console.error(e))
