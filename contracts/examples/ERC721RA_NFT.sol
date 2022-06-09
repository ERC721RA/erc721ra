/***
 * SPDX-License-Identifier: MIT
 * Creator: Rari Labs
 * Author: WIL ZEE
 */
pragma solidity ^0.8.7;

import "../ERC721RA.sol";
import "hardhat/console.sol";

error PaymentNotEnough();

contract ERC721RA_NFT is ERC721RA {
    uint256 private _mintPrice;
    event RefundMade(address to, uint256 amount);

    constructor(uint256 refundEndTime_, uint256 mintPrice_) ERC721RA("ERC721RA_NFT", "RANFT", refundEndTime_) {
        _mintPrice = mintPrice_;
    }

    function mint(uint256 amount) external payable {
        refundIfOver(_mintPrice * amount);
        _safeMint(_msgSender(), amount, _mintPrice);
    }

    /*** For the ease of Gas Saving Test ***/
    function mint1x() external payable {
        _safeMint(_msgSender(), 1, _mintPrice);
    }

    function mint2x() external payable {
        _safeMint(_msgSender(), 2, _mintPrice);
    }

    function mint3x() external payable {
        _safeMint(_msgSender(), 3, _mintPrice);
    }

    function mint4x() external payable {
        _safeMint(_msgSender(), 4, _mintPrice);
    }

    function mint5x() external payable {
        _safeMint(_msgSender(), 5, _mintPrice);
    }

    function mint6x() external payable {
        _safeMint(_msgSender(), 6, _mintPrice);
    }

    function mint7x() external payable {
        _safeMint(_msgSender(), 7, _mintPrice);
    }

    function mint8x() external payable {
        _safeMint(_msgSender(), 8, _mintPrice);
    }

    function mint9x() external payable {
        _safeMint(_msgSender(), 9, _mintPrice);
    }

    function mint10x() external payable {
        _safeMint(_msgSender(), 10, _mintPrice);
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

    /*
     * Refund to minter
     */
    function refundIfOver(uint256 totalPrice) private {
        if (msg.value < totalPrice) revert PaymentNotEnough();
        if (msg.value > totalPrice) {
            uint256 overPay = msg.value - totalPrice;
            (bool success, ) = _msgSender().call{value: overPay}("");

            if (!success) revert RefundNotSucceed();
            emit RefundMade(_msgSender(), overPay);
        }
    }
}
