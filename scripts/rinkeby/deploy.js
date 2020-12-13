const { ethers, upgrades } = require("@nomiclabs/buidler");

const addresses = require("../../addresses/rinkeby.json");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log(
    "Deploying contracts with the account:",
    await deployer.getAddress()
  );

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const XStore = await ethers.getContractFactory("XStore");
  const xStore = await XStore.deploy();
  await xStore.deployed();
  console.log("XStore address:", xStore.address);

  const Nftx = await ethers.getContractFactory("NFTX");
  let nftx = await upgrades.deployProxy(Nftx, [xStore.address], {
    initializer: "initialize",
  });
  await nftx.deployed();
  console.log("NFTX proxy address:", nftx.address);

  const ProxyController = await ethers.getContractFactory("ProxyController");
  const proxyController = await ProxyController.deploy(nftx.address);
  await proxyController.deployed();
  console.log("ProxyController address:", proxyController.address);

  await upgrades.admin.changeProxyAdmin(nftx.address, proxyController.address);
  console.log("Updated NFTX proxy admin");

  await proxyController.transferOwnership(addresses.dao);
  console.log("Updated ProxyController owner");

  await xStore.transferOwnership(nftx.address);
  console.log("Updated XStore owner");

  await nftx.transferOwnership(addresses.dao);
  console.log("Updated NFTX owner");

  console.log("-- DONE --");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
