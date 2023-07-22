//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155MetadataURI} from "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract Erc1155MembershipMint is ERC1155, AccessControl {
    bytes32 public constant ADMIN = keccak256("ADMIN");

    //price list
    mapping(uint256 => uint256) public tokenIdToPrice;

    //whitelists - one per tokenId
    mapping(uint256 => mapping(address => bool)) public tokenIdToWhitelist;

    IERC20 public payment_token_contract; //Polygon USDC: 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174
    uint256 public payment_token_contract_decimals; //Polygon USDC: 6

    address public treasury;

    string public baseURI;

    constructor(
        string memory _uri,
        address _payment_token_contract,
        uint256 _payment_token_contract_decimals,
        address _treasury
    ) ERC1155(_uri) {
        _grantRole(ADMIN, msg.sender);
        payment_token_contract = IERC20(_payment_token_contract);
        payment_token_contract_decimals = _payment_token_contract_decimals;
        treasury = _treasury;
        baseURI = _uri;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    //this is a soulbound token - only the ADMIN can move a token
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override onlyRole(ADMIN) {
        _safeTransferFrom(from, to, id, amount, data);
    }

    //this is a soulbound token - only the ADMIN can move a token
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyRole(ADMIN) {
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function mint(uint256 _id) public {
        require(tokenIdToWhitelist[_id][msg.sender], "not whitelisted");
        //allowance for payment Token needs to be set - requires call of increaseAllowance(address spender, uint256 addedValue) on the payment token contract beforehand
        require(
            payment_token_contract.allowance(msg.sender, address(this)) >=
                tokenIdToPrice[_id] * 10 ** payment_token_contract_decimals,
            "not enough allowance for payment token"
        );
        //only one token per wallet
        require(balanceOf(msg.sender, _id) == 0, "already received a membership token");
        //send the payment token to the treasury
        payment_token_contract.transferFrom(
            msg.sender,
            treasury,
            tokenIdToPrice[_id] * 10 ** payment_token_contract_decimals
        );
        //remove from whitelist
        tokenIdToWhitelist[_id][msg.sender] = false;
        _mint(msg.sender, _id, 1, "");
    }

    function freeMint(address _to, uint256 _id, uint256 _amount) public onlyRole(ADMIN) {
        _mint(_to, _id, _amount, "");
    }

    // Add an address to the whitelist
    function addToWhitelist(uint256 _id, address _address) external onlyRole(ADMIN) {
        tokenIdToWhitelist[_id][_address] = true;
    }

    function addBatchToWhitelist(uint256 _id, address[] memory _addresses) external onlyRole(ADMIN) {
        for (uint256 i = 0; i < _addresses.length; i++) {
            tokenIdToWhitelist[_id][_addresses[i]] = true;
        }
    }

    function removeBatchFromWhitelist(uint256 _id, address[] memory _addresses) external onlyRole(ADMIN) {
        for (uint256 i = 0; i < _addresses.length; i++) {
            tokenIdToWhitelist[_id][_addresses[i]] = false;
        }
    }

    // Remove an address from the whitelist
    function removeFromWhitelist(uint256 _id, address _address) external onlyRole(ADMIN) {
        tokenIdToWhitelist[_id][_address] = false;
    }

    //SETTERS

    function setPriceForTokenId(uint256 _price, uint256 _id) external onlyRole(ADMIN) {
        tokenIdToPrice[_id] = _price;
    }

    function setTreasury(address _treasury) external onlyRole(ADMIN) {
        treasury = _treasury;
    }

    function setURI(string memory _uri) public onlyRole(ADMIN) {
        baseURI = _uri;
    }

    function uri(uint256 _tokenId) public virtual override view returns (string memory) {
        return string.concat(baseURI, Strings.toString(_tokenId));
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
