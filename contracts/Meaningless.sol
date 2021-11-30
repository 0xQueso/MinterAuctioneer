// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
import "./libraries/Base64.sol";

contract Meaningless is ERC721URIStorage, Ownable  {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    event JustMinted(address sender, uint256 tokenId);

    string baseSvg = '<svg preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg"><style>.base { fill: white; font-family: serif; font-size: 24px; }</style><defs><linearGradient id="a" x1="50%" x2="50%" y2="100%"><stop stop-color="#7A5FFF" offset="0"><animate attributeName="stop-color" dur="4s" repeatCount="indefinite" values="#7A5FFF; #01FF89; #7A5FFF"/></stop><stop stop-color="#red" offset="1"><animate attributeName="stop-color" dur="4s" repeatCount="indefinite" values="#01FF89; #7A5FFF; #01FF89"/></stop></linearGradient></defs><rect width="100%" height="100%" fill="url(#a)"/><text class="base" x="50%" y="50%" dominant-baseline="middle" text-anchor="middle">';
    string[] firstWords = ["Dare", "Right", "Food", "Stop", "Out", "lunatic"];
    string[] secondWords = ["Music", "Fatuous", "Wacky", "Silly", "Blanket", "Cookie"];
    string[] thirdWords = ["Reason", "Pillow", "Work", "Leave", "Water", "Chamber"];
    uint256 totalSupply = 300;
    uint256[] tokenIds;

    constructor() ERC721 ("Meaningless", "MNLS") { }

    function mintAnNFT(address owner) external {
        require(_tokenIds.current() <= totalSupply, 'reached total supply');
        uint256 newItemId = _tokenIds.current();
        tokenIds.push(newItemId);
        string memory first = pickRandomFirstWord(newItemId);
        string memory second = pickRandomSecondWord(newItemId);
        string memory third = pickRandomThirdWord(newItemId);

        string memory combinedWord = string(abi.encodePacked(first, second, third));
        string memory finalSvg = string(abi.encodePacked(baseSvg, combinedWord, "</text></svg>"));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        combinedWord,
                        '", "description": "3D scary thoughts.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(finalSvg)),
                        '"}'
                    )
                )
            )
        );

        string memory finalTokenUri = string(abi.encodePacked("data:application/json;base64,", json));
        _safeMint(owner, newItemId);
        _setTokenURI(newItemId,finalTokenUri);
        _tokenIds.increment();

        emit JustMinted(owner, newItemId);

        console.log("An NFT w/ ID %s has been minted to %s", newItemId, owner);
    }

    function pickRandomFirstWord(uint256 tokenId) public view returns (string memory) {
        string memory test = string(abi.encodePacked("FIRST_WORD", Strings.toString(tokenId)));
        uint256 rand = random(string(abi.encodePacked("FIRST_WORD", Strings.toString(tokenId))));
        rand = rand % firstWords.length;
        return firstWords[rand];
    }

    function pickRandomSecondWord(uint256 tokenId) public view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked("SECOND_WORD", Strings.toString(tokenId))));
        rand = rand % secondWords.length;
        return secondWords[rand];
    }

    function getMintedNft() public view returns(uint256) {
        return uint256(_tokenIds.current());
    }

    function getTotalSupply() public view returns(uint256) {
        return uint256(totalSupply);
    }

    function pickRandomThirdWord(uint256 tokenId) public view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked("THIRD_WORD", Strings.toString(tokenId))));
        rand = rand % thirdWords.length;
        return thirdWords[rand];
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function tokenIdsOfOwner(address _owner) external view returns (uint256[] memory tokenIds_) {
        uint256 len = _tokenIds.current();
        tokenIds_ = new uint256[](len);
        uint256 count;
        for (uint256 i; i < len; ) {
            uint256 tokenId = tokenIds[i];
            if (ownerOf(i) == _owner) {
                tokenIds_[count] = tokenId;
            unchecked {
                count++;
            }
            }
        unchecked {
            i++;
        }
        }
        assembly {
            mstore(tokenIds_, count)
        }
    }

}