// import zombidIds from "../data/zombies";

const { ethers, upgrades } = require("@nomiclabs/buidler");

const zeroAddress = "0x0000000000000000000000000000000000000000";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log(
    "Deploying contracts with the account:",
    await deployer.getAddress()
  );

  console.log("Account balance:", (await deployer.getBalance()).toString());

  /* const Cpm = await ethers.getContractFactory("CryptoPunksMarket");
  const cpm = await Cpm.deploy();
  await cpm.deployed();
  console.log("CPM address:", cpm.address);
  const XStore = await ethers.getContractFactory("XStore");
  const xStore = await XStore.deploy();
  await xStore.deployed();
  console.log("XStore address:", xStore.address); */
  const Nftx = await ethers.getContractFactory("NFTX");
  let nftx = await upgrades.deployProxy(Nftx, [zeroAddress, zeroAddress], {
    initializer: "initialize",
  });
  await nftx.deployed();
  console.log("NFTX address:", nftx.address);

  const NftxV2 = await ethers.getContractFactory("NFTXv2");
  console.log("Preparing upgrade...");
  const nftxV2Address = await upgrades.prepareUpgrade(nftx.address, NftxV2);
  console.log("NftxV2 at:", nftxV2Address);

  // nftx.upgradeTo( )

  // await xStore.transferOwnership(nftx.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
