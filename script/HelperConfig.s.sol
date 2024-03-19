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
uint256 constant MUMBAI_CHAIN_ID = 80001;
uint256 constant ARBITRUM_ONE_ID = 42161;
uint256 constant MAINNET_CHAIN_ID = 1;
string constant ERC1155_FOR_MINTER_URI = "insert_uri_here";
string constant ERC1155_MEMBERSHIP_MINT_URI = "insert_uri_here";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address paymentTokenContractAddress;
        uint256 paymentTokenContractDecimals;
        address treasury;
        string defaultImageUrl;
        string defaultMemberRole;
        address backupAdmin;
    }

    constructor() {
        if (block.chainid == SEPOLIA_CHAIN_ID) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == MAINNET_CHAIN_ID) {
            activeNetworkConfig = getMainnetEthConfig();
        } else if (block.chainid = ARBITRUM_ONE_ID) {
            activeNetworkConfig = getArbitrumOneConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.paymentTokenContractAddress != address(0)) {
            return activeNetworkConfig;
        }
        vm.startBroadcast();
        UsdcMock usdcMock = new UsdcMock();
        vm.stopBroadcast();

        NetworkConfig memory sepoliaConfig = NetworkConfig({
            erc1155ForMinterServiceUri: ERC1155_FOR_MINTER_URI,
            erc1155MembershipMintUri: ERC1155_MEMBERSHIP_MINT_URI,
            paymentTokenContractAddress: address(usdcMock),
            paymentTokenContractDecimals: usdcMock.decimals(),
            treasury: address(0),
            defaultImageUrl: "ipfs://QmZwd45382Q7BmwguuvskuaT3oeF9Eq6AZ8wq4qCWLdLcC",
            defaultMemberRole: "Member",
            backupAdmin: address(0)
        });

        return sepoliaConfig;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            erc1155ForMinterServiceUri: ERC1155_FOR_MINTER_URI,
            erc1155MembershipMintUri: ERC1155_MEMBERSHIP_MINT_URI,
            paymentTokenContractAddress: 0xaf88d065e77c8cc2239327c5edb3a432268e5831,
            paymentTokenContractDecimals: 6,
            treasury: address(0),
            defaultImageUrl: "ipfs://QmZwd45382Q7BmwguuvskuaT3oeF9Eq6AZ8wq4qCWLdLcC",
            defaultMemberRole: "Member",
            backupAdmin: address(0)
        });
        return sepoliaConfig;
    }

    function getMumbaiPolygonConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.paymentTokenContractAddress != address(0)) {
            return activeNetworkConfig;
        }
        vm.startBroadcast();
        UsdcMock usdcMock = new UsdcMock();
        vm.stopBroadcast();

        NetworkConfig memory sepoliaConfig = NetworkConfig({
            erc1155ForMinterServiceUri: ERC1155_FOR_MINTER_URI,
            erc1155MembershipMintUri: ERC1155_MEMBERSHIP_MINT_URI,
            paymentTokenContractAddress: address(usdcMock),
            paymentTokenContractDecimals: usdcMock.decimals(),
            treasury: address(0),
            defaultImageUrl: "ipfs://QmZwd45382Q7BmwguuvskuaT3oeF9Eq6AZ8wq4qCWLdLcC",
            defaultMemberRole: "Member",
            backupAdmin: address(0)
        });

        return sepoliaConfig;
    }

    function getArbitrumOneConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.paymentTokenContractAddress != address(0)) {
            return activeNetworkConfig;
        }
        vm.startBroadcast();
        UsdcMock usdcMock = new UsdcMock();
        vm.stopBroadcast();

        NetworkConfig memory sepoliaConfig = NetworkConfig({
            paymentTokenContractAddress: address(0xaf88d065e77c8cc2239327c5edb3a432268e5831),
            paymentTokenContractDecimals: 6,
            treasury: address(0xeA46ef9c1B0B6D36bF523758DAbcb1D11B8B4A7B),
            defaultImageUrl: "ipfs://QmZwd45382Q7BmwguuvskuaT3oeF9Eq6AZ8wq4qCWLdLcC",
            defaultMemberRole: "Member",
            backupAdmin: address(0xb1845e478555bfcb183DD9cB748a20e0E3684509)
        });

        return sepoliaConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.paymentTokenContractAddress != address(0)) {
            return activeNetworkConfig;
        }
        vm.startBroadcast();
        UsdcMock usdcMock = new UsdcMock();
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            erc1155ForMinterServiceUri: ERC1155_FOR_MINTER_URI,
            erc1155MembershipMintUri: ERC1155_MEMBERSHIP_MINT_URI,
            paymentTokenContractAddress: address(usdcMock),
            paymentTokenContractDecimals: usdcMock.decimals(),
            treasury: 0xb1845e478555bfcb183DD9cB748a20e0E3684509,
            defaultImageUrl: "ipfs://QmZwd45382Q7BmwguuvskuaT3oeF9Eq6AZ8wq4qCWLdLcC",
            defaultMemberRole: "Member",
            backupAdmin: 0xb1845e478555bfcb183DD9cB748a20e0E3684509
        });

        return anvilConfig;
    }
}
