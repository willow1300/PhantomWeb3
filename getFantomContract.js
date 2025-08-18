const { ethers } = require("ethers");
const axios = require("axios");
const fs = require("fs");

// Fantom RPC endpoint (can use others if rate-limited)
const RPC = "https://rpc.ftm.tools";

// FTMScan API (only helps if ABI is available — optional)
const FTMSCAN_API = "https://api.ftmscan.com/api";
const API_KEY = "YourApiKeyHere"; // get from ftmscan.com (optional for ABI)

// Replace with any Fantom token address
const CONTRACT_ADDRESS = "0xYourTokenAddress";

async function fetchContractBytecode(address) {
  const provider = new ethers.providers.JsonRpcProvider(RPC);
  const bytecode = await provider.getCode(address);
  if (!bytecode || bytecode === "0x") {
    console.error("No contract found at this address.");
    return;
  }
  fs.writeFileSync("bytecode.txt", bytecode);
  console.log("✅ Bytecode saved to bytecode.txt");
}

async function fetchContractABI(address) {
  try {
    const res = await axios.get(FTMSCAN_API, {
      params: {
        module: "contract",
        action: "getabi",
        address,
        apikey: API_KEY,
      },
    });
    if (res.data.status !== "1") {
      console.warn("⚠️ ABI not available or contract not verified.");
      return;
    }
    const abi = res.data.result;
    fs.writeFileSync("abi.json", abi);
    console.log("✅ ABI saved to abi.json");
  } catch (err) {
    console.error("Error fetching ABI:", err.message);
  }
}

async function main() {
  console.log(`📦 Fetching contract from Fantom: ${CONTRACT_ADDRESS}`);
  await fetchContractBytecode(CONTRACT_ADDRESS);
  await fetchContractABI(CONTRACT_ADDRESS);
}

main();
