// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {RoadProofAuthorization} from "../src/RoadProofAuthorization.sol";
import {RoadProofRegistry} from "../src/RoadProofRegistry.sol";

contract InteractRoadProof is Script {
    function run() external {
        // Direcciones obtenidas en el despliegue local de Anvil.
        RoadProofAuthorization authorization = RoadProofAuthorization(0x5FbDB2315678afecb367f032d93F642f64180aa3);

        RoadProofRegistry registry = RoadProofRegistry(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);

        // Datos de prueba.
        bytes32 tallerId = keccak256("TALLER-001");
        bytes32 revisionId = keccak256("REVISION-001");
        bytes32 informeHash = keccak256("INFORME-001");
        bytes32 vehiculoRefHash = keccak256("VEHICULO-001");

        // La cuenta que despliega es el propietario de autorización.
        address directorTecnico = vm.addr(vm.envUint("DIRECTOR_PK"));

        vm.startBroadcast();

        // 1. Autorizar al director técnico para el taller.
        authorization.autorizarDirectorTecnico(tallerId, directorTecnico);

        // 2. Registrar una revisión desde la cuenta autorizada.
        vm.stopBroadcast();
        vm.startBroadcast(vm.envUint("DIRECTOR_PK"));

        registry.registrarRevision(revisionId, informeHash, vehiculoRefHash, tallerId, RoadProofRegistry.Resultado.APTO);

        vm.stopBroadcast();

        // 3. Comprobar el registro y la integridad.
        require(registry.revisionExiste(revisionId), "La revision no existe");
        require(registry.verificarIntegridad(revisionId, informeHash), "El hash del informe no coincide");

        // 4. Confirmar que la referencia del vehiculo tambien se guardo.
        (bytes32 informeGuardado, bytes32 vehiculoGuardado,,,,) = registry.revisiones(revisionId);

        require(informeGuardado == informeHash, "Informe incorrecto");
        require(vehiculoGuardado == vehiculoRefHash, "Vehiculo incorrecto");
    }
}
