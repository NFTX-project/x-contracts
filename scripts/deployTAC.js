async function main() {
  const [deployer] = await ethers.getSigners();

  console.log(
    "Deploying contracts with the account:",
    await deployer.getAddress()
  );

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const tokenManagerAddress = "0xbc43db7dddabd068732025107a0026fe758770d2";
  const xDaoAgent = "0xeddb1b92b9ad55a5bb1dcc22c23e7839cd3dc99c";

  const TAC = await ethers.getContractFactory("TokenAppController");

  const tac = await TAC.deploy();
  await tac.deployed();

  await tac.setTokenManager(tokenManagerAddress);
  await tac.transferOwnership(xDaoAgent);

  console.log("TAC address:", tac.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
