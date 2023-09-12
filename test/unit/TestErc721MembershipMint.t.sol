// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {Erc721MembershipMint} from "../../src/Erc721MembershipMint.sol";
import {DeployErc721MembershipMint} from "../../script/DeployErc721MembershipMint.s.sol";
import {UsdcMock} from "../mocks/UsdcMock.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract TestErc1155FMembershipMint is Test {
    Erc721MembershipMint erc721MembershipMint;
    HelperConfig helperConfig;
    UsdcMock usdcMock;
    address USER1 = makeAddr("USER1");
    address USER2 = makeAddr("USER2");
    address ADMIN = makeAddr("ADMIN");
    address NFT_MOVEMENT = makeAddr("NFT_MOVEMENT");
    address NFT_MANAGEMENT = makeAddr("NFT_MANAGEMENT");
    string TEST_URI = "https://example.com";
    uint256 TEST_TOKEN_PRICE = 50;
    uint256 INITIAL_PAYMENT_TOKEN_BALANCE = 100 * 10 ** 6;
    uint256 TEST_TOKEN_ID = 1;
    uint256 TEST_TOKEN_ID_2 = 2;

    event Erc1155ForMinterService_Mint(address indexed to, uint256 indexed id, uint256 amount);


    modifier nftMinted() {
        assertTrue(erc721MembershipMint.hasRole(erc721MembershipMint.NFT_MOVEMENT(), NFT_MOVEMENT));
        vm.prank(NFT_MOVEMENT);
        erc721MembershipMint.freeMint(USER1, TEST_TOKEN_ID);
        _;
    }


    function setUp() external {
        DeployErc721MembershipMint deployErc721MembershipMint = new DeployErc721MembershipMint();
        erc721MembershipMint = deployErc721MembershipMint.run();
        helperConfig = deployErc721MembershipMint.helperConfig();
        vm.startPrank(msg.sender);
        erc721MembershipMint.grantAdmin(ADMIN);
        erc721MembershipMint.grantNftManagement(NFT_MANAGEMENT);
        erc721MembershipMint.grantNftMovement(NFT_MOVEMENT);
        erc721MembershipMint.setPrice(TEST_TOKEN_PRICE);
        vm.stopPrank();
        usdcMock = UsdcMock(address(erc721MembershipMint.paymentTokenContract()));
        usdcMock.mint(USER1, INITIAL_PAYMENT_TOKEN_BALANCE);
        usdcMock.mint(ADMIN, INITIAL_PAYMENT_TOKEN_BALANCE);
    }

    function testConstructor() external {
        (
            ,
            string memory uri,
            address paymentTokenContractAddress,
            uint256 paymentTokenContractDecimals,
            address treasury,
            string memory defaultImageUrl,
            string memory defaultMemberRole,
            address backupAdmin
        ) = helperConfig.activeNetworkConfig();
        assertEq(erc721MembershipMint.baseUri(), uri);
        assertEq(address(erc721MembershipMint.paymentTokenContract()), paymentTokenContractAddress);
        assertEq(erc721MembershipMint.paymentTokenContractDecimals(), paymentTokenContractDecimals);
        assertEq(erc721MembershipMint.treasury(), treasury);
        assertEq(erc721MembershipMint.defaultImageUrl(), defaultImageUrl);
        assertEq(erc721MembershipMint.defaultMemberRole(), defaultMemberRole);
        assertEq(erc721MembershipMint.backupAdmin(), backupAdmin);
    }

    function testOnlyNftMovementCanFreeMint() external {
        assertFalse(erc721MembershipMint.hasRole(erc721MembershipMint.NFT_MOVEMENT(), USER1));
        vm.expectRevert();
        vm.prank(USER1);
        erc721MembershipMint.freeMint(USER1, TEST_TOKEN_ID);
    }

    function testFreeMint() external {
        assertTrue(erc721MembershipMint.hasRole(erc721MembershipMint.NFT_MOVEMENT(), NFT_MOVEMENT));
        vm.prank(NFT_MOVEMENT);
        erc721MembershipMint.freeMint(USER1, TEST_TOKEN_ID);
        assertEq(erc721MembershipMint.balanceOf(USER1), 1);
        assertTrue(erc721MembershipMint.ownerOf(TEST_TOKEN_ID) == USER1);
    }

    function testMintFailsIfNotAllowlisted() external {
        assertEq(erc721MembershipMint.allowlistWithId(USER1), 0);
        vm.prank(USER1);
        vm.expectRevert();
        
        erc721MembershipMint.mint();
        
    }

    function testMintFailsIfNotEnoughAllowance() external {
        vm.prank(NFT_MANAGEMENT);
        erc721MembershipMint.addToAllowlist(USER1, TEST_TOKEN_ID);
        assertEq(erc721MembershipMint.allowlistWithId(USER1), TEST_TOKEN_ID);
        vm.expectRevert();
        vm.prank(USER1);
        erc721MembershipMint.mint();
        assertEq(erc721MembershipMint.allowlistWithId(USER1), TEST_TOKEN_ID);
    }

    function testSuccessfulMint() external {
        vm.startPrank(NFT_MANAGEMENT);
        erc721MembershipMint.addToAllowlist(USER1, TEST_TOKEN_ID);
        vm.stopPrank();
        assertEq(erc721MembershipMint.allowlistWithId(USER1), TEST_TOKEN_ID);
        uint256 initial_payment_token_amount_user = usdcMock.balanceOf(USER1);
        uint256 initial_payment_token_amount_treasury = usdcMock.balanceOf(erc721MembershipMint.treasury());
        vm.startPrank(USER1);
        usdcMock.approve(address(erc721MembershipMint), erc721MembershipMint.price()*10**erc721MembershipMint.paymentTokenContractDecimals());
        erc721MembershipMint.mint();
        vm.stopPrank();
        assertEq(erc721MembershipMint.balanceOf(USER1), 1);
        assertTrue(erc721MembershipMint.ownerOf(TEST_TOKEN_ID) == USER1);
        assertEq(erc721MembershipMint.allowlistWithId(USER1), 0);
        uint256 final_payment_token_amount_user = usdcMock.balanceOf(USER1);
        uint256 final_payment_token_amount_treasury = usdcMock.balanceOf(erc721MembershipMint.treasury());
        assertEq(final_payment_token_amount_user, initial_payment_token_amount_user - erc721MembershipMint.price()*10**erc721MembershipMint.paymentTokenContractDecimals());
        assertEq(final_payment_token_amount_treasury, initial_payment_token_amount_treasury + erc721MembershipMint.price()*10**erc721MembershipMint.paymentTokenContractDecimals());
    }

    //check for soulbound
    function testOnlyNftMovementCanTransfer() external {
        assertFalse(erc721MembershipMint.hasRole(erc721MembershipMint.NFT_MOVEMENT(), USER1));
        assertTrue(erc721MembershipMint.hasRole(erc721MembershipMint.NFT_MOVEMENT(), NFT_MOVEMENT));
        vm.prank(NFT_MOVEMENT);
        erc721MembershipMint.freeMint(USER1, TEST_TOKEN_ID);
        vm.expectRevert();
        vm.prank(USER1);
        erc721MembershipMint.safeTransferFrom(USER1, USER2, TEST_TOKEN_ID, "");
        vm.expectRevert();
        vm.prank(USER1);
        erc721MembershipMint.safeTransferFrom(USER1, USER2, TEST_TOKEN_ID);
        vm.expectRevert();
        vm.prank(USER1);
        erc721MembershipMint.transferFrom(USER1, USER2, TEST_TOKEN_ID);
    }


    //Club leadership should be able to move tokens
    function testNftMovementCanSafeTransferFromAnyToken() external {
        assertFalse(erc721MembershipMint.hasRole(erc721MembershipMint.NFT_MOVEMENT(), USER1));
        assertTrue(erc721MembershipMint.hasRole(erc721MembershipMint.NFT_MOVEMENT(), NFT_MOVEMENT));
        vm.prank(NFT_MOVEMENT);
        erc721MembershipMint.freeMint(USER1, TEST_TOKEN_ID);
        assertTrue(erc721MembershipMint.balanceOf(USER2) == 0);
        assertTrue(erc721MembershipMint.balanceOf(USER1) == 1);
        vm.prank(NFT_MOVEMENT);
        erc721MembershipMint.safeTransferFrom(USER1, USER2, TEST_TOKEN_ID);
        assertTrue(erc721MembershipMint.balanceOf(USER2) == 1);
        assertTrue(erc721MembershipMint.balanceOf(USER1) == 0);
    }

    function testOnlyNftManagementCanAddToAllowlist() external {
        assertFalse(erc721MembershipMint.hasRole(erc721MembershipMint.NFT_MANAGEMENT(), USER1));
        vm.expectRevert();
        vm.prank(USER1);
        erc721MembershipMint.addToAllowlist(USER1, TEST_TOKEN_ID);
    }

    function testAddToAllowlist() external {
        assertTrue(erc721MembershipMint.hasRole(erc721MembershipMint.NFT_MANAGEMENT(), NFT_MANAGEMENT));
        vm.prank(NFT_MANAGEMENT);
        erc721MembershipMint.addToAllowlist(USER1, TEST_TOKEN_ID);
        assertEq(erc721MembershipMint.allowlistWithId(USER1), TEST_TOKEN_ID);
    }

    function testOnlyNftManagementCanRemoveFromAllowlist() external {
        assertFalse(erc721MembershipMint.hasRole(erc721MembershipMint.NFT_MANAGEMENT(), USER1));
        vm.expectRevert();
        vm.prank(USER1);
        erc721MembershipMint.removeFromAllowlist(USER1);
    }

    function testRemoveFromAllowlist() external {
        assertTrue(erc721MembershipMint.hasRole(erc721MembershipMint.NFT_MANAGEMENT(), NFT_MANAGEMENT));
        vm.prank(NFT_MANAGEMENT);
        erc721MembershipMint.addToAllowlist(USER1, TEST_TOKEN_ID);
        assertEq(erc721MembershipMint.allowlistWithId(USER1), TEST_TOKEN_ID);
        vm.prank(NFT_MANAGEMENT);
        erc721MembershipMint.removeFromAllowlist(USER1);
        assertEq(erc721MembershipMint.allowlistWithId(USER1), 0);
    }

    function testOnlyNftManagementCanAddBatchToAllowlist() external {
        assertFalse(erc721MembershipMint.hasRole(erc721MembershipMint.NFT_MANAGEMENT(), USER1));
        address[] memory users = new address[](2);
        users[0] = USER1;
        users[1] = USER2;
        uint256[] memory ids = new uint256[](2);
        ids[0] = TEST_TOKEN_ID;
        ids[1] = TEST_TOKEN_ID_2;
        vm.expectRevert();
        vm.prank(USER1);
        erc721MembershipMint.addBatchToAllowlist(users, ids);
    }

    function testAddBatchToAllowlist() external {
        assertTrue(erc721MembershipMint.hasRole(erc721MembershipMint.NFT_MANAGEMENT(), NFT_MANAGEMENT));
        address[] memory users = new address[](2);
        users[0] = USER1;
        users[1] = USER2;
        uint256[] memory ids = new uint256[](2);
        ids[0] = TEST_TOKEN_ID;
        ids[1] = TEST_TOKEN_ID_2;
        vm.prank(NFT_MANAGEMENT);
        erc721MembershipMint.addBatchToAllowlist(users, ids);
        assertEq(erc721MembershipMint.allowlistWithId(USER1), TEST_TOKEN_ID);
        assertEq(erc721MembershipMint.allowlistWithId(USER2), TEST_TOKEN_ID_2);

    }

    function testOnlyNftManagementCanRemoveBatchFromAllowlist() external {
        assertFalse(erc721MembershipMint.hasRole(erc721MembershipMint.NFT_MANAGEMENT(), USER1));
        address[] memory users = new address[](2);
        users[0] = USER1;
        users[1] = USER2;
        vm.expectRevert();
        vm.prank(USER1);
        erc721MembershipMint.removeBatchFromAllowlist(users);
    }

    function testRemoveBatchFromAllowlist() external {
        assertTrue(erc721MembershipMint.hasRole(erc721MembershipMint.NFT_MANAGEMENT(), NFT_MANAGEMENT));
        address[] memory users = new address[](2);
        users[0] = USER1;
        users[1] = USER2;
        uint256[] memory ids = new uint256[](2);
        ids[0] = TEST_TOKEN_ID;
        ids[1] = TEST_TOKEN_ID_2;
        vm.prank(NFT_MANAGEMENT);
        erc721MembershipMint.addBatchToAllowlist(users, ids);
        assertEq(erc721MembershipMint.allowlistWithId(USER1), TEST_TOKEN_ID);
        assertEq(erc721MembershipMint.allowlistWithId(USER2), TEST_TOKEN_ID_2);
        vm.prank(NFT_MANAGEMENT);
        erc721MembershipMint.removeBatchFromAllowlist(users);
        assertEq(erc721MembershipMint.allowlistWithId(USER1), 0);
        assertEq(erc721MembershipMint.allowlistWithId(USER2), 0);
    }

    function testGrantAdmin() external {
        assertFalse(erc721MembershipMint.hasRole(erc721MembershipMint.ADMIN(), USER1));
        assertTrue(erc721MembershipMint.hasRole(erc721MembershipMint.ADMIN(), ADMIN));
        vm.prank(ADMIN);
        erc721MembershipMint.grantAdmin(USER1);
        assertTrue(erc721MembershipMint.hasRole(erc721MembershipMint.ADMIN(), USER1));
    }
   
    function testGrantAdminByDefaultAdmin() external {
        (,,,,,,,address backupAdmin) = helperConfig.activeNetworkConfig();
        assertFalse(erc721MembershipMint.hasRole(erc721MembershipMint.ADMIN(), USER1));
        assertFalse(erc721MembershipMint.hasRole(erc721MembershipMint.ADMIN(), backupAdmin));
        vm.prank(backupAdmin);
        erc721MembershipMint.grantAdmin(USER1);
        assertTrue(erc721MembershipMint.hasRole(erc721MembershipMint.ADMIN(), USER1));
    }

    function testOnlyAdminCanGrantAdmin() external {
        assertFalse(erc721MembershipMint.hasRole(erc721MembershipMint.ADMIN(), USER1));
        vm.expectRevert();
        vm.prank(USER1);
        erc721MembershipMint.grantAdmin(USER1);
    }

    function testRevokeAdmin() external {
        assertTrue(erc721MembershipMint.hasRole(erc721MembershipMint.ADMIN(), ADMIN));
        vm.prank(ADMIN);
        erc721MembershipMint.revokeAdmin(ADMIN);
        assertFalse(erc721MembershipMint.hasRole(erc721MembershipMint.ADMIN(), ADMIN));
    }

    function testOnlyAdminCanRevokeAdmin() external {
        assertFalse(erc721MembershipMint.hasRole(erc721MembershipMint.ADMIN(), USER1));
        assertTrue(erc721MembershipMint.hasRole(erc721MembershipMint.ADMIN(), ADMIN));
        vm.expectRevert();
        vm.prank(USER1);
        erc721MembershipMint.revokeAdmin(ADMIN);
    }

    function testGrantNftManagement() external {
        assertFalse(erc721MembershipMint.hasRole(erc721MembershipMint.NFT_MANAGEMENT(), USER1));
        assertTrue(erc721MembershipMint.hasRole(erc721MembershipMint.ADMIN(), ADMIN));
        vm.prank(ADMIN);
        erc721MembershipMint.grantNftManagement(USER1);
        assertTrue(erc721MembershipMint.hasRole(erc721MembershipMint.NFT_MANAGEMENT(), USER1));
    }

    function testOnlyAdminCanGrantNftManagement() external {
        assertFalse(erc721MembershipMint.hasRole(erc721MembershipMint.ADMIN(), USER1));
        vm.expectRevert();
        vm.prank(USER1);
        erc721MembershipMint.grantNftManagement(USER1);
    }

    function testRevokeNftManagement() external {
        assertTrue(erc721MembershipMint.hasRole(erc721MembershipMint.NFT_MANAGEMENT(), NFT_MANAGEMENT));
        vm.prank(ADMIN);
        erc721MembershipMint.revokeNftManagement(NFT_MANAGEMENT);
        assertFalse(erc721MembershipMint.hasRole(erc721MembershipMint.NFT_MANAGEMENT(), NFT_MANAGEMENT));
    }

    function testOnlyAdminCanRevokeNftManagement() external {
        assertFalse(erc721MembershipMint.hasRole(erc721MembershipMint.ADMIN(), USER1));
        assertTrue(erc721MembershipMint.hasRole(erc721MembershipMint.NFT_MANAGEMENT(), NFT_MANAGEMENT));
        vm.expectRevert();
        vm.prank(USER1);
        erc721MembershipMint.revokeNftManagement(ADMIN);
    }

    function testGrantNftMovement() external {
        assertFalse(erc721MembershipMint.hasRole(erc721MembershipMint.NFT_MOVEMENT(), USER1));
        assertTrue(erc721MembershipMint.hasRole(erc721MembershipMint.ADMIN(), ADMIN));
        vm.prank(ADMIN);
        erc721MembershipMint.grantNftMovement(USER1);
        assertTrue(erc721MembershipMint.hasRole(erc721MembershipMint.NFT_MOVEMENT(), USER1));
    }

    function testOnlyAdminCanGrantNftMovement() external {
        assertFalse(erc721MembershipMint.hasRole(erc721MembershipMint.NFT_MOVEMENT(), USER1));
        vm.expectRevert();
        vm.prank(USER1);
        erc721MembershipMint.grantNftMovement(USER1);
    }

    function testRevokeNftMovement() external {
        assertTrue(erc721MembershipMint.hasRole(erc721MembershipMint.NFT_MOVEMENT(), NFT_MOVEMENT));
        vm.prank(ADMIN);
        erc721MembershipMint.revokeNftMovement(NFT_MOVEMENT);
        assertFalse(erc721MembershipMint.hasRole(erc721MembershipMint.NFT_MOVEMENT(), NFT_MOVEMENT));
    }

    function testOnlyAdminCanRevokeNftMovement() external {
        assertFalse(erc721MembershipMint.hasRole(erc721MembershipMint.ADMIN(), USER1));
        assertTrue(erc721MembershipMint.hasRole(erc721MembershipMint.NFT_MOVEMENT(), NFT_MOVEMENT));
        vm.expectRevert();
        vm.prank(USER1);
        erc721MembershipMint.revokeNftMovement(ADMIN);
    }

    function testSetTreasury() external {
        assertTrue(erc721MembershipMint.hasRole(erc721MembershipMint.ADMIN(), ADMIN));
        vm.prank(ADMIN);
        erc721MembershipMint.setTreasury(USER1);
        assertEq(erc721MembershipMint.treasury(), USER1);
    }

    function testOnlyAdminCanSetTreasury() external {
        assertFalse(erc721MembershipMint.hasRole(erc721MembershipMint.ADMIN(), USER1));
        vm.expectRevert();
        vm.prank(USER1);
        erc721MembershipMint.setTreasury(USER1);
    }

    function testSetPaymentTokenContract() external {
        assertTrue(erc721MembershipMint.hasRole(erc721MembershipMint.ADMIN(), ADMIN));
        vm.prank(ADMIN);
        erc721MembershipMint.setPaymentTokenContractAndDecimals(USER1, 10);
        assertEq(address(erc721MembershipMint.paymentTokenContract()), USER1);
        assertEq(erc721MembershipMint.paymentTokenContractDecimals(), 10);
    }

    function testOnlyAdminCanSetPaymentTokenContractAndDecimals() external {
        assertFalse(erc721MembershipMint.hasRole(erc721MembershipMint.ADMIN(), USER1));
        vm.expectRevert();
        vm.prank(USER1);
        erc721MembershipMint.setPaymentTokenContractAndDecimals(USER1, 10);
    }

    function testSetPriceForTokenId() external {
        assertTrue(erc721MembershipMint.hasRole(erc721MembershipMint.ADMIN(), ADMIN));
        vm.startPrank(ADMIN);
        erc721MembershipMint.setPrice(10);
        vm.stopPrank();
        assertEq(erc721MembershipMint.price(), 10);

    }

    function testOnlyAdminCanSetPriceForTokenId() external {
        assertFalse(erc721MembershipMint.hasRole(erc721MembershipMint.ADMIN(), USER1));
        vm.expectRevert();
        vm.prank(USER1);
        erc721MembershipMint.setPrice(10);
    }

    function testDefaultTokenURI() external nftMinted{
        string memory DEFAULT_URI = "data:application/json;base64,eyJuYW1lIjogIlByZXR6ZWxEQU8gTWVtYmVyc2hpcCBDYXJkIDIwMjMgIzEiLCJkZXNjcmlwdGlvbiI6ICJQcmV0emVsREFPIGUuVi4gTWVtYmVyc2hpcCBDYXJkIGZvciB0aGUgeWVhciAyMDIzLCBvbmUgcGVyIGFjdGl2ZSBhbmQgdmVyaWZpZWQgbWVtYmVyLiBNZW1iZXJzaGlwIENhcmQgTkZUIGlzIHVzZWQgYXMgYSBnb3Zlcm5hbmNlIHRva2VuIGZvciB0aGUgREFPLiBUaGUgdG9rZW4gaXMgc291bGJvdW5kLiIsImltYWdlIjogImlwZnM6Ly9RbWRGMWE3WTVkWFlQVW9jcGlYNnV5RjNvWk1KQjkzOUcxZVZVZFBuS0NCRHdNIiwidG9rZW5faWQiOiAxLCJleHRlcm5hbF91cmwiOiJodHRwczovL3ByZXR6ZWxkYW8uY29tLyIsImF0dHJpYnV0ZXMiOlt7InRyYWl0X3R5cGUiOiAiRWRpdGlvbiIsInZhbHVlIjogIjIwMjMifSwgeyJrZXkiOiJUeXBlIiwidHJhaXRfdHlwZSI6IlR5cGUiLCJ2YWx1ZSI6IkdvdmVybmFuY2UgVG9rZW4ifSx7ImRpc3BsYXlfdHlwZSI6ICJkYXRlIiwidHJhaXRfdHlwZSI6IlZhbGlkIHVudGlsIiwidmFsdWUiOjE3MDQwNjM1OTl9LHsidHJhaXRfdHlwZSI6ICJNZW1iZXIgUm9sZSIsInZhbHVlIjogIk1lbWJlciJ9XX0=";

        assertEq(DEFAULT_URI, erc721MembershipMint.tokenURI(TEST_TOKEN_ID));
    }

    function testOnlyNftManagementCanSetMemberRole() external nftMinted{
        assertFalse(erc721MembershipMint.hasRole(erc721MembershipMint.NFT_MANAGEMENT(), USER1));
        vm.expectRevert();
        vm.prank(USER1);
        erc721MembershipMint.setMemberRole(TEST_TOKEN_ID, "BOARD");
    }

    function testSetMemberRole() external nftMinted{
        assertTrue(erc721MembershipMint.hasRole(erc721MembershipMint.NFT_MANAGEMENT(), NFT_MANAGEMENT));
        vm.prank(NFT_MANAGEMENT);
        erc721MembershipMint.setMemberRole(TEST_TOKEN_ID, "BOARD");
        assertEq(erc721MembershipMint.getMemberRole(TEST_TOKEN_ID), "BOARD");
    }

    function testGetDefaultMemberRole() external nftMinted {
        assertEq(erc721MembershipMint.getMemberRole(TEST_TOKEN_ID), erc721MembershipMint.defaultMemberRole());
    }

    function testOnlyNftManagementCanSetImageUrl() external nftMinted{
        assertFalse(erc721MembershipMint.hasRole(erc721MembershipMint.NFT_MANAGEMENT(), USER1));
        vm.expectRevert();
        vm.prank(USER1);
        erc721MembershipMint.setImageUrl(TEST_TOKEN_ID, "https://test.url");
    }

    function testSetImageUrl() external nftMinted{
        assertTrue(erc721MembershipMint.hasRole(erc721MembershipMint.NFT_MANAGEMENT(), NFT_MANAGEMENT));
        vm.prank(NFT_MANAGEMENT);
        erc721MembershipMint.setImageUrl(TEST_TOKEN_ID, "https://test.url");
        assertEq(erc721MembershipMint.getImageUrl(TEST_TOKEN_ID), "https://test.url");
    }

    function testGetDefaultImageUrl() external nftMinted {
        assertEq(erc721MembershipMint.getImageUrl(TEST_TOKEN_ID), erc721MembershipMint.defaultImageUrl());
    }

    function testApproveReverts() external nftMinted {
        vm.expectRevert();
        vm.prank(USER1);
        erc721MembershipMint.approve(USER2, TEST_TOKEN_ID);
    }
}
