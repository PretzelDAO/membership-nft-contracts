//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155MetadataURI} from "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract Erc721MembershipMint is ERC721, AccessControl {
    bytes32 public constant ADMIN = keccak256("ADMIN");

    //price - without the decimals - so 50USDC -> 50
    uint256 public price;

    //whitelists - membership number == token id -> whitelist already sets the id so a member will have the same ID every year
    mapping(address => uint256) public whitelistWithId;

    IERC20 public payment_token_contract; //Polygon USDC: 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174
    uint256 public payment_token_contract_decimals; //Polygon USDC: 6

    address public treasury;

    string public baseUri;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        address _payment_token_contract,
        uint256 _payment_token_contract_decimals,
        uint256 _price,
        address _treasury
    ) ERC721(_name, _symbol) {
        _grantRole(ADMIN, msg.sender);
        payment_token_contract = IERC20(_payment_token_contract);
        payment_token_contract_decimals = _payment_token_contract_decimals;
        treasury = _treasury;
        baseUri = _baseUri; //assumption: all NFTs are the same -> containing an image and the year of the membership
        price = _price;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

        //this is a soulbound token - only the ADMIN can move a token
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override onlyRole(ADMIN) {
        _transfer(from, to, id);
    }

    //this is a soulbound token - only the ADMIN can move a token
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual override onlyRole(ADMIN) {
        _safeTransfer(from, to, id, data);
    }

    //this is a soulbound token - only the ADMIN can move a token
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override onlyRole(ADMIN) {
        safeTransferFrom(from, to, id, "");
    }

    function mint() public {
        require(whitelistWithId[msg.sender] != 0, "not whitelisted");
        //allowance for payment Token needs to be set - requires call of increaseAllowance(address spender, uint256 addedValue) on the payment token contract beforehand
        require(
            payment_token_contract.allowance(msg.sender, address(this)) >=
                price * 10 ** payment_token_contract_decimals,
            "not enough allowance for payment token"
        );
        uint256 id = whitelistWithId[msg.sender];
        //send the payment token to the treasury
        payment_token_contract.transferFrom(
            msg.sender,
            treasury,
            price * 10 ** payment_token_contract_decimals
        );
        //remove from whitelist
       whitelistWithId[msg.sender] = 0;
        _safeMint(msg.sender, id, "");
    }

    function freeMint(address _to, uint256 _id) public onlyRole(ADMIN) {
        _safeMint(_to, _id, "");
    }

    // Add an address to the whitelist
    function addToWhitelist(address _address, uint256 _reservedTokenId) external onlyRole(ADMIN) {
        whitelistWithId[_address] = _reservedTokenId;
    }

    function addBatchToWhitelist(address[] memory _addresses, uint256[] memory _ids) external onlyRole(ADMIN) {
        require (_ids.length == _addresses.length, "ids and addresses length mismatch");
        for (uint256 i = 0; i < _ids.length; i++) {
            whitelistWithId[_addresses[i]] = _ids[i];
        }
    }

    function removeBatchFromWhitelist(address[] memory _addresses) external onlyRole(ADMIN) {
        for (uint256 i = 0; i < _addresses.length; i++) {
             whitelistWithId[_addresses[i]] = 0;
        }
    }

    // Remove an address from the whitelist
    function removeFromWhitelist(address _address) external onlyRole(ADMIN) {
        whitelistWithId[_address] = 0;
    }

    //SETTERS

    function setPrice(uint256 _price) external onlyRole(ADMIN) {
        price = _price;
    }

    function setTreasury(address _treasury) external onlyRole(ADMIN) {
        treasury = _treasury;
    }

    function setURI(string memory _baseUri) public onlyRole(ADMIN) {
        baseUri = _baseUri;
    }

//assumption: each token has the same meta data - image and year of the membership
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        _requireMinted(_tokenId);

        return baseUri;
    }

    function setPaymentTokenContract(address _payment_token_contract) external onlyRole(ADMIN) {
        payment_token_contract = IERC20(_payment_token_contract);
    }

    function setPaymentTokenContractDecimals(uint256 _payment_token_contract_decimals) external onlyRole(ADMIN) {
        payment_token_contract_decimals = _payment_token_contract_decimals;
    }

    //ROLE MANAGEMENT
    function grantAdmin(address _admin) public onlyRole(ADMIN) {
        _grantRole(ADMIN, _admin);
    }

    function revokeAdmin(address _admin) public onlyRole(ADMIN) {
        _revokeRole(ADMIN, _admin);
    }
}
