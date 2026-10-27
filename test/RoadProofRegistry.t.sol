// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
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
