//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Erc721MembershipMint} from "../src/Erc721MembershipMint.sol";

contract DeployErc721MembershipMint is Script {
        struct NetworkConfig {
        string erc1155ForMinterServiceUri;
        string erc1155MembershipMintUri;
        address payment_token_contract_address;
        uint256 payment_token_contract_decimals;
        address treasury;
    }

    string name = "Membership2023";
    string symbol = "MEMB23";
    uint256 price = 50;


    HelperConfig public helperConfig;

    function run() external returns (Erc721MembershipMint) {
        helperConfig = new HelperConfig();
        (, string memory uri, address payment_token_contract_address, uint256 payment_token_contract_decimals, address treasury) = helperConfig.activeNetworkConfig();
        vm.startBroadcast();
        Erc721MembershipMint erc721MembershipMint = new Erc721MembershipMint(
                name,
                symbol,
                uri,
                payment_token_contract_address,
                payment_token_contract_decimals,
                price,
                treasury
            );
        vm.stopBroadcast();
        return erc721MembershipMint;
    }
}