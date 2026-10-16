
 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {RoadProofRegistry} from "../src/RoadProofRegistry.sol";

contract RoadProofRegistryTest is Test {
    RoadProofRegistry internal registry;

    address internal directorTecnico;
    address internal usuarioNoAutorizado;

    bytes32 internal tallerId;
    bytes32 internal revisionId;
    bytes32 internal informeHash;
    bytes32 internal vehiculoRefHash;

    function setUp() public {
        registry = new RoadProofRegistry();

        directorTecnico = makeAddr("directorTecnico");
        usuarioNoAutorizado = makeAddr("usuarioNoAutorizado");

        tallerId = keccak256("TALLER_001");
        revisionId = keccak256("REVISION_001");
        informeHash = keccak256("HASH_INFORME_001");
        vehiculoRefHash = keccak256("VEHICULO_001");
    }

    function testPropietarioPuedeAutorizarDirector() public {
        registry.autorizarDirectorTecnico(
            tallerId,
            directorTecnico
        );

        assertTrue(
            registry.directorTecnicoPorTaller(
                tallerId,
                directorTecnico
            )
        );
    }

    function testUsuarioNoAutorizadoNoPuedeAutorizarDirector()
        public
    {
        vm.prank(usuarioNoAutorizado);
        vm.expectRevert();

        registry.autorizarDirectorTecnico(
            tallerId,
            directorTecnico
        );
    }

    function testDirectorAutorizadoPuedeRegistrarRevision()
        public
    {
        registry.autorizarDirectorTecnico(
            tallerId,
            directorTecnico
        );

        vm.prank(directorTecnico);
        registry.registrarRevision(
            revisionId,
            informeHash,
            vehiculoRefHash,
            tallerId,
            RoadProofRegistry.Resultado.APTO
        );

        assertTrue(registry.revisionExiste(revisionId));

        assertTrue(
            registry.verificarIntegridad(
                revisionId,
                informeHash
            )
        );
    }

    function testDirectorNoAutorizadoNoPuedeRegistrarRevision()
        public
    {
        vm.prank(usuarioNoAutorizado);
        vm.expectRevert(
            RoadProofRegistry.DirectorTecnicoNoAutorizado.selector
        );

        registry.registrarRevision(
            revisionId,
            informeHash,
            vehiculoRefHash,
            tallerId,
            RoadProofRegistry.Resultado.APTO
        );
    }

    function testNoPermiteRegistrarRevisionDuplicada() public {
        registry.autorizarDirectorTecnico(
            tallerId,
            directorTecnico
        );

        vm.startPrank(directorTecnico);

        registry.registrarRevision(
            revisionId,
            informeHash,
            vehiculoRefHash,
            tallerId,
            RoadProofRegistry.Resultado.APTO
        );

        vm.expectRevert(
            RoadProofRegistry.RevisionDuplicada.selector
        );

        registry.registrarRevision(
            revisionId,
            informeHash,
            vehiculoRefHash,
            tallerId,
            RoadProofRegistry.Resultado.RECHAZADO
        );

        vm.stopPrank();
    }

    function testDetectaHashDeInformeIncorrecto() public {
        registry.autorizarDirectorTecnico(
            tallerId,
            directorTecnico
        );

        vm.prank(directorTecnico);
        registry.registrarRevision(
            revisionId,
            informeHash,
            vehiculoRefHash,
            tallerId,
            RoadProofRegistry.Resultado.APTO
        );

        bytes32 hashIncorrecto = keccak256("HASH_INCORRECTO");

        assertFalse(
            registry.verificarIntegridad(
                revisionId,
                hashIncorrecto
            )
        );
    }

    function testNoPermiteVerificarRevisionInexistente()
        public
    {
        vm.expectRevert(
            RoadProofRegistry.RevisionInexistente.selector
        );

        registry.verificarIntegridad(
            keccak256("REVISION_INEXISTENTE"),
            informeHash
        );
    }

    function testDirectorRevocadoNoPuedeRegistrarRevision()
        public
    {
        registry.autorizarDirectorTecnico(
            tallerId,
            directorTecnico
        );

        registry.revocarDirectorTecnico(
            tallerId,
            directorTecnico
        );

        vm.prank(directorTecnico);
        vm.expectRevert(
            RoadProofRegistry.DirectorTecnicoNoAutorizado.selector
        );

        registry.registrarRevision(
            revisionId,
            informeHash,
            vehiculoRefHash,
            tallerId,
            RoadProofRegistry.Resultado.APTO
        );
    }
}
