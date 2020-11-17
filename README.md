# General Overview

NFTX is a project for making ERC20 tokens that are backed by NFTs. For example, there will be a PUNK-ZOMBIE token which is backed by zombie cryptopunks. Anyone can mint PUNK-ZOMBIE by transfering a zombie cryptopunk, and anyone can redeem a random zombie cryptopunk by transfering 1 PUNK-ZOMBIE. The name I use for these ERC20 tokens on NFTX are "XTokens".

Anyone can create their own XToken and link it to a set of NFTs by calling the createVault(...) method on the NFTX contract. Every vault keeps track of the number of NFTs which it stores, as well as other settings like fees and a list of which NFTs are elgible. When a vault is created, the account which sends the transaction is designated as the "manager and that allows them to make adjustments. When they are done making adjustments, the manager can call finalizeVault(...) which revokes their manager permissions and hands control of the vault over to the owner the NFTX contract (which will be the NFTX Dao).

It is also possible for a manager to transfer their manager permissions. So, they could, in theory, transfer their permissions to another smart contract instead of "finalizing" and by doing that they could make a "smart vault" which is neither controlled by the NFTX Dao or themselves. This is analagous to how its possible to create a "smart pool" on Balancer by transfering ownership to another contract instead of finalizing. 

The NFTX contract will use an upgradeability proxy. NFTX.sol is the main logic contract, however I moved the state into another contract called XStore.sol (which is not upgradeable). All of the methods in the XStore contract are either "public view" or "public onlyOwner". 

Every vault has a mapping called isEligible and a bool called negateEligibility. When negateEligibility is set to false, then the isEligible mapping acts as an allowlist. Alternatively when negateEligibility is set to true, then it acts as a denylist. By default it is set true and the mapping is empty, meaning that all tokenIDs are elgible (as long as they belong to whichever NFT contract the vault is linked to).

There are two types of vaults which are possible. The default type is what we have been discussing thus far and is called D1 (for degree one). The other type of vault is D2 (for degree two). Instead of holding ERC721s, D2 vaults are each meant to store an ERC20. The reason for D2 vaults is so that we can make second degree Xtokens that combine D1 Xtokens while still having a similar feature set (like fees). To begin with, NFTX will have four D1 cryptopunk vaults:

 - PUNK-BASIC (all cryptopunks)
 - PUNK-ATTR-4 (cryptopunks w/ 4 attributes)
 - PUNK-ATTR-5 (cryptopunks w/ 5 attributes)
 - PUNK-ZOMBIE (zombie cryptopunks)

