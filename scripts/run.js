// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const {ethers} = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  const [admin, addr1, addr2, addr3, addr4, addr5] = await hre.ethers.getSigners();

  // We get the contract to deploy
  const NFTContract = await ethers.getContractFactory("Meaningless");
  const nftContract = await NFTContract.deploy();
  await nftContract.deployed();


  const Minter = await hre.ethers.getContractFactory("Minter");
  const minter = await Minter.deploy(nftContract.address);


  await minter.deployed();
  const accounts = await hre.ethers.getSigners();

  await minter.mint(admin.address, 1000000);
  await minter.mint(addr1.address, 1000);
  await minter.mint(addr2.address, 2000);
  await minter.mint(addr3.address, 3000);
  await minter.mint(addr5.address, 5000);

  let a = await minter.balanceOf(accounts[0].address)
    console.log(a.toNumber())

  // let v = await minter.mintNFT(accounts[2].address);
  // v.wait()

  let bal = await minter.nftBalance(accounts[4].address);
  console.log(bal.toNumber());

  // let ids = await minter.getOwnerNFTS(accounts[0].address);
  // console.log(ids)

  console.log("Minter deployed:", minter.address);
  console.log("NFT deployed:", nftContract.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
