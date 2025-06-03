const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const GameScores = await hre.ethers.getContractFactory("GameScores");
  const gameScores = await GameScores.deploy(deployer.address);

  await gameScores.waitForDeployment();
  const address = await gameScores.getAddress();
  console.log("GameScores deployed to:", address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 