const { BigNumber } = require("ethers");

const BASE = BigNumber.from(10).pow(18);
const UNIT = BASE.div(100);
const zeroAddress = "0x0000000000000000000000000000000000000000";

const getIntArray = (firstElem, firstNonElem) => {
  const arr = [];
  for (let i = firstElem; i < firstNonElem; i++) {
    arr.push(i);
  }
  return arr;
};

const initializeAssetTokenVault = async (
  nftx,
  signers,
  assetNameOrExistingContract,
  xTokenName,
  idsToMint,
  isD2
) => {
  const [owner, misc, alice, bob, carol, dave, eve] = signers;

  const XToken = await ethers.getContractFactory("XToken");
  const xToken = await XToken.deploy(
    xTokenName,
    xTokenName.toUpperCase(),
    nftx.address
  );
  await xToken.deployed();

  let asset;
  if (typeof assetNameOrExistingContract == "string") {
    let name = assetNameOrExistingContract;
    if (isD2) {
      const Erc20 = await ethers.getContractFactory("D2Token");
      asset = await Erc20.deploy(name, name.toUpperCase());
    } else {
      const Erc721 = await ethers.getContractFactory("ERC721");
      asset = await Erc721.deploy(name, name.toUpperCase());
    }
    await asset.deployed();
  } else {
    asset = assetNameOrExistingContract;
  }
  const response = await nftx
    .connect(owner)
    .createVault(xToken.address, asset.address, isD2);
  const receipt = await response.wait(0);

  const vaultId = receipt.events
    .find((elem) => elem.event === "NewVault")
    .args[0].toString();
  await nftx.connect(owner).finalizeVault(vaultId);
  if (isD2) {
    if (typeof assetNameOrExistingContract == "string") {
      await asset.mint(misc._address, BASE.mul(1000));
    }
  } else {
    await checkMintNFTs(asset, idsToMint, misc);
  }
  return { asset, xToken, vaultId };
};

const checkMintNFTs = async (nft, nftIds, to) => {
  for (let i = 0; i < nftIds.length; i++) {
    try {
      await nft.ownerOf(nftIds[i]);
    } catch (err) {
      await nft.safeMint(to._address, nftIds[i]);
    }
  }
};

const transferNFTs = async (nftx, nft, nftIds, sender, recipient) => {
  for (let i = 0; i < nftIds.length; i++) {
    await nft
      .connect(sender)
      .transferFrom(sender._address, recipient._address, nftIds[i]);
  }
};

const setup = async (nftx, nft, signers, eligIds) => {
  const [owner, misc, alice, bob, carol, dave, eve] = signers;
  await transferNFTs(nftx, nft, eligIds.slice(0, 8), misc, alice);
  await transferNFTs(nftx, nft, eligIds.slice(8, 16), misc, bob);
  await transferNFTs(nftx, nft, eligIds.slice(16, 19), misc, carol);
  await transferNFTs(nftx, nft, eligIds.slice(19, 20), misc, dave);
};

const setupD2 = async (nftx, asset, signers) => {
  const [owner, misc, alice, bob, carol, dave, eve] = signers;
  await asset.connect(misc).transfer(alice._address, BASE.mul(8));
  await asset.connect(misc).transfer(bob._address, BASE.mul(8));
  await asset.connect(misc).transfer(carol._address, BASE.mul(3));
  await asset.connect(misc).transfer(dave._address, BASE.mul(1));
};

const cleanup = async (nftx, nft, token, signers, vaultId, eligIds) => {
  const [owner, misc, alice, bob, carol, dave, eve] = signers;
  for (let i = 2; i < 7; i++) {
    const signer = signers[i];
    const bal = (await token.balanceOf(signer._address)).div(BASE).toNumber();
    if (bal > 0) {
      await approveAndRedeem(nftx, token, bal, signer, vaultId);
    }
  }
  for (let i = 0; i < 40; i++) {
    try {
      const nftId = eligIds[i];
      let addr;
      addr = await nft.ownerOf(nftId);
      if (addr == misc._address) {
        // console.log(`owner of ${nftId} is misc (${addr})`);
        continue;
      }
      const signerIndex = signers.findIndex((s) => s._address == addr);
      const signer = signers[signerIndex];
      /* console.log(
        `owner of ${nftId} is signer ${signerIndex} (${signer._address})`
      ); */
      await nft
        .connect(signer)
        .transferFrom(signer._address, misc._address, nftId);
    } catch (err) {
      // console.log("catch:", i, "continuing...");
      break;
    }
  }
};

