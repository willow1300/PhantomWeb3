import fs from 'fs';
import solc from 'solc';

const contractPath = "D:/webProjects/USDTcoin/artifacts/contracts/usdt~.sol/FlashUSDT.json";
const source = fs.readFileSync(contractPath, "utf8");

const input = {
    language: "Solidity",
    sources: {
        "usdt~.sol": {
            content: source,
        },
    },
    settings: {
        outputSelection: {
            "*": {
                "*": ["abi", "evm.bytecode.object"],
            },
        },
    },
};

const output = JSON.parse(solc.compile(JSON.stringify(input)));

// Log the output to check for errors
console.log("Solidity Compiler Output:", JSON.stringify(output, null, 2));

if (output.errors) {
    console.error("Compilation errors detected:");
    output.errors.forEach((err) => console.error(err.formattedMessage));
    process.exit(1); // Exit with error
}

// Ensure contract exists
if (!output.contracts || !output.contracts['usdt~.sol']) {
    console.error("No contracts found in compilation output.");
    process.exit(1);
}

const contractName = Object.keys(output.contracts['usdt~.sol'])[0]; // Get contract name  
const contract = output.contracts['usdt~.sol'][contractName];

fs.writeFileSync("D:/webProjects/USDTcoin/build/contractABI.json", JSON.stringify(contract.abi, null, 2));
fs.writeFileSync("D:/webProjects/USDTcoin/build/contractBytecode.txt", contract.evm.bytecode.object);


console.log("Compilation successful!");
