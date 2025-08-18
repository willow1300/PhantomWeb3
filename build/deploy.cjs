// build/deploy.cjs
require("dotenv").config();
const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

// destructure the commonly used exports from ethers so it works across v5/v6
const { JsonRpcProvider, Wallet, ContractFactory, formatEther } = require("ethers");

async function main() {
  console.log(`🔹 Network: ${hre.network.name}`);
  console.log(`🔹 RPC URL: ${hre.network.config.url}`);

  const PK = process.env.DEPLOYER_PRIVATE_KEY;
  if (!PK) {
    throw new Error("DEPLOYER_PRIVATE_KEY not set in .env");
  }

  // Build provider & wallet
  const provider = new JsonRpcProvider(hre.network.config.url);
  const deployerWallet = new Wallet(PK, provider);
  console.log(`👤 Deployer: ${deployerWallet.address}`);

  const balance = await provider.getBalance(deployerWallet.address);
  console.log(`💰 FTM Balance: ${formatEther(balance)} FTM`);

  // artifact path (adjust if your contract file name differs)
  const artifactPath = path.join(__dirname, "..", "artifacts", "contracts", "JEFE.sol", "JEFE.json");
  if (!fs.existsSync(artifactPath)) {
    throw new Error(`Artifact not found: ${artifactPath}`);
  }
  const artifact = JSON.parse(fs.readFileSync(artifactPath, "utf8"));
  const abi = artifact.abi;
  const bytecode = artifact.bytecode;

  // Create ContractFactory and deploy
  const factory = new ContractFactory(abi, bytecode, deployerWallet);

  const routerAddress = process.env.ROUTER_ADDRESS || "0xF491e7B69E4244ad4002BC14e878a34207E38c29";
  console.log(`🚀 Deploying JEFE with router = ${routerAddress}`);

  const contract = await factory.deploy(routerAddress);

 // Wait for deployment to be mined (works for ethers v5 & v6)
  if (typeof contract.waitForDeployment === "function") {
    await contract.waitForDeployment();
  } else if (contract.deployTransaction) {
    // ethers v5 style
    const receipt = await contract.deployTransaction.wait();
    // receipt.contractAddress exists for contract creation txs
    if (receipt && receipt.contractAddress) {
      deployedAddress = receipt.contractAddress;
    }
  }

   // Fallbacks to get address in ethers v6/v5:
  let deployedAddress;
  try {
    if (typeof contract.getAddress === "function") {
      deployedAddress = await contract.getAddress(); // ethers v6 preferred
    }
  } catch (e) { /* ignore */ }

  // other fallbacks
  if (!deployedAddress && contract.address) deployedAddress = contract.address;
  if (!deployedAddress && contract.target) deployedAddress = contract.target;
  // last resort: check the deployTransaction receipt from provider
  if (!deployedAddress && contract.deployTransaction) {
    const prov = contract.provider || provider; // provider from earlier
    try {
      const rec = await prov.getTransactionReceipt(contract.deployTransaction.hash);
      if (rec && rec.contractAddress) deployedAddress = rec.contractAddress;
    } catch (e) { /* ignore */ }
  }

  if (!deployedAddress) {
    throw new Error("Could not determine deployed contract address. Inspect transaction and contract object.");
  }

  console.log(`✅ JEFE deployed at: ${deployedAddress}`);

  console.log("\n🔍 To verify on FTMScan (run from project root):");
  console.log(
    `npx hardhat verify --network ${hre.network.name} --contract contracts/Jefe_inlined.sol:JEFE ${contract.address} "${routerAddress}"`
  );
}

main().catch((err) => {
  console.error("❌ Deployment failed:", err);
  process.exit(1);
});
