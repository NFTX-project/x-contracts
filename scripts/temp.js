// import zombidIds from "../data/zombies";

const { ethers, upgrades } = require("@nomiclabs/buidler");

const ProxyController = require("../artifacts/ProxyController.json");

// const zeroAddress = "0x0000000000000000000000000000000000000000";

const rinkebyDaoAddress = "0xeddb1b92b9ad55a5bb1dcc22c23e7839cd3dc99c";

const proxyControllerAddr = "0x49706a576bb823cdE3180C930F9947d59e2deD4D";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Using the account:", await deployer.getAddress());

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const proxyController = await ethers.getContractAt(
    "ProxyController",
    proxyControllerAddr
  );

  await proxyController.updateImplAddress();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
