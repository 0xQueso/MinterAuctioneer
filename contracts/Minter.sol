//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "hardhat/console.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IMeaningless.sol";

contract Minter is ERC20, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMINISTRATOR");
    bytes32 public constant DEV_ROLE = keccak256("DEV_ROLE");
    address private meaninglessAddress;

    struct Bid {
        uint256 bidAmount;
        address bidder;
    }

    struct Auction {
        address auctioneer;
        uint256 biddingEnd;
        bool isBlinded;
        bool ended;
        address highestBidder;
        uint256 highestBid;
    }

    struct PendingTransfer {
        address winner;
        uint256 nftId;
        uint256 bid;
    }

    mapping(uint256 => Bid[]) public bids;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => PendingTransfer) public pendingTransfers;

    event Claimed(address winner, uint256 highestBid, uint256 nftId);
    event AuctionStarted(address auctioneer, uint256 biddingEnd, bool isBlinded, uint256 nftId);

    modifier onlyAdmin() { require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an Admin"); _; }

    constructor(address mAddress) public ERC20("Token", "TKN") {
        meaninglessAddress = mAddress;
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    function startAuction (
        uint256 _biddingTime,
        bool isBlinded,
        uint256 nftId
    ) public {
        require(IMeaningless(meaninglessAddress).ownerOf(nftId) == msg.sender, 'Not the owner');

        auctions[nftId] = Auction({
            auctioneer: msg.sender,
            biddingEnd: block.timestamp + _biddingTime,
            ended: false,
            highestBidder: address(0),
            highestBid: 0,
            isBlinded: isBlinded
        });

        emit AuctionStarted(msg.sender, _biddingTime, isBlinded, nftId);
    }

    function bid (
        uint256 _bid,
        uint256 nftId
    ) public {
        Auction storage auction = auctions[nftId];
        require(_bid <= balanceOf(msg.sender), 'Not enough token to bid.');
        require(block.timestamp <= auction.biddingEnd, 'Auction has ended.');

        if (!auction.isBlinded) {
            require(_bid > auction.highestBid, 'Bid is lower than highest bid.');

            auction.highestBid = _bid;
            auction.highestBidder = msg.sender;

            pendingTransfers[nftId] = PendingTransfer({
                winner: msg.sender,
                nftId: nftId,
                bid: _bid
            });
        }

        if (auction.isBlinded && auction.highestBid < _bid) {
            auction.highestBid = _bid;
            auction.highestBidder = msg.sender;

            pendingTransfers[nftId] = PendingTransfer({
                winner: msg.sender,
                nftId: nftId,
                bid: _bid
            });
        }

        bids[nftId].push(Bid({
            bidAmount: _bid,
            bidder: msg.sender
        }));
    }

    function claimAsset(uint256 tokenId) public {
        Auction memory auction = auctions[tokenId];

        if (block.timestamp >= auction.biddingEnd) {
            auction.ended = true;
        }

        require(auction.ended, 'Auction is still active.');
        require(pendingTransfers[tokenId].winner == msg.sender, 'You are not the winner.');

        transfer(auction.auctioneer, auction.highestBid);
        IMeaningless(meaninglessAddress).safeTransferFrom(auction.auctioneer, auction.highestBidder, tokenId);
        delete pendingTransfers[tokenId];
        delete bids[tokenId];
        emit Claimed(auction.highestBidder, auction.highestBid, tokenId);
    }

    function mint(address to, uint256 amount) public onlyAdmin {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyAdmin {
        _burn(from, amount);
    }

    function mintNFT() public {
        IMeaningless(meaninglessAddress).mintAnNFT(msg.sender);
    }

    function nftBalance(address owner) public view returns (uint256 balance){
        balance = IMeaningless(meaninglessAddress).balanceOf(owner);
    }

    function nftBids(uint256 tokenId) public view returns (Bid[] memory _bids) {
        _bids = bids[tokenId];
    }

    function getOwnerNFTS(address owner) public view returns (uint256[] memory ids) {
        ids = IMeaningless(meaninglessAddress).tokenIdsOfOwner(owner);
    }
}