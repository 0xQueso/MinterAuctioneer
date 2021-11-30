const { expect } = require("chai");
const { ethers, waffle, network} = require("hardhat");
const {makeForkClient} = require("hardhat/internal/hardhat-network/provider/utils/makeForkClient");
const MinterArtifact = require("../artifacts/contracts/Minter.sol/Minter.json");
const {BigNumber} = require("ethers");

const { provider, deployContract } = waffle;

describe("Minter", function () {
  let minter;
  let nftContract;
  let admin;
  let addr1;
  let addr2;
  let addr3;
  let addr4;
  let addr5;
  let addr6;
  let addr7;

  const oneDay = 86400;

  before(async function () {
      [admin, addr1, addr2, addr3, addr4, addr5, addr6, addr7] = await hre.ethers.getSigners();
      const NFTContract = await ethers.getContractFactory("Meaningless");
      nftContract = await NFTContract.deploy();
      await nftContract.deployed();
      minter = (await deployContract(admin, MinterArtifact, [nftContract.address]));

      nftContract.connect(addr1).setApprovalForAll(minter.address, true);
      nftContract.connect(addr2).setApprovalForAll(minter.address, true);
  });

  it("Admin should mint 1m token", async function () {
    await minter.mint(admin.address, 1000000);
    expect(await minter.balanceOf(admin.address)).to.equal(1000000);
  });

  it("Admin should burn 100 token", async function () {
    await minter.burn(admin.address, 100);
    expect(await minter.balanceOf(admin.address)).to.equal(999900);
  });

  it("Admin should be able to buy back 100 token", async function () {
    await minter.mint(admin.address, 100);
    expect(await minter.balanceOf(admin.address)).to.equal(1000000);
  });

  it("Other users should not be able to mint or burn token", async function () {
     await expect(minter.connect(addr2).mint(addr2.address, 100)).to.be.revertedWith("Caller is not an Admin");
     await expect(minter.connect(addr2).burn(addr2.address, 100)).to.be.revertedWith("Caller is not an Admin");
  });

  it("Test distribute funds to other users", async function () {
    await minter.mint(addr1.address, 1000);
    await minter.mint(addr2.address, 2000);
    await minter.mint(addr3.address, 3000);
    await minter.mint(addr5.address, 5000);
    await minter.mint(addr6.address, 6000);

    expect(await minter.balanceOf(addr1.address)).to.equal(1000);
  });

  it("Users can transfer tokens to other users", async function () {
    await minter.connect(addr6).transfer(addr7.address, 1000);

    expect(await minter.balanceOf(addr7.address)).to.equal(1000);
  });


  describe("NFT Interaction", function () {
      it("Should have access to NFT contract", async function () {
          const nftBal = await minter.connect(addr2).nftBalance(addr2.address);
          expect(nftBal).to.equal(0);
      });

      it("User1 and User2 should be able to mint nft from NFTContract", async function () {
          await minter.connect(addr1).mintNFT();
          await minter.connect(addr2).mintNFT();
      });

      it("User1 and User2 should both have 1 nft", async function () {
          expect(await minter.connect(addr1).nftBalance(addr1.address)).to.equal(1);
          expect(await minter.connect(addr2).nftBalance(addr2.address)).to.equal(1);
      });
  });

  describe("Auction", function () {
      it("User1 should be able to start non-blind auction valid for 24hours for NFT minted", async function () {
          await expect(minter.connect(addr1).startAuction(oneDay, false, 0))
              .to.emit(minter, 'AuctionStarted')
              .withArgs(addr1.address, oneDay, false, 0);
      });

      it("User2 should be able to bid 500 on auction of User1", async function (){
          await minter.connect(addr2).bid(500,0);
      })

      it("User3 should be able to bid 550 on auction of User1", async function (){
          await minter.connect(addr3).bid(550,0);
      })

      it("User4 should not be able to bid 600 in an auction due to no balance", async function (){
          await expect(
              minter.connect(addr4).bid(600,0)
          ).to.be.revertedWith("Not enough token to bid.");
      })

      it("User2 cannot bid less than the highest current bid which is 550", async function (){
          await expect(
              minter.connect(addr2).bid(300,0)
          ).to.be.revertedWith("Bid is lower than highest bid.");
      })


      it("Auction by User1 Should have 2 bids from token nft id 0", async function (){
          const bids = await minter.nftBids(0);
          expect(bids).to.have.lengthOf(2);
      })

      it("Auction should end after one day, Not allowing any more bids", async function (){
          const blockTimestamp = await (await provider.getBlock(await provider.getBlockNumber())).timestamp;
          await network.provider.send("evm_increaseTime", [oneDay]);
          await network.provider.send("evm_mine");
          await expect(
              minter.connect(addr2).bid(650,0)
          ).to.be.revertedWith("Auction has ended.");
      })

      it("Claiming NFT for non-winner/non-bidder should not proceed", async function (){
          await expect(
              minter.connect(addr4).claimAsset(0)
          ).to.be.revertedWith("You are not the winner.");
      })

      it("Winner(user3) should receive the NFT and transfer the fund", async function (){
          await minter.connect(addr3).claimAsset(0);
          expect(await minter.nftBalance(addr1.address)).to.equal(0);
          expect(await minter.nftBalance(addr3.address)).to.equal(1);
      })

      it("Winner(user3) should have funds of 2450 and Auctioneer(user1) should have funds of 1550", async function (){
          const bal3 = await minter.balanceOf(addr3.address);
          const bal4 = await minter.balanceOf(addr1.address);
          expect(bal3, bal4).to.equal(2450, 1550);
      })
  })
    describe("Blinded Auction", function () {
        it("User2 should be able to start BLIND auction valid for 24hours for NFT minted", async function () {
            await expect(minter.connect(addr2).startAuction(oneDay, true, 1))
                .to.emit(minter, 'AuctionStarted')
                .withArgs(addr2.address, oneDay, true, 1);
        });

        it("User3 should be able to bid 200 on auction of User2", async function (){
            await minter.connect(addr3).bid(200,1);
        });

        it("User1 should be able to bid 100 on auction of User2", async function (){
            await minter.connect(addr1).bid(100,1);
        });

        it("User5 should be able to bid 3000 on auction of User2", async function (){
            await minter.connect(addr5).bid(3000,1);
        });

        it("Current highestBid(User5): Claiming asset while the Auction is still on going should NOT proceed", async function (){
            await expect(
                minter.connect(addr5).claimAsset(1)
            ).to.be.revertedWith("Auction is still active.");
        })

        it("Current highestBid(User5): Claiming asset after auction has ended should proceed", async function (){
            await network.provider.send("evm_increaseTime", [oneDay]);
            await network.provider.send("evm_mine");

            await minter.connect(addr5).claimAsset(1);
            expect(await minter.nftBalance(addr2.address)).to.equal(0);
            expect(await minter.nftBalance(addr5.address)).to.equal(1);
        })

        it("Winner(user5) should have funds of 2000 and Auctioneer(user2) should have funds of 5000", async function (){
            const bal2 = await minter.balanceOf(addr2.address);
            const bal5 = await minter.balanceOf(addr5.address);
            expect(bal2, bal5).to.equal(5000, 3000);
        })

        it("Mint another NFT and Get nfts owned by User5", async function (){
            await minter.connect(addr5).mintNFT();
            const nfts = await minter.getOwnerNFTS(addr5.address);
            expect(nfts[0].toNumber(), nfts[1].toNumber()).to.equal(1,2);
        })
    });
});
