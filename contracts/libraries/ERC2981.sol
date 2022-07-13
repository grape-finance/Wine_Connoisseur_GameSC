//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @title IERC2981
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981 {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}

interface RoyaltiesInterface {
    function claimCommunity(address collectionAddress, uint256 tokenId)
        external;
}

abstract contract RoyaltiesAddon is ERC721 {
    address public royaltiesAddress;
    address public wineryAddress;

    /**
     * @dev internal set royalties address
     * @param _royaltiesAddress address of the Royalties.sol
     */
    function _setRoyaltiesAddress(address _royaltiesAddress) internal {
        royaltiesAddress = _royaltiesAddress;
    }

    function _setWineryAddress(address _wineryAddress) internal {
        wineryAddress = _wineryAddress;
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the royalties get auto claim on transfer
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (
            from != wineryAddress &&
            to != wineryAddress &&
            royaltiesAddress != address(0) &&
            from != address(0) &&
            !Address.isContract(from)
        ) {
            RoyaltiesInterface(royaltiesAddress).claimCommunity(
                address(this),
                tokenId
            );
        }
    }
}

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
abstract contract ERC2981 is ERC165, IERC2981 {
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == _INTERFACE_ID_ERC2981 ||
            super.supportsInterface(interfaceId);
    }
}
