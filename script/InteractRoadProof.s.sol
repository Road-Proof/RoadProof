// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {RoadProofAuthorization} from "../src/RoadProofAuthorization.sol";
import {RoadProofRegistry} from "../src/RoadProofRegistry.sol";

contract InteractRoadProof is Script {
    function run() external {
        RoadProofAuthorization authorization = RoadProofAuthorization(0x5FbDB2315678afecb367f032d93F642f64180aa3);

        RoadProofRegistry registry = RoadProofRegistry(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);

        bytes32 workshopId = keccak256("WORKSHOP-001");
        bytes32 inspectionId = keccak256("INSPECTION-001");
        bytes32 reportHash = keccak256("REPORT-001");
        bytes32 vehicleRefHash = keccak256("VEHICLE-001");

        address technicalDirector = vm.addr(vm.envUint("DIRECTOR_PK"));

        // The owner authorizes the technical director.
        vm.startBroadcast();
        authorization.authorizeTechnicalDirector(workshopId, technicalDirector);
        vm.stopBroadcast();

        // The technical director registers the inspection.
        vm.startBroadcast(vm.envUint("DIRECTOR_PK"));
        registry.registerInspection(
            inspectionId, reportHash, vehicleRefHash, workshopId, RoadProofRegistry.InspectionResult.PASS
        );
        vm.stopBroadcast();

        // Verify the registration and its data.
        require(registry.inspectionExists(inspectionId), "The inspection does not exist");
        require(registry.verifyIntegrity(inspectionId, reportHash), "The report hash does not match");

        (bytes32 storedReportHash, bytes32 storedVehicleRefHash,,,) = registry.inspections(inspectionId);

        require(storedReportHash == reportHash, "Incorrect report");
        require(storedVehicleRefHash == vehicleRefHash, "Incorrect vehicle");
    }
}
