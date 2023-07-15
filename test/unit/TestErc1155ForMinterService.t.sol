// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {Erc1155ForMinterService} from "../../src/Erc1155ForMinterService.sol";
import {DeployErc1155ForMinterService} from "../../script/DeployErc1155ForMinterService.s.sol";

contract TestErc1155ForMinterService is Test {
    Erc1155ForMinterService erc1155ForMinterService;
    address MINTER = makeAddr("MINTER");
    address ADMIN = makeAddr("ADMIN");
    string TEST_URI = "https://example.com";

    function setUp() external {
        DeployErc1155ForMinterService deployErc1155ForMinterService = new DeployErc1155ForMinterService();
        erc1155ForMinterService = deployErc1155ForMinterService.run();
        vm.startPrank(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38);
        erc1155ForMinterService.grantMinter(MINTER);
        erc1155ForMinterService.grantAdmin(ADMIN);
        vm.stopPrank();
    }

    function testExitMinterRole() external {
        assertTrue(
            erc1155ForMinterService.hasRole(
                erc1155ForMinterService.MINTER(),
                MINTER
            )
        );
        vm.prank(MINTER);
        erc1155ForMinterService.exitMinterRole();
        assertFalse(
            erc1155ForMinterService.hasRole(
                erc1155ForMinterService.MINTER(),
                MINTER
            )
        );
    }

    function testGrantAdmin() external {
        assertFalse(
            erc1155ForMinterService.hasRole(
                erc1155ForMinterService.ADMIN(),
                MINTER
            )
        );
        assertTrue(
            erc1155ForMinterService.hasRole(
                erc1155ForMinterService.ADMIN(),
                ADMIN
            )
        );
        vm.prank(ADMIN);
        erc1155ForMinterService.grantAdmin(MINTER);
        assertTrue(
            erc1155ForMinterService.hasRole(
                erc1155ForMinterService.ADMIN(),
                MINTER
            )
        );
    }

    function testRevokeAdmin() external {
        assertTrue(
            erc1155ForMinterService.hasRole(
                erc1155ForMinterService.ADMIN(),
                ADMIN
            )
        );
        vm.prank(ADMIN);
        erc1155ForMinterService.revokeAdmin(ADMIN);
        assertFalse(
            erc1155ForMinterService.hasRole(
                erc1155ForMinterService.ADMIN(),
                ADMIN
            )
        );
    }

    function testGrantMinter() external {
        assertFalse(
            erc1155ForMinterService.hasRole(
                erc1155ForMinterService.MINTER(),
                ADMIN
            )
        );
        assertTrue(
            erc1155ForMinterService.hasRole(
                erc1155ForMinterService.ADMIN(),
                ADMIN
            )
        );
        vm.prank(ADMIN);
        erc1155ForMinterService.grantMinter(ADMIN);
        assertTrue(
            erc1155ForMinterService.hasRole(
                erc1155ForMinterService.MINTER(),
                ADMIN
            )
        );
    }

    function testRevokeMinter() external {
        assertTrue(
            erc1155ForMinterService.hasRole(
                erc1155ForMinterService.ADMIN(),
                ADMIN
            )
        );
        assertTrue(
            erc1155ForMinterService.hasRole(
                erc1155ForMinterService.MINTER(),
                MINTER
            )
        );
        vm.prank(ADMIN);
        erc1155ForMinterService.revokeMinter(MINTER);
        assertFalse(
            erc1155ForMinterService.hasRole(
                erc1155ForMinterService.MINTER(),
                MINTER
            )
        );
    }

    function testSetUri() external {
        assertTrue(
            erc1155ForMinterService.hasRole(
                erc1155ForMinterService.ADMIN(),
                ADMIN
            )
        );
        vm.prank(ADMIN);
        erc1155ForMinterService.setURI(TEST_URI);
        assertEq(erc1155ForMinterService.uri(0), TEST_URI);
    }

    function testOnlyAdminCanSetUri() external {
        assertFalse(
            erc1155ForMinterService.hasRole(
                erc1155ForMinterService.ADMIN(),
                MINTER
            )
        );
        vm.expectRevert();
        vm.prank(MINTER);
        erc1155ForMinterService.setURI("test");
    }

    function testOnlyAdminCanGrantMinter() external {
        assertFalse(
            erc1155ForMinterService.hasRole(
                erc1155ForMinterService.ADMIN(),
                MINTER
            )
        );
        vm.expectRevert();
        vm.prank(MINTER);
        erc1155ForMinterService.grantMinter(ADMIN);
    }

    function testOnlyAdminCanRevokeMinter() external {
        assertFalse(
            erc1155ForMinterService.hasRole(
                erc1155ForMinterService.ADMIN(),
                MINTER
            )
        );
        vm.expectRevert();
        vm.prank(MINTER);
        erc1155ForMinterService.revokeMinter(MINTER);
    }

    function testOnlyAdminCanGrantAdmin() external {
        assertFalse(
            erc1155ForMinterService.hasRole(
                erc1155ForMinterService.ADMIN(),
                MINTER
            )
        );
        vm.expectRevert();
        vm.prank(MINTER);
        erc1155ForMinterService.grantAdmin(MINTER);
    }

    function testOnlyAdminCanRevokeAdmin() external {
        assertFalse(
            erc1155ForMinterService.hasRole(
                erc1155ForMinterService.ADMIN(),
                MINTER
            )
        );
        assertTrue(
            erc1155ForMinterService.hasRole(
                erc1155ForMinterService.ADMIN(),
                ADMIN
            )
        );
        vm.expectRevert();
        vm.prank(MINTER);
        erc1155ForMinterService.revokeAdmin(ADMIN);
    }

    function testOnlyMinterCanMultiAddressMint() external {
        assertFalse(
            erc1155ForMinterService.hasRole(
                erc1155ForMinterService.MINTER(),
                ADMIN
            )
        );
        address[] memory addresses = new address[](2);
        uint256[] memory ids =  new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        addresses[0] = ADMIN;
        addresses[0] = MINTER;
        ids[0] = 1;
        ids[1] = 1;
        amounts[0] = 1;
        amounts[1] = 1;
        vm.expectRevert();
        vm.prank(ADMIN);
        erc1155ForMinterService.multiAddressMint(addresses, ids, amounts);
    }

    function testOnlyMinterCanMint() external {
        assertFalse(
            erc1155ForMinterService.hasRole(
                erc1155ForMinterService.MINTER(),
                ADMIN
            )
        );
        vm.expectRevert();
        vm.prank(ADMIN);
        erc1155ForMinterService.mint(ADMIN, 1, 1);
    }

        function testMultiAddressMint() external {
        assertTrue(
            erc1155ForMinterService.hasRole(
                erc1155ForMinterService.MINTER(),
                MINTER
            )
        );
        address[] memory addresses = new address[](2);
        uint256[] memory ids =  new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        addresses[0] = ADMIN;
        addresses[1] = MINTER;
        ids[0] = 1;
        ids[1] = 2;
        amounts[0] = 1;
        amounts[1] = 2;
        vm.prank(MINTER);
        erc1155ForMinterService.multiAddressMint(addresses, ids, amounts);

        assertEq(erc1155ForMinterService.balanceOf(ADMIN, 1), 1);
        assertEq(erc1155ForMinterService.balanceOf(MINTER, 2), 2);
    }

    function testMint() external {
        assertTrue(
            erc1155ForMinterService.hasRole(
                erc1155ForMinterService.MINTER(),
                MINTER
            )
        );

        vm.prank(MINTER);
        erc1155ForMinterService.mint(ADMIN, 1, 1);

        assertEq(erc1155ForMinterService.balanceOf(ADMIN, 1), 1);
    }
}
