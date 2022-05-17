/***
 *  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
 *   ░░███████╗░██████╗░░░█████╗░░███████╗░░█████╗░░░░██╗░██████╗░░░█████╗░░░
 *   ░░██╔════╝░██╔══██╗░██╔══██╗░░╚══██╔╝░██╔══██╗░████║░██╔══██╗░██╔══██╗░░
 *   ░░██████╗░░██████╔╝░██║░░╚═╝░░░░██╔╝░░╚═╝███╔╝░░░██║░██████╔╝░███████║░░
 *   ░░██╔═══╝░░██╔══██╗░██║░░██╗░░░██╔╝░░░░███╔═╝░░░░██║░██╔══██╗░██╔══██║░░
 *   ░░███████╗░██║░░██║░╚█████╔╝░░░██║░░░░███████╗░░░██║░██║░░██║░██║░░██║░░
 *   ░░╚══════╝░╚═╝░░╚═╝░░╚════╝░░░░╚═╝░░░░╚══════╝░░░╚═╝░╚═╝░░╚═╝░╚═╝░░╚═╝░░
 *  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
 *
 * SPDX-License-Identifier: MIT
 * Creator: Rari Labs  
 * Author: Will Qian
 * Version: ERC721RA Smart Contracts v1.0
 *
 * Website: erc721ra.org
 * Twitter: twitter.com/ERC721RA
 * Github: github.com/ERC721RA
 *
 * ERC721RA is an improved implementation of ERC721A with refundability and gas optimization. 
 * The goal is to give NFT owners freedom to return the NFTs and get refund, 
 * and improve the credibility of the NFT creator.
 * 
 */
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error ApprovalCallerNotOwnerNorApproved();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error MintZeroAmount();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error QueryForTokenNotExist();
error RefundIsNotActive();
error RefundTokenHasBeenBurned();
error RefundCallerNotOwner();
error RefundHasAlreadyBeenMade();
error RefundNotSucceed();
error RefundZeroAmount();
error WithdrawWhenRefundIsActive();
error WithdrawNotSucceed();
error WithdrawZeroBalance();
error TransactToZeroAddress();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**32 - 1 (max value of uint32 4,294,967,296) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**32 - 1 (max value of uint32 4,294,967,296).
 */
