//SPDX-License-Identifier: MIT
//developed for the first membership card mint of PretzelDAO
pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155MetadataURI} from "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract Erc721MembershipMint is ERC721, AccessControl {
    using Strings for uint256;

    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant NFT_MANAGEMENT = keccak256("MINTER");
    bytes32 public constant NFT_MOVEMENT = keccak256("TRANSFER");

    //price - without the decimals - so 50USDC -> 50
    uint256 public price;

    //allowlists - membership number == token id -> allowlist already sets the id so a member will have the same ID every year
    mapping(address => uint256) public allowlistWithId;

    //customization options for NFTs
    mapping(uint256 => string) public tokenIdToCustomizedImageUrl;
    mapping(uint256 => string) public tokenIdToCustomizedMemberRole;

    string public defaultImageUrl;
    string public defaultMemberRole;

    IERC20 public paymentTokenContract; //Polygon USDC: 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174
    uint256 public paymentTokenContractDecimals; //Polygon USDC: 6

    address public treasury;

    string public baseUri;

    address public backupAdmin;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        address _paymentTokenContract,
        uint256 _paymentTokenContractDecimals,
        uint256 _price,
        address _treasury,
        string memory _defaultImageUrl,
        string memory _defaultMemberRole,
        address _backupAdmin
    ) ERC721(_name, _symbol) {
        _grantRole(ADMIN, msg.sender);
        paymentTokenContract = IERC20(_paymentTokenContract);
        paymentTokenContractDecimals = _paymentTokenContractDecimals;
        treasury = _treasury;
        baseUri = _baseUri; //assumption: all NFTs are the same -> containing an image and the year of the membership
        price = _price;
        defaultImageUrl = _defaultImageUrl;
        defaultMemberRole = _defaultMemberRole;
        backupAdmin = _backupAdmin;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function mint() public {
        require(allowlistWithId[msg.sender] != 0, "not allowlisted");
        //allowance for payment Token needs to be set - requires call of increaseAllowance(address spender, uint256 addedValue) on the payment token contract beforehand
        require(
            paymentTokenContract.allowance(msg.sender, address(this)) >=
                price * 10 ** paymentTokenContractDecimals,
            "not enough allowance for payment token"
        );
        uint256 id = allowlistWithId[msg.sender];
        //send the payment token to the treasury
        paymentTokenContract.transferFrom(msg.sender, treasury, price * 10 ** paymentTokenContractDecimals);
        //remove from allowlist
        allowlistWithId[msg.sender] = 0;
        _safeMint(msg.sender, id, "");
    }

    //Onchain Metadata

    struct TokenMetadata {
        string tokenId;
        string imageUrl;
        string memberRole;

    }   
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        _requireMinted(_tokenId);

        TokenMetadata memory tokenMetadata;

        tokenMetadata.tokenId = Strings.toString(_tokenId);
        tokenMetadata.imageUrl = getImageUrl(_tokenId);
        tokenMetadata.memberRole = getMemberRole(_tokenId);

        bytes memory dataURI = abi.encodePacked(
            '{',
                '"name": "PretzelDAO Membership Card 2023 #', tokenMetadata.tokenId, '",',
                '"description": "PretzelDAO e.V. Membership Card for the year 2023, one per active and verified member. Membership Card NFT is used as a governance token for the DAO. The token is soulbound.",',
                '"image": "', tokenMetadata.imageUrl, '","token_id": ', tokenMetadata.tokenId, ',"external_url":"https://pretzeldao.com/",',
                '"attributes":[{"trait_type": "Edition","value": "2023"}, {"key":"Type","trait_type":"Type","value":"Governance Token"},',
                '{"display_type": "date","trait_type":"Valid until","value":1704063599},{"trait_type": "Member Role","value": "', tokenMetadata.memberRole, '"}]'
            '}'
        );
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
            )
        );
    }


    //NFT MOVEMENT
    function freeMint(address _to, uint256 _id) public onlyRole(NFT_MOVEMENT) {
        _safeMint(_to, _id, "");
    }

    //this is a soulbound token - only the ADMIN can move a token
    function transferFrom(address from, address to, uint256 id) public virtual override onlyRole(NFT_MOVEMENT) {
        _transfer(from, to, id);
    }

    //this is a soulbound token - only the ADMIN can move a token
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual override onlyRole(NFT_MOVEMENT) {
        _safeTransfer(from, to, id, data);
    }

    //this is a soulbound token - only the ADMIN can move a token
    function safeTransferFrom(address from, address to, uint256 id) public virtual override onlyRole(NFT_MOVEMENT) {
        safeTransferFrom(from, to, id, "");
    }

    //since the token cannot be transferred by the owner, there is no need to approve it
    function approve(address, uint256) public virtual override {
        revert("This is a soulbound token - you cannot approve it");
    }


    //NFT MANAGEMENT

    function setImageUrl(uint256 _tokenId, string memory _imageUrl) external onlyRole(NFT_MANAGEMENT) {
        tokenIdToCustomizedImageUrl[_tokenId] = _imageUrl;
    }

    function getImageUrl(uint256 _tokenId) public view returns (string memory) {
        if (bytes(tokenIdToCustomizedImageUrl[_tokenId]).length > 0) {
            return tokenIdToCustomizedImageUrl[_tokenId];
        }
        return defaultImageUrl;
    }

    function setMemberRole(uint256 _tokenId, string memory _memberRole) external onlyRole(NFT_MANAGEMENT) {
        tokenIdToCustomizedMemberRole[_tokenId] = _memberRole;
    }

    function getMemberRole(uint256 _tokenId) public view returns (string memory) {
        if (bytes( tokenIdToCustomizedMemberRole[_tokenId]).length > 0) {
            return  tokenIdToCustomizedMemberRole[_tokenId];
        }
        return defaultMemberRole;
    }

    // Add an address to the allowlist
    function addToAllowlist(address _address, uint256 _reservedTokenId) external onlyRole(NFT_MANAGEMENT) {
        allowlistWithId[_address] = _reservedTokenId;
    }

    function addBatchToAllowlist(address[] memory _addresses, uint256[] memory _ids) external onlyRole(NFT_MANAGEMENT) {
        require(_ids.length == _addresses.length, "ids and addresses length mismatch");
        for (uint256 i = 0; i < _ids.length; i++) {
            allowlistWithId[_addresses[i]] = _ids[i];
        }
    }

    function removeBatchFromAllowlist(address[] memory _addresses) external onlyRole(NFT_MANAGEMENT) {
        for (uint256 i = 0; i < _addresses.length; i++) {
            allowlistWithId[_addresses[i]] = 0;
        }
    }

    // Remove an address from the allowlist
    function removeFromAllowlist(address _address) external onlyRole(NFT_MANAGEMENT) {
        allowlistWithId[_address] = 0;
    }


    //ADMIN
    function setPaymentTokenContractAndDecimals(address _paymentTokenContract, uint256 _paymentTokenContractDecimals ) external onlyRole(ADMIN) {
        paymentTokenContract = IERC20(_paymentTokenContract);
        paymentTokenContractDecimals = _paymentTokenContractDecimals;
    }

        function setPrice(uint256 _price) external onlyRole(ADMIN) {
        price = _price;
    }

    function setTreasury(address _treasury) external onlyRole(ADMIN) {
        treasury = _treasury;
    }

    function grantAdmin(address _admin) public {
        require(hasRole(ADMIN, msg.sender) || msg.sender == backupAdmin, "only admin or backup admin can grant admin");
        _grantRole(ADMIN, _admin);
    }

    function revokeAdmin(address _admin) public onlyRole(ADMIN) {
        _revokeRole(ADMIN, _admin);
    }

    
    function grantNftMovement(address _nftMovement) public onlyRole(ADMIN) {
        _grantRole(NFT_MOVEMENT, _nftMovement);
    }

    function revokeNftMovement(address _admin) public onlyRole(ADMIN) {
        _revokeRole(NFT_MOVEMENT, _admin);
    }

    
    function grantNftManagement(address _nftManagement) public onlyRole(ADMIN) {
        _grantRole(NFT_MANAGEMENT, _nftManagement);
    }

    function revokeNftManagement(address _nftManagement) public onlyRole(ADMIN) {
        _revokeRole(NFT_MANAGEMENT, _nftManagement);
    }
}
