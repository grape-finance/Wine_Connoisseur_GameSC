// Chef
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./libraries/ERC2981.sol";

contract Vintner is Ownable, Pausable, RoyaltiesAddon, ERC2981 {
    using SafeERC20 for IERC20;
    using Strings for uint256;

    struct VintnerInfo {
        uint256 tokenId;
        uint256 vintnerType;
    }

    // CONSTANTS

    uint256 public constant VINTNER_PRICE_AVAX = 2.5 ether;
    uint256 public constant VINTNER_PRICE_GRAPE = 50 * 1e18;

    uint256 public WHITELIST_VINTNERS = 2700;
    uint256 public constant NUM_VINTNERS = 10_000;

    uint256 public constant VINTNER_TYPE = 1;
    uint256 public constant MASTER_VINTNER_TYPE = 2;

    uint256 public constant VINTNER_YIELD = 1;
    uint256 public constant MASTER_VINTNER_YIELD = 3;

    uint256 public constant PROMOTIONAL_VINTNERS = 50;

    // VAR
    // external contracts
    IERC20 public grapeAddress;
    // address public wineryAddress;
    address public vintnerTypeOracleAddress;

    // metadata URI
    string public BASE_URI;
    uint256 private royaltiesFees;

    // vintner type definitions (normal or master?)
    mapping(uint256 => uint256) public tokenTypes; // maps tokenId to its type
    mapping(uint256 => uint256) public typeYields; // maps vintner type to yield

    // mint tracking
    uint256 public vintnerPublicMinted;
    uint256 public vintnersMintedWhitelist;
    uint256 public vintnersMintedPromotional;
    uint256 public vintnersMinted = 50; // First 50 ids are reserved for the promotional vintners

    // mint control timestamps
    uint256 public startTimeWhitelist;
    uint256 public startTime;

    // whitelist
    address public couponSigner;
    struct Coupon {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }
    mapping(address => uint256) public whitelistClaimed;

    // EVENTS

    event onVintnerCreated(uint256 tokenId);
    event onVintnerRevealed(uint256 tokenId, uint256 vintnerType);

    /**
     * requires vintageWine, vintnerType oracle address
     * vintageWine: for liquidity bootstrapping and spending on vintners
     * vintnerTypeOracleAddress: external vintner generator uses secure RNG
     */
    constructor(
        address _grapeAddress,
        address _couponSigner,
        address _vintnerTypeOracleAddress,
        string memory _BASE_URI
    ) ERC721("The Vintners", "The VINTNERS") {
        couponSigner = _couponSigner;
        require(_vintnerTypeOracleAddress != address(0));

        // set required contract references
        grapeAddress = IERC20(_grapeAddress);
        vintnerTypeOracleAddress = _vintnerTypeOracleAddress;

        // set base uri
        BASE_URI = _BASE_URI;

        // initialize token yield values for each vintner type
        typeYields[VINTNER_TYPE] = VINTNER_YIELD;
        typeYields[MASTER_VINTNER_TYPE] = MASTER_VINTNER_YIELD;
    }

    // VIEWS

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // minting status

    function mintingStartedWhitelist() public view returns (bool) {
        return startTimeWhitelist != 0 && block.timestamp >= startTimeWhitelist;
    }

    function mintingStarted() public view returns (bool) {
        return startTime != 0 && block.timestamp >= startTime;
    }

    // metadata

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function getYield(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "token does not exist");
        return typeYields[tokenTypes[_tokenId]];
    }

    function getType(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "token does not exist");
        return tokenTypes[_tokenId];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(_baseURI(), "/", tokenId.toString(), ".json")
            );
    }

    // override

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool)
    {
        // winery must be able to stake and unstake
        if (wineryAddress != address(0) && _operator == wineryAddress)
            return true;
        return super.isApprovedForAll(_owner, _operator);
    }

    // ADMIN

    function setGrapeAddress(address _grapeAddress) external onlyOwner {
        grapeAddress = IERC20(_grapeAddress);
    }

    function setWineryAddress(address _wineryAddress) external onlyOwner {
        wineryAddress = _wineryAddress;
        super._setWineryAddress(_wineryAddress);
    }

    function setvintnerTypeOracleAddress(address _vintnerTypeOracleAddress)
        external
        onlyOwner
    {
        vintnerTypeOracleAddress = _vintnerTypeOracleAddress;
    }

    function setStartTimeWhitelist(uint256 _startTime) external onlyOwner {
        require(
            _startTime >= block.timestamp,
            "startTime cannot be in the past"
        );
        startTimeWhitelist = _startTime;
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        require(
            _startTime >= block.timestamp,
            "startTime cannot be in the past"
        );
        startTime = _startTime;
    }

    function setBaseURI(string calldata _BASE_URI) external onlyOwner {
        BASE_URI = _BASE_URI;
    }

    /**
     * @dev allows owner to send ERC20s held by this contract to target
     */
    function forwardERC20s(
        IERC20 _token,
        uint256 _amount,
        address target
    ) external onlyOwner {
        _token.safeTransfer(target, _amount);
    }

    /**
     * @dev allows owner to withdraw AVAX
     */
    function withdrawAVAX(uint256 _amount) external payable onlyOwner {
        require(address(this).balance >= _amount, "not enough AVAX");
        address payable to = payable(_msgSender());
        (bool sent, ) = to.call{ value: _amount }("");
        require(sent, "Failed to send AVAX");
    }

    // MINTING

    function _createVintner(address to, uint256 tokenId) internal {
        require(vintnersMinted <= NUM_VINTNERS, "cannot mint anymore vintners");
        _safeMint(to, tokenId);

        emit onVintnerCreated(tokenId);
    }

    function _createVintners(uint256 qty, address to) internal {
        for (uint256 i = 0; i < qty; i++) {
            vintnersMinted += 1;
            _createVintner(to, vintnersMinted);
        }
    }

    /**
     * @dev as an anti cheat mechanism, an external automation will generate the NFT metadata and set the vintner types via rng
     * - Using an external source of randomness ensures our mint cannot be cheated
     * - The external automation is open source and can be found on vintageWine game's github
     * - Once the mint is finished, it is provable that this randomness was not tampered with by providing the seed
     * - Vintner type can be set only once
     */
    function setVintnerType(uint256 tokenId, uint256 vintnerType) external {
        require(
            _msgSender() == vintnerTypeOracleAddress,
            "msgsender does not have permission"
        );
        require(
            tokenTypes[tokenId] == 0,
            "that token's type has already been set"
        );
        require(
            vintnerType == VINTNER_TYPE || vintnerType == MASTER_VINTNER_TYPE,
            "invalid vintner type"
        );

        tokenTypes[tokenId] = vintnerType;
        emit onVintnerRevealed(tokenId, vintnerType);
    }

    /**
     * @dev Promotional minting
     * Can mint maximum of PROMOTIONAL_VINTNERS
     * All vintners minted are from the same vintnerType
     */
    function mintPromotional(
        uint256 qty,
        uint256 vintnerType,
        address target
    ) external onlyOwner {
        require(qty > 0, "quantity must be greater than 0");
        require(
            (vintnersMintedPromotional + qty) <= PROMOTIONAL_VINTNERS,
            "you can't mint that many right now"
        );
        require(
            vintnerType == VINTNER_TYPE || vintnerType == MASTER_VINTNER_TYPE,
            "invalid vintner type"
        );

        for (uint256 i = 0; i < qty; i++) {
            vintnersMintedPromotional += 1;
            require(
                tokenTypes[vintnersMintedPromotional] == 0,
                "that token's type has already been set"
            );
            tokenTypes[vintnersMintedPromotional] = vintnerType;
            _createVintner(target, vintnersMintedPromotional);
        }
    }

    /**
     * @dev Whitelist minting
     * We implement a hard limit on the whitelist vintners.
     */

    function setWhitelistMintCount(uint256 qty) external onlyOwner {
        require(qty > 0, "quantity must be greater than 0");
        WHITELIST_VINTNERS = qty;
    }

    /**
     * * Set Coupon Signer
     * @dev Set the coupon signing wallet
     * @param couponSigner_ The new coupon signing wallet address
     */
    function setCouponSigner(address couponSigner_) external onlyOwner {
        couponSigner = couponSigner_;
    }

    function _isVerifiedCoupon(bytes32 digest, Coupon memory coupon)
        internal
        view
        returns (bool)
    {
        address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
        require(signer != address(0), "Zero Address");
        return signer == couponSigner;
    }

    function mintWhitelist(
        uint256 qty,
        uint256 allotted,
        Coupon memory coupon
    ) external whenNotPaused {
        // check most basic requirements
        require(mintingStartedWhitelist(), "cannot mint right now");
        require(
            qty + whitelistClaimed[_msgSender()] < allotted + 1,
            "Exceeds Max Allotted"
        );

        // Create digest to verify against signed coupon
        bytes32 digest = keccak256(abi.encode(allotted, _msgSender()));

        // Verify digest against signed coupon
        require(_isVerifiedCoupon(digest, coupon), "Invalid Coupon");

        vintnersMintedWhitelist += qty;
        whitelistClaimed[_msgSender()] += qty;

        // mint vintners
        _createVintners(qty, _msgSender());
    }

    /**
     * @dev Mint with Avax
     */
    function mintVintnerWithAVAX(uint256 qty) external payable whenNotPaused {
        require(mintingStarted(), "cannot mint right now");

        require(qty > 0 && qty <= 20, "Exceeds number of mints allowed");
        require(
            (vintnerPublicMinted + qty) <=
                (NUM_VINTNERS - WHITELIST_VINTNERS - PROMOTIONAL_VINTNERS),
            "Exceeds number of total mints allowed"
        );

        // calculate the transaction cost
        uint256 transactionCost = VINTNER_PRICE_AVAX * qty;
        require(msg.value >= transactionCost, "not enough AVAX");

        vintnerPublicMinted += qty;

        // mint vintners
        _createVintners(qty, _msgSender());
    }

    /**
     * @dev Mint with Grape
     */
    function mintVintnerWithGrape(uint256 qty) external whenNotPaused {
        require(mintingStarted(), "cannot mint right now");

        require(qty > 0 && qty <= 20, "Exceeds number of mints allowed");
        require(
            (vintnerPublicMinted + qty) <=
                (NUM_VINTNERS - WHITELIST_VINTNERS - PROMOTIONAL_VINTNERS),
            "Exceeds number of total mints allowed"
        );

        // calculate the transaction cost
        uint256 transactionCost = VINTNER_PRICE_GRAPE * qty;
        require(
            grapeAddress.balanceOf(_msgSender()) >= transactionCost,
            "not enough Grape"
        );

        grapeAddress.transferFrom(_msgSender(), address(this), transactionCost);

        vintnerPublicMinted += qty;

        // mint vintners
        _createVintners(qty, _msgSender());
    }

    /// @dev sets royalties address
    /// for royalties addon
    /// for 2981
    function setRoyaltiesAddress(address _royaltiesAddress) public onlyOwner {
        super._setRoyaltiesAddress(_royaltiesAddress);
    }

    /// @dev sets royalties fees
    function setRoyaltiesFees(uint256 _royaltiesFees) public onlyOwner {
        royaltiesFees = _royaltiesFees;
    }

    /// @inheritdoc	IERC2981
    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        if (tokenId > 0)
            return (royaltiesAddress, (value * royaltiesFees) / 100);
        else return (royaltiesAddress, 0);
    }

    // Returns information for multiples vintners
    // function batchedVintnersOfOwner(
    //     address _owner,
    //     uint256 _offset,
    //     uint256 _maxSize
    // ) public view returns (VintnerInfo[] memory) {
    //     if (_offset >= balanceOf(_owner)) {
    //         return new VintnerInfo[](0);
    //     }

    //     uint256 outputSize = _maxSize;
    //     if (_offset + _maxSize >= balanceOf(_owner)) {
    //         outputSize = balanceOf(_owner) - _offset;
    //     }
    //     VintnerInfo[] memory vintners = new VintnerInfo[](outputSize);

    //     for (uint256 i = 0; i < outputSize; i++) {
    //         uint256 tokenId = tokenOfOwnerByIndex(_owner, _offset + i); // tokenOfOwnerByIndex comes from IERC721Enumerable

    //         vintners[i] = VintnerInfo({
    //             tokenId: tokenId,
    //             vintnerType: tokenTypes[tokenId]
    //         });
    //     }

    //     return vintners;
    // }
}
