//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Erc1155MembershipMint} from "../src/Erc1155MembershipMint.sol";

contract DeployErc1155MembershipMint is Script {
        struct NetworkConfig {
        string erc1155ForMinterServiceUri;
        string erc1155MembershioMintUri;
        address payment_token_contract_address;
        uint256 payment_token_contract_decimals;
        address treasury;
    }

    HelperConfig public helperConfig;

    function run() external returns (Erc1155MembershipMint) {
        helperConfig = new HelperConfig();
        (, string memory uri, address payment_token_contract_address, uint256 payment_token_contract_decimals, address treasury) = helperConfig.activeNetworkConfig();
        vm.startBroadcast();
        Erc1155MembershipMint erc1155MembershipMint = new Erc1155MembershipMint(
                uri,
                payment_token_contract_address,
                payment_token_contract_decimals,
                treasury
            );
        vm.stopBroadcast();
        return erc1155MembershipMint;
    }
}
