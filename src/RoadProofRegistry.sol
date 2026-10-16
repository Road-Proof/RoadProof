
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title RoadProofRegistry
/// @author RoadProof
/// @notice Registra revisiones técnicas vehiculares y permite verificar
///         la integridad de sus informes mediante hashes.
/// @dev Los informes completos se almacenan fuera de la blockchain.
///      El contrato conserva sus hashes y los datos necesarios para
///      verificar su trazabilidad e integridad.
contract RoadProofRegistry is Ownable{
    // ---------------------------------------------------------------
    // TIPOS DE DATOS
    // ---------------------------------------------------------------

    /// @notice Resultados posibles de una revisión técnica.
    enum Resultado {
        APTO,
        CONDICIONAL,
        RECHAZADO
    }

    /// @notice Información registrada de una revisión técnica.
    struct Revision {
        bytes32 informeHash;
        bytes32 vehiculoRefHash;
        bytes32 tallerId;
        Resultado resultado;
        address directorTecnico;
        uint256 timestamp;
    }

    // ---------------------------------------------------------------
    // ESTADO
    // ---------------------------------------------------------------

    /// @notice Información de cada revisión, identificada por su ID.
    mapping(bytes32 => Revision) public revisiones;

    /// @notice Indica si una revisión ya fue registrada.
    mapping(bytes32 => bool) public revisionExiste;

    /// @notice Indica qué directores técnicos están autorizados por taller.
    /// @dev tallerId => director técnico => autorizado.
    mapping(bytes32 => mapping(address => bool))
        public directorTecnicoPorTaller;

    // ---------------------------------------------------------------
    // ERRORES PERSONALIZADOS
    // ---------------------------------------------------------------

    error DireccionInvalida();
    error IdentificadorInvalido();
    error HashInvalido();
    error DirectorTecnicoNoAutorizado();
    error RevisionDuplicada();
    error RevisionInexistente();
    error DirectorYaAutorizado();
    error DirectorNoAutorizado();

    // ---------------------------------------------------------------
    // EVENTOS
    // ---------------------------------------------------------------

    /// @notice Se emite cuando se autoriza un director técnico.
    event DirectorTecnicoAutorizado(
        bytes32 indexed tallerId,
        address indexed directorTecnico,
        address indexed administrador
    );

    /// @notice Se emite cuando se revoca una autorización.
    event DirectorTecnicoRevocado(
        bytes32 indexed tallerId,
        address indexed directorTecnico,
        address indexed administrador
    );

    /// @notice Se emite al registrar una revisión técnica.
    event RevisionRegistrada(
        bytes32 indexed revisionId,
        bytes32 indexed tallerId,
        bytes32 vehiculoRefHash,
        address indexed directorTecnico,
        Resultado resultado,
        bytes32 informeHash,
        uint256 timestamp
    );


    // ---------------------------------------------------------------
    // CONSTRUCTOR
    // ---------------------------------------------------------------

    /// @notice Inicializa el contrato y asigna el administrador.
    /// @dev La dirección que despliega el contrato será el administrador
    ///      inicial. Esta versión no contempla transferencia del rol.

    constructor() Ownable(msg.sender) {}

    // ---------------------------------------------------------------
    // ADMINISTRACIÓN DE DIRECTORES TÉCNICOS
    // ---------------------------------------------------------------

    /// @notice Autoriza un director técnico para un taller.
    /// @param tallerId Identificador único del taller.
    /// @param directorTecnico Dirección del director técnico.
    function autorizarDirectorTecnico(
        bytes32 tallerId,
        address directorTecnico
    ) external onlyOwner {
        if (tallerId == bytes32(0)) {
            revert IdentificadorInvalido();
        }

        if (directorTecnico == address(0)) {
            revert DireccionInvalida();
        }

        if (directorTecnicoPorTaller[tallerId][directorTecnico]) {
            revert DirectorYaAutorizado();
        }

        directorTecnicoPorTaller[tallerId][directorTecnico] = true;

        emit DirectorTecnicoAutorizado(
            tallerId,
            directorTecnico,
            msg.sender
        );
    }

    /// @notice Revoca la autorización de un director técnico para un taller.
    /// @param tallerId Identificador del taller.
    /// @param directorTecnico Dirección del director técnico.
    function revocarDirectorTecnico(
        bytes32 tallerId,
        address directorTecnico
    ) external onlyOwner {
        if (tallerId == bytes32(0)) {
            revert IdentificadorInvalido();
        }

        if (directorTecnico == address(0)) {
            revert DireccionInvalida();
        }

        if (!directorTecnicoPorTaller[tallerId][directorTecnico]) {
            revert DirectorNoAutorizado();
        }

        directorTecnicoPorTaller[tallerId][directorTecnico] = false;

        emit DirectorTecnicoRevocado(
            tallerId,
            directorTecnico,
            msg.sender
        );
    }

    // ---------------------------------------------------------------
    // REGISTRO DE REVISIONES
    // ---------------------------------------------------------------

    /// @notice Registra una revisión técnica vehicular.
    /// @dev Solo puede registrar revisiones un director autorizado
    ///      para el taller indicado. Los registros son inmutables:
    ///      no existe una función para modificarlos o eliminarlos.
    /// @param revisionId Identificador único de la revisión.
    /// @param informeHash Hash del informe de revisión.
    /// @param vehiculoRefHash Hash de una referencia del vehículo.
    /// @param tallerId Identificador del taller que realizó la revisión.
    /// @param resultado Resultado de la revisión técnica.
    function registrarRevision(
        bytes32 revisionId,
        bytes32 informeHash,
        bytes32 vehiculoRefHash,
        bytes32 tallerId,
        Resultado resultado
    ) external {
        if (revisionId == bytes32(0) || tallerId == bytes32(0)) {
            revert IdentificadorInvalido();
        }

        if (
            informeHash == bytes32(0) ||
            vehiculoRefHash == bytes32(0)
        ) {
            revert HashInvalido();
        }

        if (revisionExiste[revisionId]) {
            revert RevisionDuplicada();
        }

        if (!directorTecnicoPorTaller[tallerId][msg.sender]) {
            revert DirectorTecnicoNoAutorizado();
        }

        // Checks-Effects-Interactions:
        // se validan las condiciones antes de modificar el estado.
        revisionExiste[revisionId] = true;

        revisiones[revisionId] = Revision({
            informeHash: informeHash,
            vehiculoRefHash: vehiculoRefHash,
            tallerId: tallerId,
            resultado: resultado,
            directorTecnico: msg.sender,
            timestamp: block.timestamp
        });

        emit RevisionRegistrada(
            revisionId,
            tallerId,
            vehiculoRefHash,
            msg.sender,
            resultado,
            informeHash,
            block.timestamp
        );
    }

    // ---------------------------------------------------------------
    // VERIFICACIÓN DE INTEGRIDAD
    // ---------------------------------------------------------------

    /// @notice Comprueba si un hash coincide con el informe registrado.
    /// @dev No demuestra que el informe sea verdadero; solo comprueba
    ///      que su hash coincide con el que fue registrado.
    /// @param revisionId Identificador de la revisión.
    /// @param hashCalculado Hash calculado a partir del informe a verificar.
    /// @return integro True si el hash coincide con el registrado.
    function verificarIntegridad(
        bytes32 revisionId,
        bytes32 hashCalculado
    ) external view returns (bool integro) {
        if (!revisionExiste[revisionId]) {
            revert RevisionInexistente();
        }

        if (hashCalculado == bytes32(0)) {
            revert HashInvalido();
        }

        return revisiones[revisionId].informeHash == hashCalculado;
    }
}
