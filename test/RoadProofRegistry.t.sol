// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {RoadProofRegistry} from "../src/RoadProofRegistry.sol";
import {RoadProofAuthorization} from "../src/RoadProofAuthorization.sol";

contract RoadProofRegistryTest is Test {
    RoadProofAuthorization internal authorization;
    RoadProofRegistry internal registry;

    address internal technicalDirector;
    address internal unauthorizedUser;

    bytes32 internal workshopId;
    bytes32 internal inspectionId;
    bytes32 internal reportHash;
    bytes32 internal vehicleRefHash;

    function setUp() public {
        authorization = new RoadProofAuthorization();
        registry = new RoadProofRegistry(address(authorization));

        technicalDirector = makeAddr("technicalDirector");
        unauthorizedUser = makeAddr("unauthorizedUser");

        workshopId = keccak256("WORKSHOP_001");
        inspectionId = keccak256("INSPECTION_001");
        reportHash = keccak256("REPORT_HASH_001");
        vehicleRefHash = keccak256("VEHICLE_001");
    }

    // ---------------------------------------------------------------
    // OWNERSHIP
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

    // ---------------------------------------------------------------
    // INSPECTION REGISTRATION
    // ---------------------------------------------------------------

    function testAuthorizedDirectorCanRegisterInspection() public {
        authorization.authorizeTechnicalDirector(workshopId, technicalDirector);

        vm.prank(technicalDirector);
        registry.registerInspection(
            inspectionId, reportHash, vehicleRefHash, workshopId, RoadProofRegistry.InspectionResult.PASS
        );

        assertTrue(registry.inspectionExists(inspectionId));

        assertTrue(registry.verifyIntegrity(inspectionId, reportHash));
    }

    function testRegistersRejectedResult() public {
        authorization.authorizeTechnicalDirector(workshopId, technicalDirector);

        vm.prank(technicalDirector);
        registry.registerInspection(
            inspectionId, reportHash, vehicleRefHash, workshopId, RoadProofRegistry.InspectionResult.REJECTED
        );

        (,,, RoadProofRegistry.InspectionResult storedResult,) = registry.inspections(inspectionId);

        assertEq(uint256(storedResult), uint256(RoadProofRegistry.InspectionResult.REJECTED));
    }

    function testUnauthorizedDirectorCannotRegisterInspection() public {
        vm.prank(unauthorizedUser);
        vm.expectRevert(RoadProofRegistry.TechnicalDirectorNotAuthorized.selector);

        registry.registerInspection(
            inspectionId, reportHash, vehicleRefHash, workshopId, RoadProofRegistry.InspectionResult.PASS
        );
    }

    function testCannotRegisterDuplicateInspection() public {
        authorization.authorizeTechnicalDirector(workshopId, technicalDirector);

        // First call: the inspection is registered successfully.
        vm.prank(technicalDirector);
        registry.registerInspection(
            inspectionId, reportHash, vehicleRefHash, workshopId, RoadProofRegistry.InspectionResult.PASS
        );

        // Second call: must fail because the identifier already exists.
        vm.prank(technicalDirector);
        vm.expectRevert(RoadProofRegistry.DuplicateInspection.selector);

        registry.registerInspection(
            inspectionId, reportHash, vehicleRefHash, workshopId, RoadProofRegistry.InspectionResult.REJECTED
        );
    }

    function testRevokedDirectorCannotRegisterInspection() public {
        authorization.authorizeTechnicalDirector(workshopId, technicalDirector);

        authorization.revokeTechnicalDirector(workshopId, technicalDirector);

        vm.prank(technicalDirector);
        vm.expectRevert(RoadProofRegistry.TechnicalDirectorNotAuthorized.selector);

        registry.registerInspection(
            inspectionId, reportHash, vehicleRefHash, workshopId, RoadProofRegistry.InspectionResult.PASS
        );
    }

    function testCannotRegisterWithInvalidInspectionId() public {
        authorization.authorizeTechnicalDirector(workshopId, technicalDirector);

        vm.prank(technicalDirector);
        vm.expectRevert(RoadProofRegistry.InvalidIdentifier.selector);

        registry.registerInspection(
            bytes32(0), reportHash, vehicleRefHash, workshopId, RoadProofRegistry.InspectionResult.PASS
        );
    }

    function testCannotRegisterWithInvalidWorkshop() public {
        authorization.authorizeTechnicalDirector(workshopId, technicalDirector);

        vm.prank(technicalDirector);
        vm.expectRevert(RoadProofRegistry.InvalidIdentifier.selector);

        registry.registerInspection(
            inspectionId, reportHash, vehicleRefHash, bytes32(0), RoadProofRegistry.InspectionResult.PASS
        );
    }

    function testCannotRegisterWithZeroReportHash() public {
        authorization.authorizeTechnicalDirector(workshopId, technicalDirector);

        vm.prank(technicalDirector);
        vm.expectRevert(RoadProofRegistry.InvalidHash.selector);

        registry.registerInspection(
            inspectionId, bytes32(0), vehicleRefHash, workshopId, RoadProofRegistry.InspectionResult.PASS
        );
    }

    function testCannotRegisterWithZeroVehicleHash() public {
        authorization.authorizeTechnicalDirector(workshopId, technicalDirector);

        vm.prank(technicalDirector);
        vm.expectRevert(RoadProofRegistry.InvalidHash.selector);

        registry.registerInspection(
            inspectionId, reportHash, bytes32(0), workshopId, RoadProofRegistry.InspectionResult.PASS
        );
    }

    function testEmitsEventWhenRegisteringInspection() public {
        authorization.authorizeTechnicalDirector(workshopId, technicalDirector);
        vm.warp(1_700_000_000);

        vm.expectEmit(true, true, true, true, address(registry));

        emit RoadProofRegistry.InspectionRegistered(
            inspectionId,
            workshopId,
            vehicleRefHash,
            technicalDirector,
            RoadProofRegistry.InspectionResult.PASS,
            reportHash,
            block.timestamp
        );

        vm.prank(technicalDirector);
        registry.registerInspection(
            inspectionId, reportHash, vehicleRefHash, workshopId, RoadProofRegistry.InspectionResult.PASS
        );
    }

    // ---------------------------------------------------------------
    // REPORT INTEGRITY
    // ---------------------------------------------------------------

    function testDetectsIncorrectReportHash() public {
        authorization.authorizeTechnicalDirector(workshopId, technicalDirector);

        vm.prank(technicalDirector);
        registry.registerInspection(
            inspectionId, reportHash, vehicleRefHash, workshopId, RoadProofRegistry.InspectionResult.PASS
        );

        bytes32 incorrectHash = keccak256("INCORRECT_HASH");

        assertFalse(registry.verifyIntegrity(inspectionId, incorrectHash));
    }

    function testCannotVerifyNonexistentInspection() public {
        vm.expectRevert(RoadProofRegistry.InspectionNotFound.selector);

        registry.verifyIntegrity(keccak256("NONEXISTENT_INSPECTION"), reportHash);
    }

    function testCannotVerifyWithZeroHash() public {
        authorization.authorizeTechnicalDirector(workshopId, technicalDirector);

        vm.prank(technicalDirector);
        registry.registerInspection(
            inspectionId, reportHash, vehicleRefHash, workshopId, RoadProofRegistry.InspectionResult.PASS
        );

        vm.expectRevert(RoadProofRegistry.InvalidHash.selector);

        registry.verifyIntegrity(inspectionId, bytes32(0));
    }

    // ---------------------------------------------------------------
    // CONTRACT INTEGRATION
    // ---------------------------------------------------------------

    function testRegistryQueriesExternalAuthorization() public {
        authorization.authorizeTechnicalDirector(workshopId, technicalDirector);

        assertEq(address(registry.authorizationContract()), address(authorization));

        vm.prank(technicalDirector);
        registry.registerInspection(
            inspectionId, reportHash, vehicleRefHash, workshopId, RoadProofRegistry.InspectionResult.CONDITIONAL
        );

        (
            bytes32 storedReportHash,
            bytes32 storedVehicleRefHash,
            bytes32 storedWorkshopId,
            RoadProofRegistry.InspectionResult storedResult,
            address storedDirector
        ) = registry.inspections(inspectionId);

        assertEq(storedReportHash, reportHash);
        assertEq(storedVehicleRefHash, vehicleRefHash);
        assertEq(storedWorkshopId, workshopId);
        assertEq(uint256(storedResult), uint256(RoadProofRegistry.InspectionResult.CONDITIONAL));
        assertEq(storedDirector, technicalDirector);
    }

    function testCannotCreateRegistryWithZeroAuthorizationAddress() public {
        vm.expectRevert(RoadProofRegistry.InvalidAuthorizationContract.selector);

        new RoadProofRegistry(address(0));
    }

    function testCannotCreateRegistryWithAddressWithoutCode() public {
        address addressWithoutContract = makeAddr("addressWithoutContract");

        vm.expectRevert(RoadProofRegistry.InvalidAuthorizationContract.selector);

        new RoadProofRegistry(addressWithoutContract);
    }

    function testConstructorRejectsIncompatibleContract() public {
        ContractWithoutAuthorization incompatibleContract = new ContractWithoutAuthorization();

        vm.expectRevert(RoadProofRegistry.InvalidAuthorizationContract.selector);

        new RoadProofRegistry(address(incompatibleContract));
    }
}

contract ContractWithoutAuthorization {
    function otherFunction() external pure returns (bool) {
        return true;
    }
}