contract ERC721RA is Context, ERC165, IERC721, IERC721Metadata, Ownable {
    using Address for address;
    using Strings for uint256;

    // Token data to track token 
    struct TokenData {
        // The address of the owner.
        address ownerAddress;
        // Keeps track of the start time of tokenData with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Track refund information of each token. Token can be returned even they're not owned by minter.
        // Only allowed to refund once, Keeps track of the price paid by minter, price in Wei
        uint256 pricePaid;
        // Whether the token has been burned.
        bool burned;
        // Whether token has been refunded
        bool refunded;
    }

    // Owner data to track against token balance
    struct OwnerData {
        // Token balance
        uint32 balance;
        // Number of tokens minted
        uint32 numberMinted;
        // Number of tokens burned
        uint32 numberBurned;
        // Number of tokens refunded
        uint32 numberRefunded;
    }

    // The tokenId of the next token to be minted.
    uint32 internal _currentIndex;

    // The number of tokens burned.
    uint32 internal _burnCounter;

    // The number of tokens refunded.
    uint32 internal _refundCounter;

    // The refund end timestamp
    uint64 private _refundEndTime;

    // The return address to transfer token to
    address private _returnAddress;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to tokenData details
    // An empty struct value does not necessarily mean the token is unowned. See _ownerOf implementation for details.
    mapping(uint256 => TokenData) internal _tokenData;

    // Mapping owner address to address data
    mapping(address => OwnerData) private _ownerData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_, uint256 refundEndTime_) {
        _name = name_;
        _symbol = symbol_;

        _refundEndTime = uint64(refundEndTime_);
        _returnAddress = _msgSender();

        _currentIndex = _startTokenId();
    }

    /**
     * @dev To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint32) {
        return 0;
    }

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256) {
        // ====== Removed original unchecked clause below, to prevent over/underflow ====== //
        return _currentIndex - _burnCounter - _startTokenId();
        // ====== Removed original unchecked clause above, to prevent over/underflow ====== //
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint32) {
        // ====== Removed original unchecked clause below, to prevent over/underflow ====== //
        return _currentIndex - _startTokenId();
        // ====== Removed original unchecked clause above, to prevent over/underflow ====== //
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) external view override returns (uint256) {
        return _ownerData[owner].balance;
    }

    /**
     * @dev Checks whether a token has been burned
     */
    function _tokenBurned(uint256 tokenId) internal view returns (bool) {
        return _tokenData[tokenId].burned;
    }

    /**
     * @dev Checks whether a token has been refunded
     */
    function _tokenRefunded(uint256 tokenId) internal view returns (bool) {
        return _tokenData[tokenId].refunded;
    }

    /**
     * @dev Returns the price paid by minter
     */
    function _pricePaid(uint256 tokenId) internal view returns (uint256) {
        return _tokenData[tokenId].pricePaid;
    }

    /**
     * @dev Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint32) {
        return _ownerData[owner].numberMinted;
    }

    /**
     * @dev Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint32) {
        return _ownerData[owner].numberBurned;
    }

    /**
     * @dev Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _numberRefunded(address owner) internal view returns (uint32) {
        return _ownerData[owner].numberRefunded;
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownerOf(uint256 tokenId) internal view returns (TokenData memory) {
        uint32 curr = uint32(tokenId);

        // ====== Removed original unchecked clause below, to prevent over/underflow ====== //
        if (_startTokenId() <= curr && curr < _currentIndex) {
            TokenData memory tokenData = _tokenData[curr];
            if (!tokenData.burned) {
                if (tokenData.ownerAddress != address(0)) {
                    return tokenData;
                }
                
                while (true) {
                    curr--;
                    tokenData = _tokenData[curr];
                    if (tokenData.ownerAddress != address(0)) {
                        return tokenData;
                    }
                }
            }
        }
        // ====== Removed original unchecked clause above, to prevent over/underflow ====== //

        revert QueryForTokenNotExist();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownerOf(tokenId).ownerAddress;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert QueryForTokenNotExist();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) external override {
        address owner = ERC721RA.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert QueryForTokenNotExist();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        _transfer(from, to, tokenId);
        if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex && !_tokenData[tokenId].burned;
    }

    /**
     * Equivalent to `_safeMint(to, amount, '')`.
     */
    function _safeMint(address to, uint256 amount) internal {
        _safeMint(to, uint32(amount), "");
    }

    /**
     * @dev Safely mints `amount` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement 
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `amount` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint32 amount, bytes memory _data) internal {
        uint32 startTokenId = _currentIndex;
        if (to == address(0)) revert TransactToZeroAddress();
        if (amount == 0) revert MintZeroAmount();

        _beforeTokenTransfers(address(0), to, startTokenId, amount);

        // ====== Removed original unchecked clause below, to prevent over/underflow ====== //
        _ownerData[to].balance += amount;
        _ownerData[to].numberMinted += amount;

        uint32 updatedIndex = startTokenId;
        uint32 end = updatedIndex + amount;

        if (to.isContract()) {
            do {
                _tokenData[updatedIndex].ownerAddress = to;
                _tokenData[updatedIndex].startTimestamp = uint64(block.timestamp);
                _tokenData[updatedIndex].pricePaid = msg.value / amount;

                emit Transfer(address(0), to, updatedIndex);
                if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                    revert TransferToNonERC721ReceiverImplementer();
                }
            } while (updatedIndex != end);
            // Reentrancy protection
            if (_currentIndex != startTokenId) revert();
        } else {
            do {
                _tokenData[updatedIndex].ownerAddress = to;
                _tokenData[updatedIndex].startTimestamp = uint64(block.timestamp);
                _tokenData[updatedIndex].pricePaid = msg.value / amount;

                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex != end);
        }
        _currentIndex = updatedIndex;
        // ====== Removed original unchecked clause above, to prevent over/underflow ====== //

        _afterTokenTransfers(address(0), to, startTokenId, amount);
    }

    /**
     * @dev Mints `amount` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `amount` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint32 amount) internal {
        uint32 startTokenId = _currentIndex;
        if (to == address(0)) revert TransactToZeroAddress();
        if (amount == 0) revert MintZeroAmount();

        _beforeTokenTransfers(address(0), to, startTokenId, amount);

        // ====== Removed original unchecked clause below, to prevent over/underflow ====== //
        _ownerData[to].balance += amount;
        _ownerData[to].numberMinted += amount;

        uint32 updatedIndex = startTokenId;
        uint32 end = updatedIndex + amount;

        do {
            _tokenData[updatedIndex].ownerAddress = to;
            _tokenData[updatedIndex].startTimestamp = uint64(block.timestamp);
            _tokenData[updatedIndex].pricePaid = msg.value / amount;

            emit Transfer(address(0), to, updatedIndex++);
        } while (updatedIndex != end);

        _currentIndex = updatedIndex;
        // ====== Removed original unchecked clause above, to prevent over/underflow ====== //

        _afterTokenTransfers(address(0), to, startTokenId, amount);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) private {
        TokenData memory prevTokenData = _ownerOf(tokenId);

        if (prevTokenData.ownerAddress != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransactToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        _ownerData[from].balance -= 1;
        _ownerData[to].balance += 1;

        TokenData storage currSlot = _tokenData[tokenId];
        currSlot.ownerAddress = to;
        currSlot.startTimestamp = uint64(block.timestamp);

        // If the tokenData slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
        // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
        uint256 nextTokenId = tokenId + 1;
        TokenData storage nextSlot = _tokenData[nextTokenId];
        if (nextSlot.ownerAddress == address(0)) {
            // This will suffice for checking _exists(nextTokenId),
            // as a burned slot cannot contain the zero address.
            if (nextTokenId != _currentIndex) {
                nextSlot.ownerAddress = from;
                nextSlot.startTimestamp = prevTokenData.startTimestamp;
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        TokenData memory prevTokenData = _ownerOf(tokenId);

        address from = prevTokenData.ownerAddress;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
                isApprovedForAll(from, _msgSender()) ||
                getApproved(tokenId) == _msgSender());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // ====== Removed original unchecked clause below, to prevent over/underflow ====== //
        OwnerData storage ownerData = _ownerData[from];
        ownerData.balance -= 1;
        ownerData.numberBurned += 1;

        // Keep track of who burned the token, and the timestamp of burning.
        TokenData storage currSlot = _tokenData[tokenId];
        currSlot.ownerAddress = from;
        currSlot.startTimestamp = uint64(block.timestamp);
        currSlot.burned = true;

        // If the tokenData slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
        // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
        uint256 nextTokenId = tokenId + 1;
        TokenData storage nextSlot = _tokenData[nextTokenId];
        if (nextSlot.ownerAddress == address(0)) {
            // This will suffice for checking _exists(nextTokenId),
            // as a burned slot cannot contain the zero address.
            if (nextTokenId != _currentIndex) {
                nextSlot.ownerAddress = from;
                nextSlot.startTimestamp = prevTokenData.startTimestamp;
            }
        }
        // ====== Removed original unchecked clause above, to prevent over/underflow ====== //

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // ====== Removed original unchecked clause below, to prevent over/underflow ====== //
        _burnCounter++;
        // ====== Removed original unchecked clause above, to prevent over/underflow ====== //
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * emit a {Approval} event.
     */
    function _approve(address to, uint256 tokenId, address owner) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * amount - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * amount - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 amount) internal virtual {}

    /**
     * @dev Set the return address
     */
    function setReturnAddress(address to) external onlyOwner {
        _returnAddress = to;
    }

    /**
     * @dev Get the return address 
     */
    function returnAddress() external view returns (address) {
        return _returnAddress;
    }

    /**
     * @dev Get the refund end time
     */
    function refundEndTime() external view returns (uint256) {
        return _refundEndTime;
    }

    /**
     * @dev Check if refund has not ended
     */
    function isRefundActive() public view returns (bool) {
        return _refundEndTime > uint64(block.timestamp);
    }

    /**
     * @dev Refund the current owner of the token
     */
    function _refund(address to, uint256 tokenId) internal {
        if (!isRefundActive()) revert RefundIsNotActive();
        if (to == address(0)) revert TransactToZeroAddress();

        if (_msgSender() != ownerOf(tokenId)) revert RefundCallerNotOwner();
        if (_tokenData[tokenId].burned) revert RefundTokenHasBeenBurned();
        if (_tokenData[tokenId].refunded) revert RefundHasAlreadyBeenMade();

        uint256 refundAmount = _tokenData[tokenId].pricePaid;
        if (refundAmount == 0) revert RefundZeroAmount();

        _beforeTokenTransfers(_msgSender(), _returnAddress, tokenId, 1);

        // ====== Removed original unchecked clause below, to prevent over/underflow ====== //
        _tokenData[tokenId].refunded = true;
        _ownerData[ownerOf(tokenId)].numberRefunded += 1;
        _refundCounter++;
        // ====== Removed original unchecked clause above, to prevent over/underflow ====== //

        safeTransferFrom(_msgSender(), _returnAddress, tokenId);

        (bool success, ) = to.call{ value: refundAmount }("");
        if (!success) revert RefundNotSucceed();

        emit Transfer(_msgSender(), _returnAddress, tokenId);
        _afterTokenTransfers(_msgSender(), _returnAddress, tokenId, 1);
    }


    /**
     * @dev Can only withdraw after when the refund is inactive
     */
    function _withdraw(address to) internal onlyOwner {
        if (isRefundActive()) revert WithdrawWhenRefundIsActive();
        if (to == address(0)) revert TransactToZeroAddress();

        uint256 contractBalance = address(this).balance;
        if (contractBalance == 0) revert WithdrawZeroBalance();

        (bool success, ) = to.call{ value: contractBalance }("");

        if (!success) revert WithdrawNotSucceed();
    }

}