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
uint256 constant MAINNET_CHAIN_ID = 1;
string constant ERC1155_FOR_MINTER_URI = "insert_uri_here";
string constant ERC1155_MEMBERSHIP_MINT_URI = "insert_uri_here";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        string erc1155ForMinterServiceUri;
        string erc1155MembershipMintUri;
        address paymentTokenContractAddress;
        uint256 paymentTokenContractDecimals;
        address treasury;
        string defaultImageUrl;
        string defaultMemberRole;
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
            defaultImageUrl: "ipfs://QmdF1a7Y5dXYPUocpiX6uyF3oZMJB939G1eVUdPnKCBDwM",
            defaultMemberRole: "Member"
        });

        return sepoliaConfig;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            erc1155ForMinterServiceUri: ERC1155_FOR_MINTER_URI,
            erc1155MembershipMintUri: ERC1155_MEMBERSHIP_MINT_URI,
            paymentTokenContractAddress: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            paymentTokenContractDecimals: 6,
            treasury: address(0),
            defaultImageUrl: "ipfs://QmdF1a7Y5dXYPUocpiX6uyF3oZMJB939G1eVUdPnKCBDwM",
            defaultMemberRole: "Member"
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
            defaultImageUrl: "ipfs://QmdF1a7Y5dXYPUocpiX6uyF3oZMJB939G1eVUdPnKCBDwM",
            defaultMemberRole: "Member"
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
            treasury: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            defaultImageUrl: "ipfs://QmdF1a7Y5dXYPUocpiX6uyF3oZMJB939G1eVUdPnKCBDwM",
            defaultMemberRole: "Member"
        });

        return anvilConfig;
    }
}
