// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {Erc1155MembershipMint} from "../../src/Erc1155MembershipMint.sol";
import {DeployErc1155MembershipMint} from "../../script/DeployErc1155MembershipMint.s.sol";
import {UsdcMock} from "../mocks/UsdcMock.sol";

contract TestErc1155FMembershipMint is Test {
    Erc1155MembershipMint erc1155MembershipMint;
    UsdcMock usdcMock;
    address USER1 = makeAddr("USER1");
    address USER2 = makeAddr("USER2");
    address ADMIN = makeAddr("ADMIN");
    string TEST_URI = "https://example.com";
    uint256 TEST_TOKEN_PRICE = 50;
    uint256 INITIAL_PAYMENT_TOKEN_BALANCE = 100 * 10 ** 6;
    uint256 TEST_TOKEN_ID = 1;
    uint256 TEST_TOKEN_ID_2 = 2;

    event Erc1155ForMinterService_Mint(address indexed to, uint256 indexed id, uint256 amount);

    function setUp() external {
        DeployErc1155MembershipMint deployErc1155MembershipMint = new DeployErc1155MembershipMint();
        erc1155MembershipMint = deployErc1155MembershipMint.run();
        vm.startPrank(msg.sender);
        erc1155MembershipMint.grantAdmin(ADMIN);
        erc1155MembershipMint.setPriceForTokenId(TEST_TOKEN_PRICE, TEST_TOKEN_ID);
        erc1155MembershipMint.setPriceForTokenId(TEST_TOKEN_PRICE, TEST_TOKEN_ID_2);
        vm.stopPrank();
        usdcMock = UsdcMock(address(erc1155MembershipMint.payment_token_contract()));
        usdcMock.mint(USER1, INITIAL_PAYMENT_TOKEN_BALANCE);
        usdcMock.mint(ADMIN, INITIAL_PAYMENT_TOKEN_BALANCE);
    }

    function testConstructor() external {
        DeployErc1155MembershipMint deployErc1155MembershipMint = new DeployErc1155MembershipMint();
        erc1155MembershipMint = deployErc1155MembershipMint.run();
        (
            ,
            string memory uri,
            address payment_token_contract_address,
            uint256 payment_token_contract_decimals,
            address treasury,,
        ) = deployErc1155MembershipMint.helperConfig().activeNetworkConfig();
        assertEq(erc1155MembershipMint.baseURI(), uri);
        assertEq(address(erc1155MembershipMint.payment_token_contract()), payment_token_contract_address);
        assertEq(erc1155MembershipMint.payment_token_contract_decimals(), payment_token_contract_decimals);
        assertEq(erc1155MembershipMint.treasury(), treasury);
    }

    function testOnlyAdminCanFreeMint() external {
        assertFalse(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), USER1));
        vm.expectRevert();
        vm.prank(USER1);
        erc1155MembershipMint.freeMint(USER1, TEST_TOKEN_ID, 1);
    }

    function testFreeMint() external {
        assertTrue(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), ADMIN));
        vm.prank(ADMIN);
        erc1155MembershipMint.freeMint(USER1, TEST_TOKEN_ID, 1);
        assertEq(erc1155MembershipMint.balanceOf(USER1, TEST_TOKEN_ID), 1);
    }

    function testMintFailsIfNotWhitelisted() external {
        assertFalse(erc1155MembershipMint.tokenIdToWhitelist(TEST_TOKEN_ID, USER1));
        vm.prank(USER1);
        vm.expectRevert();
        
        erc1155MembershipMint.mint(TEST_TOKEN_ID);
        
    }

    function testMintFailsIfNotEnoughAllowance() external {
        vm.prank(ADMIN);
        erc1155MembershipMint.addToWhitelist(TEST_TOKEN_ID, USER1);
        assertTrue(erc1155MembershipMint.tokenIdToWhitelist(TEST_TOKEN_ID, USER1));
        vm.expectRevert();
        vm.prank(USER1);
        erc1155MembershipMint.mint(TEST_TOKEN_ID);
        assertTrue(erc1155MembershipMint.tokenIdToWhitelist(TEST_TOKEN_ID, USER1));
    }

    function testMintFailsIfAlreadyReceivedAToken() external {
        vm.startPrank(ADMIN);
        erc1155MembershipMint.addToWhitelist(TEST_TOKEN_ID, USER1);
        erc1155MembershipMint.freeMint(USER1, TEST_TOKEN_ID, 1);
        vm.stopPrank();
        assertTrue(erc1155MembershipMint.tokenIdToWhitelist(TEST_TOKEN_ID, USER1));
        vm.startPrank(USER1);
        usdcMock.approve(address(erc1155MembershipMint), erc1155MembershipMint.tokenIdToPrice(TEST_TOKEN_ID)*10**erc1155MembershipMint.payment_token_contract_decimals());
        vm.expectRevert();
        erc1155MembershipMint.mint(TEST_TOKEN_ID);
        vm.stopPrank();
        assertTrue(erc1155MembershipMint.tokenIdToWhitelist(TEST_TOKEN_ID, USER1));
    }

    function testSuccessfulMint() external {
        vm.startPrank(ADMIN);
        erc1155MembershipMint.addToWhitelist(TEST_TOKEN_ID, USER1);
        vm.stopPrank();
        assertTrue(erc1155MembershipMint.tokenIdToWhitelist(TEST_TOKEN_ID, USER1));
        assertTrue(erc1155MembershipMint.balanceOf(USER1, TEST_TOKEN_ID) == 0);
        uint256 initial_payment_token_amount_user = usdcMock.balanceOf(USER1);
        uint256 initial_payment_token_amount_treasury = usdcMock.balanceOf(erc1155MembershipMint.treasury());
        vm.startPrank(USER1);
        usdcMock.approve(address(erc1155MembershipMint), erc1155MembershipMint.tokenIdToPrice(TEST_TOKEN_ID)*10**erc1155MembershipMint.payment_token_contract_decimals());
        erc1155MembershipMint.mint(TEST_TOKEN_ID);
        vm.stopPrank();
        assertTrue(erc1155MembershipMint.balanceOf(USER1, TEST_TOKEN_ID) == 1);
        assertFalse(erc1155MembershipMint.tokenIdToWhitelist(TEST_TOKEN_ID, USER1));
        uint256 final_payment_token_amount_user = usdcMock.balanceOf(USER1);
        uint256 final_payment_token_amount_treasury = usdcMock.balanceOf(erc1155MembershipMint.treasury());
        assertEq(final_payment_token_amount_user, initial_payment_token_amount_user - erc1155MembershipMint.tokenIdToPrice(TEST_TOKEN_ID)*10**erc1155MembershipMint.payment_token_contract_decimals());
        assertEq(final_payment_token_amount_treasury, initial_payment_token_amount_treasury + erc1155MembershipMint.tokenIdToPrice(TEST_TOKEN_ID)*10**erc1155MembershipMint.payment_token_contract_decimals());
    }

    //check for soulbound
    function testOnlyAdminCanSafeTransferFrom() external {
        assertFalse(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), USER1));
        assertTrue(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), ADMIN));
        vm.prank(ADMIN);
        erc1155MembershipMint.freeMint(USER1, TEST_TOKEN_ID, 1);
        vm.expectRevert();
        vm.prank(USER1);
        erc1155MembershipMint.safeTransferFrom(USER1, USER2, TEST_TOKEN_ID, 1, "");
    }

    //Club leadership should be able to move tokens
    function testAdminCanSafeBatchTransferFromAnyToken() external {
        assertFalse(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), USER1));
        assertTrue(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), ADMIN));
        uint256[] memory ids = new uint256[](2);
        ids[0] = TEST_TOKEN_ID;
        ids[1] = TEST_TOKEN_ID_2;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;
        vm.startPrank(ADMIN);
        erc1155MembershipMint.freeMint(USER1, TEST_TOKEN_ID, 1);
        erc1155MembershipMint.freeMint(USER1, TEST_TOKEN_ID_2, 1);
        assertTrue(erc1155MembershipMint.balanceOf(USER2, TEST_TOKEN_ID) == 0);
        assertTrue(erc1155MembershipMint.balanceOf(USER2, TEST_TOKEN_ID_2) == 0);
        assertTrue(erc1155MembershipMint.balanceOf(USER1, TEST_TOKEN_ID) == 1);
        assertTrue(erc1155MembershipMint.balanceOf(USER1, TEST_TOKEN_ID_2) == 1);
        erc1155MembershipMint.safeBatchTransferFrom(USER1, USER2, ids, amounts, "");
        vm.stopPrank();
        assertTrue(erc1155MembershipMint.balanceOf(USER2, TEST_TOKEN_ID) == 1);
        assertTrue(erc1155MembershipMint.balanceOf(USER2, TEST_TOKEN_ID_2) == 1);
        assertTrue(erc1155MembershipMint.balanceOf(USER1, TEST_TOKEN_ID) == 0);
        assertTrue(erc1155MembershipMint.balanceOf(USER1, TEST_TOKEN_ID_2) == 0);
    }

    //check for soulbound
    function testOnlyAdminCanSafeBatchTransferFrom() external {
        assertFalse(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), USER1));
        assertTrue(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), ADMIN));
        uint256[] memory ids = new uint256[](2);
        ids[0] = TEST_TOKEN_ID;
        ids[1] = TEST_TOKEN_ID_2;
        uint256[] memory amounts = new uint256[](2);
        ids[0] = 1;
        ids[1] = 1;
        vm.startPrank(ADMIN);
        erc1155MembershipMint.freeMint(USER1, TEST_TOKEN_ID, 1);
        erc1155MembershipMint.freeMint(USER1, TEST_TOKEN_ID_2, 1);
        vm.stopPrank();
        vm.expectRevert();
        vm.prank(USER1);
        erc1155MembershipMint.safeBatchTransferFrom(USER1, USER2, ids, amounts, "");
    }

    //Club leadership should be able to move tokens
    function testAdminCanSafeTransferFromAnyToken() external {
        assertFalse(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), USER1));
        assertTrue(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), ADMIN));
        vm.prank(ADMIN);
        erc1155MembershipMint.freeMint(USER1, TEST_TOKEN_ID, 1);
        assertTrue(erc1155MembershipMint.balanceOf(USER2, TEST_TOKEN_ID) == 0);
        assertTrue(erc1155MembershipMint.balanceOf(USER1, TEST_TOKEN_ID) == 1);
        vm.prank(ADMIN);
        erc1155MembershipMint.safeTransferFrom(USER1, USER2, TEST_TOKEN_ID, 1, "");
        assertTrue(erc1155MembershipMint.balanceOf(USER2, TEST_TOKEN_ID) == 1);
        assertTrue(erc1155MembershipMint.balanceOf(USER1, TEST_TOKEN_ID) == 0);
    }

    function testOnlyAdminCanAddToWhitelist() external {
        assertFalse(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), USER1));
        vm.expectRevert();
        vm.prank(USER1);
        erc1155MembershipMint.addToWhitelist(TEST_TOKEN_ID, USER1);
    }

    function testAddToWhitelist() external {
        assertTrue(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), ADMIN));
        vm.prank(ADMIN);
        erc1155MembershipMint.addToWhitelist(TEST_TOKEN_ID, USER1);
        assertTrue(erc1155MembershipMint.tokenIdToWhitelist(TEST_TOKEN_ID, USER1));
    }

    function testOnlyAdminCanRemoveFromWhitelist() external {
        assertFalse(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), USER1));
        vm.expectRevert();
        vm.prank(USER1);
        erc1155MembershipMint.removeFromWhitelist(TEST_TOKEN_ID, USER1);
    }

    function testRemoveFromWhitelist() external {
        assertTrue(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), ADMIN));
        vm.prank(ADMIN);
        erc1155MembershipMint.addToWhitelist(TEST_TOKEN_ID, USER1);
        assertTrue(erc1155MembershipMint.tokenIdToWhitelist(TEST_TOKEN_ID, USER1));
        vm.prank(ADMIN);
        erc1155MembershipMint.removeFromWhitelist(TEST_TOKEN_ID, USER1);
        assertFalse(erc1155MembershipMint.tokenIdToWhitelist(TEST_TOKEN_ID, USER1));
    }

    function testOnlyAdminCanAddBatchToWhitelist() external {
        assertFalse(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), USER1));
        address[] memory users = new address[](2);
        users[0] = USER1;
        users[1] = USER2;
        vm.expectRevert();
        vm.prank(USER1);
        erc1155MembershipMint.addBatchToWhitelist(TEST_TOKEN_ID, users);
    }

    function testAddBatchToWhitelist() external {
        assertTrue(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), ADMIN));
        address[] memory users = new address[](2);
        users[0] = USER1;
        users[1] = USER2;
        vm.prank(ADMIN);
        erc1155MembershipMint.addBatchToWhitelist(TEST_TOKEN_ID, users);
        assertTrue(erc1155MembershipMint.tokenIdToWhitelist(TEST_TOKEN_ID, USER1));
        assertTrue(erc1155MembershipMint.tokenIdToWhitelist(TEST_TOKEN_ID, USER2));
    }

    function testOnlyAdminCanRemoveBatchFromWhitelist() external {
        assertFalse(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), USER1));
        address[] memory users = new address[](2);
        users[0] = USER1;
        users[1] = USER2;
        vm.expectRevert();
        vm.prank(USER1);
        erc1155MembershipMint.removeBatchFromWhitelist(TEST_TOKEN_ID, users);
    }

    function testRemoveBatchFromWhitelist() external {
        assertTrue(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), ADMIN));
        address[] memory users = new address[](2);
        users[0] = USER1;
        users[1] = USER2;
        vm.prank(ADMIN);
        erc1155MembershipMint.addBatchToWhitelist(TEST_TOKEN_ID, users);
        assertTrue(erc1155MembershipMint.tokenIdToWhitelist(TEST_TOKEN_ID, USER1));
        assertTrue(erc1155MembershipMint.tokenIdToWhitelist(TEST_TOKEN_ID, USER2));
        vm.prank(ADMIN);
        erc1155MembershipMint.removeBatchFromWhitelist(TEST_TOKEN_ID, users);
        assertFalse(erc1155MembershipMint.tokenIdToWhitelist(TEST_TOKEN_ID, USER1));
        assertFalse(erc1155MembershipMint.tokenIdToWhitelist(TEST_TOKEN_ID, USER2));
    }

    function testGrantAdmin() external {
        assertFalse(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), USER1));
        assertTrue(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), ADMIN));
        vm.prank(ADMIN);
        erc1155MembershipMint.grantAdmin(USER1);
        assertTrue(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), USER1));
    }

    function testOnlyAdminCanGrantAdmin() external {
        assertFalse(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), USER1));
        vm.expectRevert();
        vm.prank(USER1);
        erc1155MembershipMint.grantAdmin(USER1);
    }

    function testRevokeAdmin() external {
        assertTrue(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), ADMIN));
        vm.prank(ADMIN);
        erc1155MembershipMint.revokeAdmin(ADMIN);
        assertFalse(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), ADMIN));
    }

    function testOnlyAdminCanRevokeAdmin() external {
        assertFalse(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), USER1));
        assertTrue(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), ADMIN));
        vm.expectRevert();
        vm.prank(USER1);
        erc1155MembershipMint.revokeAdmin(ADMIN);
    }

    function testSetUri() external {
        assertTrue(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), ADMIN));
        vm.prank(ADMIN);
        erc1155MembershipMint.setURI(TEST_URI);
        assertEq(erc1155MembershipMint.baseURI(), TEST_URI);
    }

    function testOnlyAdminCanSetUri() external {
        assertFalse(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), USER1));
        vm.expectRevert();
        vm.prank(USER1);
        erc1155MembershipMint.setURI("test");
    }

    function testSetTreasury() external {
        assertTrue(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), ADMIN));
        vm.prank(ADMIN);
        erc1155MembershipMint.setTreasury(USER1);
        assertEq(erc1155MembershipMint.treasury(), USER1);
    }

    function testOnlyAdminCanSetTreasury() external {
        assertFalse(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), USER1));
        vm.expectRevert();
        vm.prank(USER1);
        erc1155MembershipMint.setTreasury(USER1);
    }

    function testSetPaymentTokenContract() external {
        assertTrue(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), ADMIN));
        vm.prank(ADMIN);
        erc1155MembershipMint.setPaymentTokenContract(USER1);
        assertEq(address(erc1155MembershipMint.payment_token_contract()), USER1);
    }

    function testOnlyAdminCanSetPaymentTokenContract() external {
        assertFalse(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), USER1));
        vm.expectRevert();
        vm.prank(USER1);
        erc1155MembershipMint.setPaymentTokenContract(USER1);
    }

    function testSetPaymentTokenContractDecimals() external {
        assertTrue(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), ADMIN));
        vm.prank(ADMIN);
        erc1155MembershipMint.setPaymentTokenContractDecimals(10);
        assertEq(erc1155MembershipMint.payment_token_contract_decimals(), 10);
    }

    function testOnlyAdminCanSetPaymentTokenContractDecimals() external {
        assertFalse(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), USER1));
        vm.expectRevert();
        vm.prank(USER1);
        erc1155MembershipMint.setPaymentTokenContractDecimals(10);
    }

    function testSetPriceForTokenId() external {
        assertTrue(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), ADMIN));
        vm.startPrank(ADMIN);
        erc1155MembershipMint.setPriceForTokenId(10, 1);
        erc1155MembershipMint.setPriceForTokenId(15, 2);
        vm.stopPrank();
        assertEq(erc1155MembershipMint.tokenIdToPrice(1), 10);
        assertEq(erc1155MembershipMint.tokenIdToPrice(2), 15);
    }

    function testOnlyAdminCanSetPriceForTokenId() external {
        assertFalse(erc1155MembershipMint.hasRole(erc1155MembershipMint.ADMIN(), USER1));
        vm.expectRevert();
        vm.prank(USER1);
        erc1155MembershipMint.setPriceForTokenId(10, 1);
    }
}
