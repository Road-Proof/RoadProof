// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {RoadProofAuthorization} from "../src/RoadProofAuthorization.sol";
import {RoadProofRegistry} from "../src/RoadProofRegistry.sol";

/// @notice Deploys both contracts using the broadcaster selected through the Forge CLI.
contract DeployRoadProof is Script {
    function run() external returns (RoadProofAuthorization authorization, RoadProofRegistry registry) {
        vm.startBroadcast();

        authorization = new RoadProofAuthorization();
        registry = new RoadProofRegistry(address(authorization));

        vm.stopBroadcast();

        console2.log("RoadProofAuthorization:", address(authorization));
        console2.log("RoadProofRegistry:", address(registry));
        console2.log("Administrator:", authorization.owner());
    }
}
