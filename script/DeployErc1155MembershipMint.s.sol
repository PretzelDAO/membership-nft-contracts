//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Erc1155MembershipMint} from "../src/Erc1155MembershipMint.sol";

contract DeployErc1155MembershipMint is Script {
    HelperConfig public helperConfig;

    function run() external returns (Erc1155MembershipMint) {
        helperConfig = new HelperConfig();
        (, string memory uri, address paymentTokenContractAddress, uint256 paymentTokenContractDecimals, address treasury,,,) = helperConfig.activeNetworkConfig();
        vm.startBroadcast();
        Erc1155MembershipMint erc1155MembershipMint = new Erc1155MembershipMint(
                uri,
                paymentTokenContractAddress,
                paymentTokenContractDecimals,
                treasury
            );
        vm.stopBroadcast();
        return erc1155MembershipMint;
    }
}