Then, these four Xtokens will be used to create a 25/25/25/25 Balancer pool which combines them into a single Balancer-Pool-Token (let's call it PUNK-BPT). At this point, people could just use PUNK-BPT, but I decided to make D2 vaults so that PUNK-BPT can be wrapped to create PUNK. This way it is possible to use the other features I previously alluded to (such as burnFees) with D2 Xtokens as well. 

So the PUNK token is a (D2) XToken which wraps the PUNK-BPT token via a (D2) vault on NFTX. If you deposit PUNK into the vault then you can redeem PUNK-BPT which can then be used to redeem each of PUNK-BASIC, ..., PUNK-ZOMBIE on Balancer, which are themselves (D1) Xtokens that wrap subsets of cryptopunks via (D1) vaults on NFTX. This way, it's possible to get exposure to a diverse portfolio of cryptopunks by simply buying the PUNK token which has efficient price discovery as a result of it being possible for arbitrageurs to mint and burn it in exchange for the underlying asset.

The next part of the system is the XController which is the interface the Dao uses to interact with the NFTX contract. So, technically, the NFTX contract is "owned" by the XController, and the XController is owned by the NFTX Dao (on Aragon). The primary reason for having the XController is so that actions performed by the Dao have a time delay. I do not know if there is an easier way to implement this, but the way I have done it is to enable the owner (or the lead dev) to stage a function call along with the necessary function parameters. Then, after a certain amount of time has passed, it's possible for anyone to execute the staged call. Like the NFTX contract, the XController contract also uses an upgradeability proxy, however unlike the NFTX contract, the XController does not have a seperate store contract for its state.

Keep in mind that upgradeable contracts designate a "proxy admin" which may be different from the contract "owner". In our case the proxy admin for both the NFTX contract and the XController will be a seperate contract which I call UpgradeController. The reason for having an UpgradeController is so that any upgrades to the NFTX contract or the XController contract can have a time delay as well. In both cases, the time delay is to protect users from governance attacks and increase the trustlessness of the XTokens for holders. 

So to recap:

- NFTX Dao (on Aragon) is owner of UpgradeController and XController
- UpgradeController is the proxy admin for XController and NFTX
- XController is the owner of NFTX
- NFTX is the owner of XStore
- NFTX is the owner of all XTokens

The two primary functions for interacting with a vault are mint(...) and redeem(...). There is also a third function mintAndRedeem(...) which combines these two actions and can be used to swap NFTs for random NFTs from a D1 vault. It's crucial that all vaults always maintain 1:1 ratio between the XToken and the asset at all times. For D2 vaults, this means that for every 10^18 of an ERC20 there is also 10^18 of the XToken. For D1 vaults, this means that for every 1 NFT there is 10^18 of the XToken. 

When an NFT is deposited into a vault, that vault adds the NFT's tokenID to its list of "holdings". It is possible for a vault to also "reserve" NFTs after they have been deposited. Reserving an NFT essentially puts it at the bottom of the deck, so to speak. So there are two lists of NFTs that a vault has ownership of, (1) holdings and (2) reserves. When a user transfers an XToken to redeems an NFT, the NFTX contract first checks if there are any NFTs on the "holdings" list, and if there are then it selects a random one. If there are no NFTs left on the holdings list (when a redemption happens) then an NFT is randomly selected fromt the reserves list instead. It is possible for a manager to move items from one list to the other and it's also possible for a manager to set which NFTs should be reserved ahead of time by setting booleans on the "shouldReserve" mapping. 

The reason for the reserve function is so that other services can be built on top of NFTX in the future which allow users to purchase NFT giftcards that the recipient can use to select an NFT of their choosing. With this service in mind, it is better for vaults to have a diverse selection of similarly priced NFTs (e.g. cryptopunks that have different attributes and skin colors despite having similar value). By reserving one of each type of item, it then makes it more likely that a vault will maintain a deep reserve of dynamic choices for gift cards. (Note that any giftcards would essentially be XTokens + an added price premium, so that the 1:1 backing is always maintained). (Also note that no giftcard expansion is in development yet——I am simply describing the motive for the reserve functionality). 

There are three types of fees that every vault has, (1) mintFees, (2) burnFees, and (3) dualFees. The last of these, dualFees, is associated with the mintAndBurn operation and is therefor only relevant for D1 vaults. FeeParams is a struct containing two uints. The first of these uinst is the base fee for an operation, and the second uint the the multiplicative fee based on the size of the operation (e.g. 5 PUNK being minted versus 1 PUNK being minted).

Every vault also has a "supplierBounty". The purpose of supplier bounties is to disincentivize burning an XToken when supply is low, and also to incentivize minting it instead. BountyParams is a struct containing two uints: ethMax and length. 

As an example, let's say the supplierBounty for a PUNK-ZOMBIE token is (ethMax: 20, length: 5).

Supply is 6. Alice burns 1. 0 added cost.
Supply is 5. Alice burns 1. 4 ETH added cost.
Supply is 4. Alice burns 1. 8 ETH added cost.
Supply is 3. Bob mints 1. 8 ETH payout to Bob.
Supply is 4. Bob mints 1. 4 ETH payout to Bob.
Supply is 5. Bob mints 1. 0 ETH payout to Bob.

However, minters only receive a payout if the vault's "ethBalance" (stored in the Vault struct) is sufficient to cover it. In other words, the first time that a supply increases from zero to its length there is no payout (assuming no ETH is deposited). 
