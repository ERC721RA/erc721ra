/***
 * SPDX-License-Identifier: MIT
 * Creator: Rari Labs
 * Author: Will Qian
 */
pragma solidity ^0.8.7;

import "./ERC721RA.sol";

contract ERC721RA_NFT is ERC721RA {
    constructor(uint256 refundEndTime_) ERC721RA("ERC721RA_NFT", "RANFT", refundEndTime_) {}

    function mint(uint256 amount) external payable {
        _safeMint(_msgSender(), amount);
    }

    /*** For the ease of Gas Saving Test ***/
    function mint1x() external payable {
        _safeMint(_msgSender(), 1);
    }

    function mint2x() external payable {
        _safeMint(_msgSender(), 2);
    }

    function mint3x() external payable {
        _safeMint(_msgSender(), 3);
    }

    function mint4x() external payable {
        _safeMint(_msgSender(), 4);
    }

    function mint5x() external payable {
        _safeMint(_msgSender(), 5);
    }

    function mint6x() external payable {
        _safeMint(_msgSender(), 6);
    }

    function mint7x() external payable {
        _safeMint(_msgSender(), 7);
    }

    function mint8x() external payable {
        _safeMint(_msgSender(), 8);
    }

    function mint9x() external payable {
        _safeMint(_msgSender(), 9);
    }

    function mint10x() external payable {
        _safeMint(_msgSender(), 10);
    }

    /*** For ease of Gas Saving Test ***/

    function refund(uint256 tokenId) external {
        _refund(_msgSender(), tokenId);
    }

    function withdraw() external onlyOwner {
        _withdraw(_msgSender());
    }

    function tokenRefunded(uint256 tokenId) external view returns (bool) {
        return _tokenRefunded(tokenId);
    }

    function numberRefunded(address owner) external view returns (uint256) {
        return _numberRefunded(owner);
    }
}
