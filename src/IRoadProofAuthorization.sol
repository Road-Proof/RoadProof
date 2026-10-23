// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IRoadProofAuthorization
/// @notice Defines the interface for querying technical director authorizations.
interface IRoadProofAuthorization {
    function isAuthorized(bytes32 workshopId, address technicalDirector) external view returns (bool authorized);
}
