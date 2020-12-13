const { BigNumber } = require("ethers");
const { expect } = require("chai");
const { expectRevert } = require("../utils/expectRevert");

const BASE = BigNumber.from(10).pow(18);
const UNIT = BASE.div(100);

const {
  transferNFTs,
  setup,
  cleanup,
  holdingsOf,
  checkBalances,
  approveEach,
  approveAndMint,
  approveAndRedeem,
  setupD2,
  balancesOf,
  approveAndMintD2,
  checkBalancesD2,
  approveAndRedeemD2,
  cleanupD2,
} = require("./_helpers");

const runVaultTests = async (
  nftx,
  asset,
  xToken,
  signers,
  vaultId,
  allNftIds,
  eligIds,
  isD2
) => {
  const [owner, misc, alice, bob, carol, dave, eve] = signers;

  const notEligIds = allNftIds.filter((elem) => !eligIds.includes(elem));

  //////////////////
  // mint, redeem //
  //////////////////

  const runMintRedeem = async () => {
    console.log("Testing: mint, redeem...\n");
    await setup(nftx, asset, signers, eligIds);
    let [aliceNFTs, bobNFTs] = await holdingsOf(asset, eligIds, [alice, bob]);

    await approveAndMint(nftx, asset, aliceNFTs, alice, vaultId, 0);
    await approveAndMint(nftx, asset, bobNFTs, bob, vaultId, 0);
    await checkBalances(nftx, asset, xToken, signers.slice(2));
    await approveAndRedeem(nftx, xToken, aliceNFTs.length, alice, vaultId);
    await approveAndRedeem(nftx, xToken, bobNFTs.length, bob, vaultId);

    [aliceNFTs, bobNFTs] = await holdingsOf(asset, eligIds, [alice, bob]);
    console.log(aliceNFTs);
    console.log(bobNFTs, "\n");
    await checkBalances(nftx, asset, xToken, signers.slice(2));
    await cleanup(nftx, asset, xToken, signers, vaultId, eligIds);
  };

  const runMintRedeemD2 = async () => {
    console.log("Testing (D2): mint, redeem...\n");
    await setupD2(nftx, asset, signers);
    const [aliceBal, bobBal] = await balancesOf(asset, [alice, bob]);
    await approveAndMintD2(nftx, asset, aliceBal, alice, vaultId, 0);
    await approveAndMintD2(nftx, asset, bobBal, bob, vaultId, 0);
    await checkBalancesD2(nftx, asset, xToken, [alice, bob]);
    await approveAndRedeemD2(nftx, xToken, aliceBal, alice, vaultId, 0);
    await approveAndRedeemD2(nftx, xToken, bobBal, bob, vaultId, 0);

    await checkBalancesD2(nftx, asset, xToken, [alice, bob]);
    await cleanupD2(nftx, asset, xToken, signers, vaultId);
  };

  ///////////////////
  // mintAndRedeem //
  ///////////////////

  const runMintAndRedeem = async () => {
    console.log("Testing: mintAndRedeem...\n");
    await setup(nftx, asset, signers, eligIds);
    let [aliceNFTs, bobNFTs] = await holdingsOf(asset, eligIds, [alice, bob]);
    await approveAndMint(nftx, asset, aliceNFTs, alice, vaultId, 0);

    await approveEach(asset, bobNFTs, bob, nftx.address);
    await nftx.connect(bob).mintAndRedeem(vaultId, bobNFTs);
    await checkBalances(nftx, asset, xToken, signers.slice(2));

    [bobNFTs] = await holdingsOf(asset, eligIds, [bob]);
    console.log(bobNFTs, "\n");
    await cleanup(nftx, asset, xToken, signers, vaultId, eligIds);
  };

  ////////////////////////
  // mintFees, burnFees //
  ////////////////////////

  const runMintFeesBurnFees = async () => {
    console.log("Testing: mintFees, burnFees...\n");
    await setup(nftx, asset, signers, eligIds);
    let [aliceNFTs, bobNFTs] = await holdingsOf(asset, eligIds, [alice, bob]);
    await nftx.connect(owner).setMintFees(vaultId, UNIT.mul(5), UNIT);
    await nftx.connect(owner).setBurnFees(vaultId, UNIT.mul(5), UNIT);

    const n = aliceNFTs.length;
    let amount = UNIT.mul(5).add(UNIT.mul(n - 1));
    await expectRevert(
      approveAndMint(nftx, asset, aliceNFTs, alice, vaultId, amount.sub(1))
    );
    await approveAndMint(nftx, asset, aliceNFTs, alice, vaultId, amount);
    await checkBalances(nftx, asset, xToken, signers.slice(2));
    await expectRevert(
      approveAndRedeem(nftx, xToken, n, alice, vaultId, amount.sub(1))
    );
    await approveAndRedeem(nftx, xToken, n, alice, vaultId, amount);
    await checkBalances(nftx, asset, xToken, signers.slice(2));

    await nftx.connect(owner).setMintFees(vaultId, 0, 0);
    await nftx.connect(owner).setBurnFees(vaultId, 0, 0);
    await cleanup(nftx, asset, xToken, signers, vaultId, eligIds);
  };

  const runMintFeesBurnFeesD2 = async () => {
    console.log("Testing (D2): mintFees, burnFees...\n");
    await setupD2(nftx, asset, signers);
    const [aliceBal] = await balancesOf(asset, [alice]);
    await nftx.connect(owner).setMintFees(vaultId, UNIT.mul(5), UNIT);
    await nftx.connect(owner).setBurnFees(vaultId, UNIT.mul(5), UNIT);

    const n = aliceBal.div(BASE);
    const amount = UNIT.mul(5).add(UNIT.mul(n - 1));
    await expectRevert(
      approveAndMintD2(nftx, asset, aliceBal, alice, vaultId, amount.sub(1))
    );
    await approveAndMintD2(nftx, asset, aliceBal, alice, vaultId, amount);
    await checkBalancesD2(nftx, asset, xToken, [alice]);
    await expectRevert(
      approveAndRedeemD2(nftx, xToken, aliceBal, alice, vaultId, amount.sub(1))
    );
    await approveAndRedeemD2(nftx, xToken, aliceBal, alice, vaultId, amount);
    await nftx.connect(owner).setMintFees(vaultId, 0, 0);
    await nftx.connect(owner).setBurnFees(vaultId, 0, 0);
    await checkBalancesD2(nftx, asset, xToken, [alice]);
    await cleanupD2(nftx, asset, xToken, signers, vaultId);
  };

  //////////////
  // dualFees //
  //////////////

  const runDualFees = async () => {
    console.log("Testing: dualFees...\n");
    await setup(nftx, asset, signers, eligIds);
    let [aliceNFTs, bobNFTs] = await holdingsOf(asset, eligIds, [alice, bob]);
    await nftx.connect(owner).setDualFees(vaultId, UNIT.mul(5), UNIT);
    await approveAndMint(nftx, asset, aliceNFTs, alice, vaultId, 0);

    await approveEach(asset, bobNFTs, bob, nftx.address);
    let amount = UNIT.mul(5).add(UNIT.mul(bobNFTs.length - 1));
    await expectRevert(
      nftx
        .connect(bob)
        .mintAndRedeem(vaultId, bobNFTs, { value: amount.sub(1) })
    );
    await nftx.connect(bob).mintAndRedeem(vaultId, bobNFTs, { value: amount });

    await nftx.connect(owner).setDualFees(vaultId, 0, 0);
    await cleanup(nftx, asset, xToken, signers, vaultId, eligIds);
  };

  ////////////////////
  // supplierBounty //
  ////////////////////

  const runSupplierBounty = async () => {
    console.log("Testing: supplierBounty...\n");
    await setup(nftx, asset, signers, eligIds);
    let [aliceNFTs] = await holdingsOf(asset, eligIds, [alice]);
    await nftx.connect(owner).depositETH(vaultId, { value: UNIT.mul(100) });
    await nftx.connect(owner).setSupplierBounty(vaultId, UNIT.mul(10), 5);

    let nftxBal1 = BigNumber.from(await web3.eth.getBalance(nftx.address));
    let aliceBal1 = BigNumber.from(await web3.eth.getBalance(alice._address));
    await approveAndMint(nftx, asset, aliceNFTs, alice, vaultId, 0);
    let nftxBal2 = BigNumber.from(await web3.eth.getBalance(nftx.address));
    let aliceBal2 = BigNumber.from(await web3.eth.getBalance(alice._address));
    expect(nftxBal2.toString()).to.equal(
      nftxBal1.sub(UNIT.mul(10 + 8 + 6 + 4 + 2)).toString()
    );
    expect(aliceBal2.gt(aliceBal1)).to.equal(true);
    await approveAndRedeem(
      nftx,
      xToken,
      aliceNFTs.length,
      alice,
      vaultId,
      UNIT.mul(10 + 8 + 6 + 4 + 2).toString()
    );
    let nftxBal3 = BigNumber.from(await web3.eth.getBalance(nftx.address));
    let aliceBal3 = BigNumber.from(await web3.eth.getBalance(alice._address));
    expect(nftxBal3.toString()).to.equal(nftxBal1.toString());
    expect(aliceBal3.lt(aliceBal2)).to.equal(true);

    await nftx.connect(owner).setSupplierBounty(vaultId, 0, 0);
    await cleanup(nftx, asset, xToken, signers, vaultId, eligIds);
  };

  const runSupplierBountyD2 = async () => {
    console.log("Testing (D2): supplierBounty...\n");
    await setupD2(nftx, asset, signers);
    const [aliceBal] = await balancesOf(asset, [alice]);
    await nftx.connect(owner).depositETH(vaultId, { value: UNIT.mul(100) });
    await nftx
      .connect(owner)
      .setSupplierBounty(vaultId, UNIT.mul(10), BASE.mul(5));

    let nftxBal1 = BigNumber.from(await web3.eth.getBalance(nftx.address));
    let aliceBal1 = BigNumber.from(await web3.eth.getBalance(alice._address));
    await approveAndMintD2(nftx, asset, aliceBal, alice, vaultId, 0);
    await checkBalancesD2(nftx, asset, xToken, [alice]);
    let nftxBal2 = BigNumber.from(await web3.eth.getBalance(nftx.address));
    let aliceBal2 = BigNumber.from(await web3.eth.getBalance(alice._address));
    expect(nftxBal1.sub(nftxBal2).toString()).to.equal(
      UNIT.mul(10).mul(5).div(2).toString()
    );
    expect(aliceBal2.gt(aliceBal1)).to.equal(true);
    await approveAndRedeemD2(
      nftx,
      xToken,
      aliceBal,
      alice,
      vaultId,
      UNIT.mul(10).mul(5).div(2)
    );
    let nftxBal3 = BigNumber.from(await web3.eth.getBalance(nftx.address));
    let aliceBal3 = BigNumber.from(await web3.eth.getBalance(alice._address));
    expect(nftxBal3.toString()).to.equal(nftxBal1.toString());
    expect(aliceBal3.lt(aliceBal2)).to.equal(true);
    await checkBalancesD2(nftx, asset, xToken, [alice]);

    await nftx.connect(owner).setSupplierBounty(vaultId, 0, 0);
    await cleanupD2(nftx, asset, xToken, signers, vaultId);
  };

  ////////////////
  // isEligible //
  ////////////////

  const runIsEligible = async () => {
    console.log("Testing: isEligible...\n");
    await setup(nftx, asset, signers, eligIds);
    let [aliceNFTs] = await holdingsOf(asset, eligIds, [alice]);
    let nftIds = notEligIds.slice(0, 2);
    await transferNFTs(nftx, asset, nftIds, misc, alice);
    await expectRevert(approveAndMint(nftx, asset, nftIds, alice, vaultId, 0));
    await approveAndMint(nftx, asset, eligIds.slice(0, 2), alice, vaultId, 0);

    await cleanup(nftx, asset, xToken, signers, vaultId, allNftIds);
  };

  ////////////////////
  // isEligibleFlip //
  ////////////////////

  const runIsEligibleFlip = async () => {
    console.log("Testing: isEligibleFlip...\n");
    await setup(nftx, asset, signers, eligIds);
    await nftx.connect(owner).setFlipEligOnRedeem(vaultId, true);
    let [aliceNFTs] = await holdingsOf(asset, eligIds, [alice]);
    let nftIds = aliceNFTs.slice(0, 1);
    await approveAndMint(nftx, asset, nftIds, alice, vaultId, 0);
    await approveAndRedeem(nftx, xToken, nftIds.length, alice, vaultId, 0);
    let [newAliceNFTs] = await holdingsOf(asset, eligIds, [alice]);
    await expect(JSON.stringify(aliceNFTs)).to.equal(
      JSON.stringify(newAliceNFTs)
    );
    await expectRevert(approveAndMint(nftx, asset, nftIds, alice, vaultId, 0));
    await nftx.connect(owner).setFlipEligOnRedeem(vaultId, false);
    await cleanup(nftx, asset, xToken, signers, vaultId, allNftIds);
  };

  /////////////////
  // requestMint //
  /////////////////

  const runRequestMint = async () => {
    console.log("Testing requestMint...\n");
    await setup(nftx, asset, signers, allNftIds);
    let [aliceNFTs] = await holdingsOf(asset, notEligIds, [alice]);
    let nftIds = aliceNFTs.slice(0, 2);
    await expectRevert(approveAndMint(nftx, asset, nftIds, alice, vaultId, 0));
    await approveEach(asset, nftIds, alice, nftx.address);
    await nftx.connect(alice).requestMint(vaultId, nftIds);
    await nftx.connect(alice).revokeMintRequests(vaultId, nftIds);
    await expectRevert(nftx.connect(owner).approveMintRequest(vaultId, nftIds));
    let [newAliceNFTs] = await holdingsOf(asset, notEligIds, [alice]);
    await expect(JSON.stringify(aliceNFTs)).to.equal(
      JSON.stringify(newAliceNFTs)
    );
    await approveEach(asset, nftIds, alice, nftx.address);
    await nftx.connect(alice).requestMint(vaultId, nftIds);
    await expectRevert(nftx.connect(alice).approveMintRequest(vaultId, nftIds));
    await nftx.connect(owner).approveMintRequest(vaultId, nftIds);
    await expectRevert(nftx.connect(alice).revokeMintRequests(vaultId, nftIds));
    await approveAndRedeem(nftx, xToken, nftIds.length, alice, vaultId, 0);
    await approveAndMint(nftx, asset, nftIds, alice, vaultId, 0);
    await approveAndRedeem(nftx, xToken, nftIds.length, alice, vaultId, 0);
    await cleanup(nftx, asset, xToken, signers, vaultId, allNftIds);
  };

  //////////////////////////
  // Run Feature Tests... //
  //////////////////////////

  if (isD2) {
    await runMintRedeemD2();
    await runMintFeesBurnFeesD2();
    await runSupplierBountyD2();
  } else {
    await runMintRedeem();
    // await runMintAndRedeem();
    await runMintFeesBurnFees();
    // await runDualFees();
    await runSupplierBounty();
    eligIds[1] - eligIds[0] > 1 && (await runIsEligible());
    eligIds[1] - eligIds[0] > 1 && (await runIsEligibleFlip());
    eligIds[1] - eligIds[0] > 1 && (await runRequestMint());
  }

  console.log("\n-- Vault tests complete --\n\n");
};

exports.runVaultTests = runVaultTests;
