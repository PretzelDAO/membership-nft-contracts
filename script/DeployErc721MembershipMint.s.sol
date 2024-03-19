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
        helperConfig = new HelperConfig();
        (, string memory uri, address paymentTokenContractAddress, uint256 paymentTokenContractDecimals, address treasury, string memory defaultImageUrl, string memory defaultMemberRole, address backupAdmin) = helperConfig.activeNetworkConfig();
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