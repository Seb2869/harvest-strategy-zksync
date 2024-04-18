const hre = require("hardhat");
const { Deployer } = require("@matterlabs/hardhat-zksync-deploy")

async function main() {
    const wallet = await zksyncEthers.getWallet()
    const deployer = new Deployer(hre, wallet);
  
    const ULR = await deployer.loadArtifact("UniversalLiquidatorRegistry");
    const registry = await deployer.deploy(ULR);  
    console.log("ULR address:", registry.target);
    const verificationId1 = await hre.run("verify:verify", {address: registry.target});
    console.log("Verifying source code. Id:", verificationId1);  

    const UL = await deployer.loadArtifact("UniversalLiquidator");
    const universalLiquidator = await deployer.deploy(UL);  
    await universalLiquidator.setPathRegistry(registry.target);
    console.log("UL address:", universalLiquidator.target);
    const verificationId2 = await hre.run("verify:verify", {address: universalLiquidator.target});
    console.log("Verifying source code. Id:", verificationId2);  
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
