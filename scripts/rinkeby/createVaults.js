const { ethers, upgrades } = require("@nomiclabs/buidler");

const addresses = require("../../addresses/rinkeby.json");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log(
    "Deploying contracts with the account:",
    await deployer.getAddress()
  );

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const XToken = await ethers.getContractFactory("XToken");
  const xStore = await ethers.getContractAt("XStore", addresses.xStore);

  const nftx = await ethers.getContractAt("NFTX", addresses.nftx);

  const funds = [
    {
      ticker: "PUNK-BASIC",
      name: "Punk-Basic",
      asset: "cryptopunks",
      negateElig: true,
    },
    {
      ticker: "PUNK-ATTR-4",
      name: "Punk-Attr-4",
      asset: "cryptopunks",
      negateElig: false,
    },
    {
      ticker: "PUNK-ATTR-5",
      name: "Punk-Attr-5",
      asset: "cryptopunks",
      negateElig: false,
    },
    {
      ticker: "PUNK-ZOMBIE",
      name: "Punk-Zombie",
      asset: "cryptopunks",
      negateElig: false,
    },
    {
      ticker: "KITTY-GEN-0",
      name: "Kitty-Gen-0",
      asset: "cryptokitties",
      negateElig: false,
    },
    {
      ticker: "KITTY-GEN-0-F",
      name: "Kitty-Gen-0-Fast",
      asset: "cryptokitties",
      negateElig: false,
      flipEligOnRedeem: true,
    },
    {
      ticker: "KITTY-FANCY",
      name: "Kitty-Fancy",
      asset: "cryptokitties",
      negateElig: false,
    },
    {
      ticker: "KITTY-FOUNDER",
      name: "Kitty-Founder",
      asset: "cryptokitties",
      negateElig: false,
    },
    {
      ticker: "AXIE-ORIGIN",
      name: "Axie-Origin",
      asset: "axies",
      negateElig: false,
    },
    {
      ticker: "AXIE-MYSTIC-1",
      name: "Axie-Mystic-1",
      asset: "axies",
      negateElig: false,
    },
    {
      ticker: "AXIE-MYSTIC-2",
      name: "Axie-Mystic-2",
      asset: "axies",
      negateElig: false,
    },
    {
      ticker: "AVASTR-RANK-25",
      name: "Avastar-Rank-25",
      asset: "avastars",
      negateElig: false,
    },
    {
      ticker: "AVASTR-RANK-50",
      name: "Avastar-Rank-50",
      asset: "avastars",
      negateElig: false,
    },
    {
      ticker: "AVASTR-RANK-75",
      name: "Avastar-Rank-75",
      asset: "avastars",
      negateElig: false,
    },
    { ticker: "GLYPH", name: "Glyph", asset: "autoglyphs", negateElig: true },
    { ticker: "JOY", name: "Joy", asset: "joys", negateElig: false },
  ];

  for (let i = 0; i < funds.length; i++) {
    const fund = funds[i];
    const fundToken = await XToken.deploy(
      fund.name,
      fund.ticker,
      addresses.nftx
    );
    await fundToken.deployed();
    console.log(`${fund.ticker} deployed to ${fundToken.address}`);
    funds[i].tokenAddress = fundToken.address;

    await nftx.createVault(fund.tokenAddress, addresses[fund.asset], false);
    console.log(`Vault created: ${fund.ticker}`);

    await new Promise((resolve) => setTimeout(() => resolve(), 5000));
    console.log('continuing...');

    if (fund.flipEligOnRedeem) {
      await nftx.setFlipEligOnRedeem(i, true, {
        gasLimit: "9500000",
      });
      console.log(`${fund.ticker} flipEligOnRedeem set to true`);

      await new Promise((resolve) => setTimeout(() => resolve(), 5000));
    console.log('continuing...');
    }
    if (fund.negateElig == false) {
      await nftx.setNegateEligibility(i, false, {
        gasLimit: "9500000",
      });
      console.log(`${fund.ticker} negateEligibility set to false`);

      await new Promise((resolve) => setTimeout(() => resolve(), 5000));
    console.log('continuing...');
    } else {
      await nftx.finalizeVault(i, {
        gasLimit: "9500000",
      });
      console.log(`${fund.ticker} finalized`);

      await new Promise((resolve) => setTimeout(() => resolve(), 5000));
    console.log('continuing...');
    }
    console.log("");
  }

  console.log("-- DONE --");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
