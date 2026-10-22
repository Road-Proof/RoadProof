// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {RoadProofAuthorization} from "../src/RoadProofAuthorization.sol";
import {RoadProofRegistry} from "../src/RoadProofRegistry.sol";

contract InteractRoadProof is Script {
    function run() external {
        RoadProofAuthorization authorization = RoadProofAuthorization(0x5FbDB2315678afecb367f032d93F642f64180aa3);

        RoadProofRegistry registry = RoadProofRegistry(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);

        bytes32 tallerId = keccak256("TALLER-001");
        bytes32 revisionId = keccak256("REVISION-001");
        bytes32 informeHash = keccak256("INFORME-001");
        bytes32 vehiculoRefHash = keccak256("VEHICULO-001");

        address directorTecnico = vm.addr(vm.envUint("DIRECTOR_PK"));

        // El propietario autoriza al director técnico.
        vm.startBroadcast();
        authorization.autorizarDirectorTecnico(tallerId, directorTecnico);
        vm.stopBroadcast();

        // El director técnico registra la revisión.
        vm.startBroadcast(vm.envUint("DIRECTOR_PK"));
        registry.registrarRevision(revisionId, informeHash, vehiculoRefHash, tallerId, RoadProofRegistry.Resultado.APTO);
        vm.stopBroadcast();

        // Verificar el registro y sus datos.
        require(registry.revisionExiste(revisionId), "La revision no existe");
        require(registry.verificarIntegridad(revisionId, informeHash), "El hash del informe no coincide");

        (bytes32 informeGuardado, bytes32 vehiculoGuardado,,,,) = registry.revisiones(revisionId);

        require(informeGuardado == informeHash, "Informe incorrecto");
        require(vehiculoGuardado == vehiculoRefHash, "Vehiculo incorrecto");
    }
}
