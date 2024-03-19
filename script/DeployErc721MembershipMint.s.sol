//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Erc721MembershipMint} from "../src/Erc721MembershipMint.sol";

contract DeployErc721MembershipMint is Script {
    string _name = "PretzelDAO Membership Card 2024";
    string _symbol = "PRTZL24";
    uint256 _price = 20;


    HelperConfig public helperConfig;

    function run() external returns (Erc721MembershipMint) {

        string memory uri = "";
        address paymentTokenContractAddress = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
        uint256 paymentTokenContractDecimals = 6;
        address treasury = 0xeA46ef9c1B0B6D36bF523758DAbcb1D11B8B4A7B;
        string memory defaultImageUrl = "ipfs://QmZwd45382Q7BmwguuvskuaT3oeF9Eq6AZ8wq4qCWLdLcC";
        string memory defaultMemberRole = "Member";
        address backupAdmin = 0xb1845e478555bfcb183DD9cB748a20e0E3684509;

        vm.startBroadcast();
        Erc721MembershipMint erc721MembershipMint = new Erc721MembershipMint(
                _name,
                _symbol,
                uri,
                paymentTokenContractAddress,
                paymentTokenContractDecimals,
                _price,
                treasury,
                defaultImageUrl,
                defaultMemberRole,
                backupAdmin
            );
        vm.stopBroadcast();
        return erc721MembershipMint;
    }
}