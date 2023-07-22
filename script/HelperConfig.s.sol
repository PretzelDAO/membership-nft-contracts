// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

//1. Deploy mocks when we are on a local anvil chain
//2. Keep track of contract addresses accross different networks
//Sepolia ETH/USD
//main net ETH/USD

import {Script} from "forge-std/Script.sol";
import {UsdcMock} from "../test/mocks/UsdcMock.sol";

uint8 constant ETH_USD_DECIMALS = 8;
int256 constant ETH_USD_INITIAL_PRICE = 1600e8;
uint256 constant SEPOLIA_CHAIN_ID = 11155111;
uint256 constant MAINNET_CHAIN_ID = 1;
string constant ERC1155_FOR_MINTER_URI = "insert_uri_here";
string constant ERC1155_MEMBERSHIP_MINT_URI = "insert_uri_here";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        string erc1155ForMinterServiceUri;
        string erc1155MembershioMintUri;
        address payment_token_contract_address;
        uint256 payment_token_contract_decimals;
        address treasury;
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

    function getSepoliaEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.payment_token_contract_address != address(0)) {
            return activeNetworkConfig;
        }
        vm.startBroadcast();
        UsdcMock usdcMock = new UsdcMock();
        vm.stopBroadcast();

        NetworkConfig memory sepoliaConfig = NetworkConfig({
            erc1155ForMinterServiceUri: ERC1155_FOR_MINTER_URI,
            erc1155MembershioMintUri: ERC1155_MEMBERSHIP_MINT_URI,
            payment_token_contract_address: address(usdcMock),
            payment_token_contract_decimals: usdcMock.decimals(),
            treasury: address(0)
        });

        return sepoliaConfig;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            erc1155ForMinterServiceUri: ERC1155_FOR_MINTER_URI,
            erc1155MembershioMintUri: ERC1155_MEMBERSHIP_MINT_URI,
            payment_token_contract_address: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            payment_token_contract_decimals: 6,
            treasury: address(0)
        });
        return sepoliaConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.payment_token_contract_address != address(0)) {
            return activeNetworkConfig;
        }
        vm.startBroadcast();
        UsdcMock usdcMock = new UsdcMock();
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            erc1155ForMinterServiceUri: ERC1155_FOR_MINTER_URI,
            erc1155MembershioMintUri: ERC1155_MEMBERSHIP_MINT_URI,
            payment_token_contract_address: address(usdcMock),
            payment_token_contract_decimals: usdcMock.decimals(),
            treasury: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
        });

        return anvilConfig;
    }
}
