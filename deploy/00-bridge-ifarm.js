const { Deployer } = require("@matterlabs/hardhat-zksync-deploy")
const { Wallet, Provider } = require("zksync-web3")
const secret = require('../dev-keys.json');

// Token address
const TOKEN_ADDRESS = "0x1571eD0bed4D987fe2b498DdBaE7DFA19519F651";

// Amount of tokens 
const AMOUNT = "1";

module.exports =  async function (hre) {
  console.log(`Running script to bridge ERC20 to L2`);

  // Initialize the wallet.
  const provider = new Provider(
    hre.config.networks.mainnet.ethNetwork
  );
  const mnemonicWallet = ethers.Wallet.fromMnemonic(secret.mnemonic)
  const wallet = new Wallet(mnemonicWallet.privateKey, provider)

  // Create deployer object 
  const deployer = new Deployer(hre, wallet);

  // Deposit ERC20 tokens to L2
  const depositHandle = await deployer.zkWallet.deposit({
    to: deployer.zkWallet.address,
    token: TOKEN_ADDRESS,
    amount: ethers.utils.parseEther(AMOUNT), // assumes ERC20 has 18 decimals
    // performs the ERC20 approve action
    approveERC20: true,
  });

  console.log(`Deposit transaction sent ${depositHandle.hash}`);
  console.log(`Waiting for deposit to be processed in L2...`);
  // Wait until the deposit is processed on zkSync
  await depositHandle.wait();
  console.log(`ERC20 tokens available in L2`);
}