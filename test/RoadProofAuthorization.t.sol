// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {RoadProofAuthorization} from "../src/RoadProofAuthorization.sol";

contract RoadProofAuthorizationTest is Test {
    RoadProofAuthorization internal authorization;

    address internal technicalDirector;
    address internal unauthorizedUser;

    bytes32 internal workshopId;

    function setUp() public {
        authorization = new RoadProofAuthorization();

        technicalDirector = makeAddr("technicalDirector");
        unauthorizedUser = makeAddr("unauthorizedUser");

        workshopId = keccak256("WORKSHOP_001");
    }

    // ---------------------------------------------------------------
    // OWNERSHIP MANAGEMENT
    // ---------------------------------------------------------------

    function testPendingOwnerCannotManageDirectors() public {
        address newOwner = makeAddr("newOwner");

        authorization.transferOwnership(newOwner);

        assertEq(authorization.owner(), address(this));
        assertEq(authorization.pendingOwner(), newOwner);

        vm.prank(newOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, newOwner));
        authorization.authorizeTechnicalDirector(workshopId, technicalDirector);

        authorization.authorizeTechnicalDirector(workshopId, technicalDirector);
        assertTrue(authorization.isAuthorized(workshopId, technicalDirector));

        vm.prank(newOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, newOwner));
        authorization.revokeTechnicalDirector(workshopId, technicalDirector);

        authorization.revokeTechnicalDirector(workshopId, technicalDirector);
        assertFalse(authorization.isAuthorized(workshopId, technicalDirector));
    }

    function testAcceptedOwnerCanManageDirectors() public {
        address newOwner = makeAddr("newOwner");
        authorization.authorizeTechnicalDirector(workshopId, technicalDirector);
        authorization.transferOwnership(newOwner);

        vm.prank(newOwner);
        authorization.acceptOwnership();

        assertEq(authorization.owner(), newOwner);
        assertEq(authorization.pendingOwner(), address(0));
        assertTrue(authorization.isAuthorized(workshopId, technicalDirector));

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this)));
        authorization.revokeTechnicalDirector(workshopId, technicalDirector);

        vm.prank(newOwner);
        authorization.revokeTechnicalDirector(workshopId, technicalDirector);
        assertFalse(authorization.isAuthorized(workshopId, technicalDirector));

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this)));
        authorization.authorizeTechnicalDirector(workshopId, technicalDirector);

        vm.prank(newOwner);
        authorization.authorizeTechnicalDirector(workshopId, technicalDirector);
        assertTrue(authorization.isAuthorized(workshopId, technicalDirector));
    }

    function testOnlyOwnerCanStartOwnershipTransfer() public {
        vm.prank(unauthorizedUser);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, unauthorizedUser));
        authorization.transferOwnership(unauthorizedUser);

        assertEq(authorization.owner(), address(this));
        assertEq(authorization.pendingOwner(), address(0));
    }

    function testOnlyPendingOwnerCanAcceptOwnership() public {
        address newOwner = makeAddr("newOwner");
        authorization.transferOwnership(newOwner);

        vm.prank(unauthorizedUser);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, unauthorizedUser));
        authorization.acceptOwnership();

        assertEq(authorization.owner(), address(this));
        assertEq(authorization.pendingOwner(), newOwner);
    }

    function testOwnerCanReplacePendingOwner() public {
        address firstNominee = makeAddr("firstNominee");
        address replacement = makeAddr("replacement");
        authorization.transferOwnership(firstNominee);
        authorization.transferOwnership(replacement);

        vm.prank(firstNominee);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, firstNominee));
        authorization.acceptOwnership();

        vm.prank(replacement);
        authorization.acceptOwnership();

        assertEq(authorization.owner(), replacement);
        assertEq(authorization.pendingOwner(), address(0));
    }

    function testOwnerCanCancelPendingTransferWithoutRenouncingOwnership() public {
        address newOwner = makeAddr("newOwner");
        authorization.transferOwnership(newOwner);
        authorization.transferOwnership(address(0));

        assertEq(authorization.owner(), address(this));
        assertEq(authorization.pendingOwner(), address(0));

        vm.prank(newOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, newOwner));
        authorization.acceptOwnership();

        authorization.authorizeTechnicalDirector(workshopId, technicalDirector);
        assertTrue(authorization.isAuthorized(workshopId, technicalDirector));
    }

    function testOwnerCannotRenounceOwnershipAndCanStillManageDirectors() public {
        authorization.authorizeTechnicalDirector(workshopId, technicalDirector);

        vm.expectRevert(RoadProofAuthorization.OwnershipRenunciationDisabled.selector);
        authorization.renounceOwnership();

        assertEq(authorization.owner(), address(this));
        assertTrue(authorization.isAuthorized(workshopId, technicalDirector));

        authorization.revokeTechnicalDirector(workshopId, technicalDirector);
        assertFalse(authorization.isAuthorized(workshopId, technicalDirector));
    }

    function testRenunciationRemainsDisabledDuringAndAfterOwnershipTransfer() public {
        address newOwner = makeAddr("newOwner");
        authorization.transferOwnership(newOwner);

        vm.expectRevert(RoadProofAuthorization.OwnershipRenunciationDisabled.selector);
        authorization.renounceOwnership();

        assertEq(authorization.owner(), address(this));
        assertEq(authorization.pendingOwner(), newOwner);

        vm.prank(newOwner);
        authorization.acceptOwnership();

        vm.prank(newOwner);
        vm.expectRevert(RoadProofAuthorization.OwnershipRenunciationDisabled.selector);
        authorization.renounceOwnership();

        assertEq(authorization.owner(), newOwner);
        assertEq(authorization.pendingOwner(), address(0));
    }

    function testUnauthorizedUserCannotRenounceOwnership() public {
        vm.prank(unauthorizedUser);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, unauthorizedUser));
        authorization.renounceOwnership();

        assertEq(authorization.owner(), address(this));
    }

    // ---------------------------------------------------------------
    // AUTHORIZATIONS
    // ---------------------------------------------------------------

    function testOwnerCanAuthorizeDirector() public {
        authorization.authorizeTechnicalDirector(workshopId, technicalDirector);

        assertTrue(authorization.isAuthorized(workshopId, technicalDirector));
    }

    function testUnauthorizedUserCannotAuthorizeDirector() public {
        vm.prank(unauthorizedUser);
        vm.expectRevert();

        authorization.authorizeTechnicalDirector(workshopId, technicalDirector);
    }

    function testCannotAuthorizeWithInvalidWorkshop() public {
        vm.expectRevert(RoadProofAuthorization.InvalidIdentifier.selector);

        authorization.authorizeTechnicalDirector(bytes32(0), technicalDirector);
    }

    function testCannotAuthorizeZeroAddress() public {
        vm.expectRevert(RoadProofAuthorization.InvalidAddress.selector);

        authorization.authorizeTechnicalDirector(workshopId, address(0));
    }

    function testCannotAuthorizeDirectorTwice() public {
        authorization.authorizeTechnicalDirector(workshopId, technicalDirector);

        vm.expectRevert(RoadProofAuthorization.DirectorAlreadyAuthorized.selector);

        authorization.authorizeTechnicalDirector(workshopId, technicalDirector);
    }

    function testCannotRevokeUnauthorizedDirector() public {
        vm.expectRevert(RoadProofAuthorization.DirectorNotAuthorized.selector);

        authorization.revokeTechnicalDirector(workshopId, technicalDirector);
    }

    function testEmitsEventWhenAuthorizingDirector() public {
        vm.expectEmit(true, true, true, true, address(authorization));

        emit RoadProofAuthorization.TechnicalDirectorAuthorized(workshopId, technicalDirector, address(this));

        authorization.authorizeTechnicalDirector(workshopId, technicalDirector);
    }

    function testEmitsEventWhenRevokingDirector() public {
        authorization.authorizeTechnicalDirector(workshopId, technicalDirector);

        vm.expectEmit(true, true, true, true, address(authorization));

        emit RoadProofAuthorization.TechnicalDirectorRevoked(workshopId, technicalDirector, address(this));

        authorization.revokeTechnicalDirector(workshopId, technicalDirector);
    }

    function testUnauthorizedDirectorQueryReturnsFalse() public view {
        assertFalse(authorization.isAuthorized(workshopId, technicalDirector));
    }

    function testQueryWithInvalidWorkshopReverts() public {
        vm.expectRevert(RoadProofAuthorization.InvalidIdentifier.selector);

        authorization.isAuthorized(bytes32(0), technicalDirector);
    }

    function testQueryWithZeroAddressReverts() public {
        vm.expectRevert(RoadProofAuthorization.InvalidAddress.selector);

        authorization.isAuthorized(workshopId, address(0));
    }
}
