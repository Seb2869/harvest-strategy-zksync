const prompt = require('prompt');
const hre = require("hardhat");
const { Deployer } = require("@matterlabs/hardhat-zksync-deploy")
const ethers = require("ethers");

const addresses = require("../../test/test-config.js")

async function main() {
    prompt.start();
    const wallet = await zksyncEthers.getWallet()
    const deployer = new Deployer(hre, wallet);
    
    const registry = await zksyncEthers.getContractAt("UniversalLiquidatorRegistry", addresses.UniversalLiquidator.UniversalLiquidatorRegistry);
    const {dex, name} = await prompt.get(['dex', 'name']);

    // const Dex = await deployer.loadArtifact(dex);
    // const contract = await deployer.deploy(Dex);
    // const verificationId = await hre.run("verify:verify", {address: contract.target});
    // console.log("Verifying source code. Id:", verificationId);

    const contract = {target: "0xbcA906cf83ecc33f41C82073677f91f6c4D98486"}
    const nameBytes = ethers.solidityPackedKeccak256(["bytes"], [ethers.toUtf8Bytes(name)]);
    console.log(`${dex} id:`, nameBytes);
    console.log(`${dex} address:`, contract.target);
    await registry.addDex(nameBytes, contract.target);
    console.log("Dex added to the Registry:", nameBytes, contract.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
