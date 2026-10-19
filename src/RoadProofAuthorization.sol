// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title RoadProofAuthorization
/// @author RoadProof
/// @notice Administra las autorizaciones de directores técnicos por taller.
/// @dev Solo el propietario puede autorizar o revocar directores técnicos.
///      Los permisos pueden consultarse desde otros contratos.
contract RoadProofAuthorization is Ownable {
    // ---------------------------------------------------------------
    // ESTADO
    // ---------------------------------------------------------------

    /// @notice Indica qué directores técnicos están autorizados por taller.
    /// @dev tallerId => director técnico => autorizado.
    mapping(bytes32 => mapping(address => bool))
        public directorTecnicoPorTaller;

    // ---------------------------------------------------------------
    // ERRORES PERSONALIZADOS
    // ---------------------------------------------------------------

    /// @notice El identificador del taller no puede ser cero.
    error IdentificadorInvalido();

    /// @notice La dirección del director técnico no puede ser cero.
    error DireccionInvalida();

    /// @notice El director técnico ya está autorizado para el taller.
    error DirectorYaAutorizado();

    /// @notice El director técnico no está autorizado para el taller.
    error DirectorNoAutorizado();

    // ---------------------------------------------------------------
    // EVENTOS
    // ---------------------------------------------------------------

    /// @notice Se emite al autorizar un director técnico.
    /// @param tallerId Identificador del taller.
    /// @param directorTecnico Dirección del director autorizado.
    /// @param administrador Dirección que ejecutó la autorización.
    event DirectorTecnicoAutorizado(
        bytes32 indexed tallerId,
        address indexed directorTecnico,
        address indexed administrador
    );

    /// @notice Se emite al revocar un director técnico.
    /// @param tallerId Identificador del taller.
    /// @param directorTecnico Dirección del director revocado.
    /// @param administrador Dirección que ejecutó la revocación.
    event DirectorTecnicoRevocado(
        bytes32 indexed tallerId,
        address indexed directorTecnico,
        address indexed administrador
    );

    // ---------------------------------------------------------------
    // CONSTRUCTOR
    // ---------------------------------------------------------------

    /// @notice Inicializa el contrato.
    /// @dev El desplegador se convierte en propietario inicial.
    constructor() Ownable(msg.sender) {}

    // ---------------------------------------------------------------
    // ADMINISTRACIÓN DE AUTORIZACIONES
    // ---------------------------------------------------------------

    /// @notice Autoriza a un director técnico para un taller.
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
    /// @param tallerId Identificador único del taller.
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
    // CONSULTA DE AUTORIZACIONES
    // ---------------------------------------------------------------

    /// @notice Consulta si un director técnico está autorizado para un taller.
    /// @param tallerId Identificador único del taller.
    /// @param directorTecnico Dirección del director técnico.
    /// @return autorizado True si el director está autorizado.
    function estaAutorizado(
        bytes32 tallerId,
        address directorTecnico
    ) external view returns (bool autorizado) {
        if (tallerId == bytes32(0)) {
            revert IdentificadorInvalido();
        }

        if (directorTecnico == address(0)) {
            revert DireccionInvalida();
        }

        return directorTecnicoPorTaller[tallerId][directorTecnico];
    }
}
