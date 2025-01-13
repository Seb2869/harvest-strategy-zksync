const prompt = require('prompt');
const hre = require("hardhat");
const { Deployer } = require("@matterlabs/hardhat-zksync")

async function main() {
  console.log("New implementation deployment.");
  console.log("Specify the implementation contract's name");
  prompt.start();
  const wallet = await zksyncEthers.getWallet()
  const deployer = new Deployer(hre, wallet);

  const {implName} = await prompt.get(['implName']);

  const ImplContract = await deployer.loadArtifact(implName);
  const impl = await deployer.deploy(ImplContract);
  // const verificationId = await hre.run("verify:verify", {address: impl.target});
  // console.log("Verifying source code. Id:", verificationId);

  console.log("Deployment complete. Implementation deployed at:", impl.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
