//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155MetadataURI} from "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract Erc1155ForMinterService is ERC1155, AccessControl {
    bytes32 public constant MINTER = keccak256("MINTER");
    bytes32 public constant ADMIN = keccak256("ADMIN");

    event Erc1155ForMinterService_Mint(address indexed to, uint256 indexed id, uint256 amount);

    constructor(string memory _uri) ERC1155(_uri) {
        _grantRole(ADMIN, msg.sender);
        _grantRole(MINTER, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setURI(string memory uri) public onlyRole(ADMIN) {
        _setURI(uri);
    }

    function mint(address to, uint256 id, uint256 amount) public onlyRole(MINTER) {
        _mint(to, id, amount, "");
        emit Erc1155ForMinterService_Mint(to, id, amount);
    }

    function multiAddressMint(
        address[] memory to,
        uint256[] memory id,
        uint256[] memory amount
    ) public onlyRole(MINTER) {
        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], id[i], amount[i], "");
        }
    }

    function exitMinterRole() public onlyRole(MINTER) {
        _revokeRole(MINTER, msg.sender);
    }

    function grantMinter(address _minter) public onlyRole(ADMIN) {
        _grantRole(MINTER, _minter);
    }

    function revokeMinter(address _minter) public onlyRole(ADMIN) {
        _revokeRole(MINTER, _minter);
    }

    function grantAdmin(address _admin) public onlyRole(ADMIN) {
        _grantRole(ADMIN, _admin);
    }

    function revokeAdmin(address _admin) public onlyRole(ADMIN) {
        _revokeRole(ADMIN, _admin);
    }
}
