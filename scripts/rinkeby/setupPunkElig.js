const { ethers, upgrades } = require("@nomiclabs/buidler");

const addresses = require("../../addresses/rinkeby.json");

const punkAttr4Ids = require("../../data/punk/punkAttr4.json");
const punkAttr5Ids = require("../../data/punk/punkAttr5.json");
const punkZombieIds = require("../../data/punk/punkZombie.json");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log(
    "Deploying contracts with the account:",
    await deployer.getAddress()
  );

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const xStore = await ethers.getContractAt("XStore", addresses.xStore);
  const nftx = await ethers.getContractAt("NFTX", addresses.nftx);

  const data = [
    {
      vaultId: 1,
      ids: punkAttr4Ids
    },
    {
      vaultId: 2,
      ids: punkAttr5Ids
    },
    {
      vaultId: 3,
      ids: punkZombieIds
    }
  ];

  for (let i = 0; i < data.length; i++) {
    const {vaultId, ids} = data[i];
    let j = 0;
    while (j < ids.length) {
      let k = Math.min(j+500, ids.length);
      const nftIds = punkAttr5Ids.slice(j, k);
      console.log(`i: ${i}, j: ${j}, k: ${k}\n`);
      await nftx.setIsEligible(vaultId, nftIds, true);
      j = k;
    }
    await nftx.finalizeVault(vaultId, {
      gasLimit: "9500000",
    });
    console.log(`Vault ${vaultId} finalized\n`);
  }
  
  console.log("-- DONE --");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
