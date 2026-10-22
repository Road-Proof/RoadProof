// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IRoadProofAuthorization
/// @notice Define la interfaz para consultar autorizaciones de directores técnicos.
interface IRoadProofAuthorization {
    function estaAutorizado(bytes32 tallerId, address directorTecnico) external view returns (bool autorizado);
}
