//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Erc1155ForMinterService} from "../src/Erc1155ForMinterService.sol";

contract DeployErc1155ForMinterService is Script {
    function run() external returns (Erc1155ForMinterService) {
        HelperConfig helperConfig = new HelperConfig();
        string memory uri = helperConfig.activeNetworkConfig();
        vm.startBroadcast();
        Erc1155ForMinterService erc1155ForMinterService = new Erc1155ForMinterService(
                uri
            );
        vm.stopBroadcast();
        return erc1155ForMinterService;
    }
}
