// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {RoadProofAuthorization} from "../src/RoadProofAuthorization.sol";
import {RoadProofRegistry} from "../src/RoadProofRegistry.sol";

contract InteractRoadProof is Script {
    function run() external {
        // Addresses obtained from the local Anvil deployment.
        RoadProofAuthorization authorization = RoadProofAuthorization(0x5FbDB2315678afecb367f032d93F642f64180aa3);

        RoadProofRegistry registry = RoadProofRegistry(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);

        // Test data.
        bytes32 workshopId = keccak256("WORKSHOP-001");
        bytes32 inspectionId = keccak256("INSPECTION-001");
        bytes32 reportHash = keccak256("REPORT-001");
        bytes32 vehicleRefHash = keccak256("VEHICLE-001");

        // The deploying account owns the authorization contract.
        address technicalDirector = vm.addr(vm.envUint("DIRECTOR_PK"));

        vm.startBroadcast();

        // 1. Authorize the technical director for the workshop.
        authorization.authorizeTechnicalDirector(workshopId, technicalDirector);

        // 2. Register an inspection from the authorized account.
        vm.stopBroadcast();
        vm.startBroadcast(vm.envUint("DIRECTOR_PK"));

        registry.registerInspection(
            inspectionId, reportHash, vehicleRefHash, workshopId, RoadProofRegistry.InspectionResult.PASS
        );

        vm.stopBroadcast();

        // 3. Check the registration and integrity.
        require(registry.inspectionExists(inspectionId), "The inspection does not exist");
        require(registry.verifyIntegrity(inspectionId, reportHash), "The report hash does not match");

        // 4. Confirm that the vehicle reference was also stored.
        (bytes32 storedReportHash, bytes32 storedVehicleRefHash,,,) = registry.inspections(inspectionId);

        require(storedReportHash == reportHash, "Incorrect report");
        require(storedVehicleRefHash == vehicleRefHash, "Incorrect vehicle");
    }
}
