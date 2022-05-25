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

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

error ApprovalCallerNotOwnerNorApproved();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error MintZeroAmount();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error RefundNotActive();
error RefundTokenHasBeenBurned();
error RefundCallerNotOwner();
error RefundHasAlreadyBeenMade();
error RefundNotSucceed();
error RefundZeroAmount();
error WithdrawWhenRefundActive();
error WithdrawNotSucceed();
error WithdrawZeroBalance();
error TransactToZeroAddress();
error WithdrawToZeroAddress();
error TransferToZeroAddress();
error MintToZeroAddress();
error ReturnAddressSetToZeroAddress();
error RefundToZeroAddress();
error QueryTokenNotExist();
error QueryZeroAddress();

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
contract ERC721RAUpgradable is
    Initializable,
    ContextUpgradeable,
    ERC165Upgradeable,
    IERC721Upgradeable,
    IERC721MetadataUpgradeable,
    OwnableUpgradeable
{
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token data to track token
    struct TokenData {
        // Whether the token has been burned.
        bool burned;
        // Whether token has been refunded
        bool refunded;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // The address of the owner.
        address ownerAddress;
        // Track refund information of each token. Token can be returned even they're not owned by minter.
        // Only allowed to refund once, Keeps track of the price paid by minter, price in Wei
        uint256 price;
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
        // To record extra information.
        uint32 aux;
    }

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // The number of tokens refunded.
    uint256 internal _refundCounter;

    // The refund end timestamp
    uint256 private _refundEndTime;

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

    function __ERC721RA_init(
        string memory name_,
        string memory symbol_,
        uint256 refundEndTime_
    ) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();

        _refundEndTime = refundEndTime_;
        _returnAddress = _msgSender();
    }

    /**
     * @dev To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view returns (uint256) {
        // Impossible to underflow:
        // _burnCounter cannot be greater than _currentIndex - _startTokenId()
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Impossible to underflow:
        // _currentIndex is always greater than or equal to_startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) external view override returns (uint256) {
        if (owner == address(0)) revert QueryZeroAddress();
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
    function pricePaid(uint256 tokenId) public view returns (uint256) {
        return _ownerOf(tokenId).price;
    }

    /**
     * @dev Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_ownerData[owner].numberMinted);
    }

    /**
     * @dev Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_ownerData[owner].numberBurned);
    }

    /**
     * @dev Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _numberRefunded(address owner) internal view returns (uint256) {
        return uint256(_ownerData[owner].numberRefunded);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint32) {
        return _ownerData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint32.
     */
    function _setAux(address owner, uint32 aux) internal {
        _ownerData[owner].aux = aux;
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownerOf(uint256 tokenId) internal view returns (TokenData memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr) {
                if (curr < _currentIndex) {
                    TokenData memory tokenData = _tokenData[curr];

                    // Check if token is not burnt
                    if (!tokenData.burned) {
                        if (tokenData.ownerAddress != address(0)) {
                            return tokenData;
                        }

                        // Underlying magic:
                        // Doesn't explicitly set owner address for consecutive tokens when minting
                        // Set ownership when checking the data
                        // Impossible for --curr to be underflow
                        // Token can never be burnt before minted
                        while (true) {
                            tokenData = _tokenData[--curr];
                            if (tokenData.ownerAddress != address(0)) {
                                return tokenData;
                            }
                        }
                    }
                }
            }
        }

        revert QueryTokenNotExist();
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
        if (!_exists(tokenId)) revert QueryTokenNotExist();

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
        address owner = ERC721RAUpgradable.ownerOf(tokenId);
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
        if (!_exists(tokenId)) revert QueryTokenNotExist();

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
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
    function _safeMint(
        address to,
        uint256 amount,
        uint256 pricePaid_
    ) internal {
        _safeMint(to, amount, pricePaid_, "");
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
    function _safeMint(
        address to,
        uint256 amount,
        uint256 pricePaid_,
        bytes memory _data
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (amount == 0) revert MintZeroAmount();

        _beforeTokenTransfers(address(0), to, startTokenId, amount);

        // Incredibly unlikely to overflow:
        // balance or numberMinted overflow if either + amount > 2**32 - 1
        // updatedIndex overflow if _currentIndex + amount > 2**256 - 1
        unchecked {
            _ownerData[to].balance += uint32(amount);
            _ownerData[to].numberMinted += uint32(amount);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + amount;

            // Underlying magic: doesn't explicitly set owner address for consecutive tokens when minting
            _tokenData[updatedIndex].ownerAddress = to;
            _tokenData[startTokenId].startTimestamp = uint64(block.timestamp);
            _tokenData[updatedIndex].price = pricePaid_;

            if (to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex != end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex != end);
            }
            _currentIndex = updatedIndex;
        }

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
    function _mint(
        address to,
        uint256 amount,
        uint256 pricePaid_
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (amount == 0) revert MintZeroAmount();

        _beforeTokenTransfers(address(0), to, startTokenId, amount);

        // Incredibly unlikely to overflow:
        // balance or numberMinted overflow if either + amount > 2**32 - 1
        // updatedIndex overflow if _currentIndex + amount > 2**256 - 1
        unchecked {
            _ownerData[to].balance += uint32(amount);
            _ownerData[to].numberMinted += uint32(amount);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + amount;

            // Underlying magic: doesn't explicitly set owner address for consecutive tokens when minting
            _tokenData[updatedIndex].ownerAddress = to;
            _tokenData[startTokenId].startTimestamp = uint64(block.timestamp);
            _tokenData[updatedIndex].price = pricePaid_;

            do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex != end);

            _currentIndex = updatedIndex;
        }

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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenData memory prevTokenData = _ownerOf(tokenId);

        if (prevTokenData.ownerAddress != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Impossible for from address to underflow, or to address to overflow
        // nextTokenId is incredibly unlikely to overflow
        unchecked {
            _ownerData[from].balance -= 1;
            _ownerData[to].balance += 1;

            TokenData storage currSlot = _tokenData[tokenId];

            // Must update price paid when transfer
            currSlot.ownerAddress = to;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.price = prevTokenData.price;

            // If the tokenData slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;

            TokenData storage nextSlot = _tokenData[nextTokenId];
            if (nextSlot.ownerAddress == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    // Must update price paid for from address which owns the next token
                    nextSlot.ownerAddress = from;
                    nextSlot.startTimestamp = prevTokenData.startTimestamp;
                    nextSlot.price = prevTokenData.price;
                }
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

        // Impossible for balance to go underflow, or numberBurned to overflow
        // nextTokenId is icredibly unlikely to overflow
        unchecked {
            OwnerData storage ownerData = _ownerData[from];
            ownerData.balance -= 1;
            ownerData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenData storage currSlot = _tokenData[tokenId];
            currSlot.ownerAddress = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.price = prevTokenData.price;
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
                    nextSlot.price = prevTokenData.price;
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * emit a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
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
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == IERC721ReceiverUpgradeable(to).onERC721Received.selector;
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
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 amount
    ) internal virtual {}

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
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[42] private __gap;

    /**
     * @dev Set the return address
     */
    function setReturnAddress(address to) external onlyOwner {
        if (to == address(0)) revert ReturnAddressSetToZeroAddress();
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
    function refundActive() public view returns (bool) {
        return _refundEndTime > block.timestamp;
    }

    /**
     * @dev Refund the current owner of the token
     * to - the refund payment is paid to
     */
    function _refund(address to, uint256 tokenId) internal {
        if (!refundActive()) revert RefundNotActive();
        if (to == address(0)) revert RefundToZeroAddress();

        if (_msgSender() != ownerOf(tokenId)) revert RefundCallerNotOwner();
        if (_tokenData[tokenId].burned) revert RefundTokenHasBeenBurned();
        if (_tokenData[tokenId].refunded) revert RefundHasAlreadyBeenMade();

        uint256 refundAmount = pricePaid(tokenId);

        if (refundAmount == 0) revert RefundZeroAmount();

        _beforeTokenTransfers(_msgSender(), _returnAddress, tokenId, 1);

        // Refund amount is impossible to overflow
        unchecked {
            // No need to change balance here, SafeTransferFrom updates balance
            _tokenData[tokenId].refunded = true;
            _ownerData[_msgSender()].numberRefunded += 1;
            _refundCounter++;
        }

        // safeTransferFrom updates price and startTimestamp of new owner
        safeTransferFrom(_msgSender(), _returnAddress, tokenId);

        (bool success, ) = to.call{value: refundAmount}("");
        if (!success) revert RefundNotSucceed();

        emit Transfer(_msgSender(), _returnAddress, tokenId);
        _afterTokenTransfers(_msgSender(), _returnAddress, tokenId, 1);
    }

    /**
     * @dev Can only withdraw after when the refund is inactive
     */
    function _withdraw(address to) internal virtual onlyOwner {
        if (refundActive()) revert WithdrawWhenRefundActive();
        if (to == address(0)) revert WithdrawToZeroAddress();

        uint256 contractBalance = address(this).balance;
        if (contractBalance == 0) revert WithdrawZeroBalance();

        (bool success, ) = to.call{value: contractBalance}("");

        if (!success) revert WithdrawNotSucceed();
    }
}
