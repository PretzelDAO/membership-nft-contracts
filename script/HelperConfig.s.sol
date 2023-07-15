// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

//1. Deploy mocks when we are on a local anvil chain
//2. Keep track of contract addresses accross different networks
//Sepolia ETH/USD
//main net ETH/USD

import {Script} from "forge-std/Script.sol";

uint8 constant ETH_USD_DECIMALS = 8;
int256 constant ETH_USD_INITIAL_PRICE = 1600e8;
uint256 constant SEPOLIA_CHAIN_ID = 11155111;
uint256 constant MAINNET_CHAIN_ID = 1;
string constant ERC1155_FOR_MINTER_URI = "insert_uri_here";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        string erc1155ForMinterServiceUri;
    }

    constructor() {
        if (block.chainid == SEPOLIA_CHAIN_ID) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == MAINNET_CHAIN_ID) {
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            erc1155ForMinterServiceUri: ERC1155_FOR_MINTER_URI
        });
        return sepoliaConfig;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            erc1155ForMinterServiceUri: ERC1155_FOR_MINTER_URI
        });
        return sepoliaConfig;
    }

    function getOrCreateAnvilEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory anvilConfig = NetworkConfig({
            erc1155ForMinterServiceUri: ERC1155_FOR_MINTER_URI
        });

        return anvilConfig;
    }
}
