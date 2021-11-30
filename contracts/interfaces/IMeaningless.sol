// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMeaningless is IERC721 {
    function mintAnNFT(address) external;

    function tokenIdsOfOwner(address _owner) external view returns (uint256[] memory);
}