const cleanupD2 = async (nftx, asset, xToken, signers, vaultId) => {
  const [owner, misc, alice, bob, carol, dave, eve] = signers;
  for (let i = 2; i < 7; i++) {
    const signer = signers[i];
    const xBal = await xToken.balanceOf(signer._address);
    if (xBal.gt(0)) {
      await approveAndRedeemD2(nftx, xToken, bal, signer, vaultId, 0);
    }
    const assetBal = await asset.balanceOf(signer._address);
    if (assetBal.gt(0)) {
      await asset.connect(signer).transfer(misc._address, assetBal);
    }
  }
};

const holdingsOf = async (nft, nftIds, accounts, isD2) => {
  const lists = [];
  for (let i = 0; i < accounts.length; i++) {
    const account = accounts[i];
    const list = [];
    for (let _i = 0; _i < nftIds.length; _i++) {
      const id = nftIds[_i];
      const nftOwner = await nft.ownerOf(id);
      if (nftOwner === account._address) {
        list.push(id);
      }
    }
    lists.push(list);
  }
  return lists;
};

const balancesOf = async (token, accounts) => {
  const balances = [];
  for (let i = 0; i < accounts.length; i++) {
    balances.push(await token.balanceOf(accounts[i]._address));
  }
  return balances;
};

const checkBalances = async (nftx, nft, xToken, users) => {
  let tokenAmount = BigNumber.from(0);
  for (let i = 0; i < users.length; i++) {
    const user = users[i];
    const bal = await xToken.balanceOf(user._address);
    tokenAmount = tokenAmount.add(bal);
  }
  const nftAmount = await nft.balanceOf(nftx.address);
  if (!nftAmount.mul(BASE).eq(tokenAmount)) {
    throw "Balances do not match up";
  }
};

const checkBalancesD2 = async (nftx, asset, xToken, accounts) => {
  let tokenAmount = BigNumber.from(0);
  const balances = await balancesOf(xToken, accounts);
  balances.forEach((balance) => {
    tokenAmount = tokenAmount.add(balance);
  });
  const contractBal = await asset.balanceOf(nftx.address);
  if (tokenAmount.toString() !== contractBal.toString()) {
    throw "Balances do not match up (D2)";
  }
};

const approveEach = async (nft, nftIds, signer, to) => {
  for (let i = 0; i < nftIds.length; i++) {
    const nftId = nftIds[i];
    await nft.connect(signer).approve(to, nftId);
  }
};

const approveAndMint = async (nftx, nft, nftIds, signer, vaultId, value) => {
  await approveEach(nft, nftIds, signer, nftx.address);
  await nftx.connect(signer).mint(vaultId, nftIds, 0, { value: value });
};

const approveAndMintD2 = async (
  nftx,
  asset,
  amount,
  signer,
  vaultId,
  value
) => {
  await asset.connect(signer).approve(nftx.address, amount);
  await nftx.connect(signer).mint(vaultId, [], amount, { value: value });
};

const approveAndRedeem = async (
  nftx,
  xToken,
  amount,
  signer,
  vaultId,
  value = 0
) => {
  await xToken
    .connect(signer)
    .approve(nftx.address, BASE.mul(amount).toString());
  await nftx.connect(signer).redeem(vaultId, amount, { value: value });
};

const approveAndRedeemD2 = async (
  nftx,
  xToken,
  amount,
  signer,
  vaultId,
  value
) => {
  await xToken.connect(signer).approve(nftx.address, amount);
  await nftx.connect(signer).redeem(vaultId, amount, { value: value });
};

exports.getIntArray = getIntArray;
exports.initializeAssetTokenVault = initializeAssetTokenVault;
exports.checkMintNFTs = checkMintNFTs;
exports.transferNFTs = transferNFTs;
exports.setup = setup;
exports.setupD2 = setupD2;
exports.cleanup = cleanup;
exports.cleanupD2 = cleanupD2;
exports.holdingsOf = holdingsOf;
exports.balancesOf = balancesOf;
exports.checkBalances = checkBalances;
exports.checkBalancesD2 = checkBalancesD2;
exports.approveEach = approveEach;
exports.approveAndMint = approveAndMint;
exports.approveAndMintD2 = approveAndMintD2;
exports.approveAndRedeem = approveAndRedeem;
exports.approveAndRedeemD2 = approveAndRedeemD2;
