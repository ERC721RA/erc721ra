/***
 * SPDX-License-Identifier: MIT
 * Creator: Rari Labs  
 * Author: Will Qian
 */
pragma solidity ^0.8.7;

import "./ERC721RA.sol";

contract ERC721RA_NFT is ERC721RA {
  constructor(uint256 refundEndTime_) 
    ERC721RA("ERC721RA_NFT", "RANFT", refundEndTime_) {}

  function mint(uint256 amount) external payable {
    _safeMint(_msgSender(), amount);
  }

  function refund(uint256 tokenId) external {
      _refund(_msgSender(), tokenId);
  }

  function withdraw() external onlyOwner{
    _withdraw(_msgSender());
  }

  function tokenRefunded(uint256 tokenId) external view returns(bool) {
    return _tokenRefunded(tokenId);
  }

  function pricePaid(uint256 tokenId) external view returns(uint256) {
    return _pricePaid(tokenId);
  }
  
  function numberRefunded(address owner) external view returns(uint256) {
    return _numberRefunded(owner);
  }
}