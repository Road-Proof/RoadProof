// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IRoadProofAuthorization} from "./IRoadProofAuthorization.sol";

/// @title RoadProofRegistry
/// @author RoadProof
/// @notice Registers vehicle inspections and verifies the integrity
///         of their reports using hashes.
/// @dev Full reports are stored off-chain.
///      Authorizations are queried through RoadProofAuthorization.

contract RoadProofRegistry {
    // ---------------------------------------------------------------
    // DATA TYPES
    // ---------------------------------------------------------------

    /// @notice Possible vehicle inspection results.

    enum InspectionResult {
        PASS,
        CONDITIONAL,
        REJECTED
    }

    /// @notice Recorded information for a vehicle inspection.
    /// @dev The registration timestamp is available in the InspectionRegistered event.

    struct Inspection {
        bytes32 reportHash;
        bytes32 vehicleRefHash;
        bytes32 workshopId;
        InspectionResult result;
        address technicalDirector;
    }

    // ---------------------------------------------------------------
    // STATE
    // ---------------------------------------------------------------

    /// @notice External contract that manages authorizations.
    IRoadProofAuthorization public immutable authorizationContract;

    /// @notice Information for each inspection, identified by its ID.
    mapping(bytes32 => Inspection) public inspections;

    /// @notice Indicates whether an inspection has already been registered.
    mapping(bytes32 => bool) public inspectionExists;

    // ---------------------------------------------------------------
    // CUSTOM ERRORS
    // ---------------------------------------------------------------

    /// @notice The inspection or workshop identifier is invalid.
    error InvalidIdentifier();

    /// @notice One of the required hashes is zero.
    error InvalidHash();

    /// @notice The technical director is not authorized for the workshop.
    error TechnicalDirectorNotAuthorized();

    /// @notice The inspection has already been registered.
    error DuplicateInspection();

    /// @notice The requested inspection does not exist.
    error InspectionNotFound();

    /// @notice The authorization contract address is invalid.
    error InvalidAuthorizationContract();

    // ---------------------------------------------------------------
    // EVENTS
    // ---------------------------------------------------------------

    /// @notice Emitted when a vehicle inspection is registered.
    /// @param inspectionId Unique inspection identifier.
    /// @param workshopId Workshop identifier.
    /// @param vehicleRefHash Hash of the vehicle reference.
    /// @param technicalDirector Address of the technical director who registered the inspection.
    /// @param result Inspection result.
    /// @param reportHash Hash of the registered report.
    /// @param timestamp Timestamp of registration on the blockchain.

    event InspectionRegistered(
        bytes32 indexed inspectionId,
        bytes32 indexed workshopId,
        bytes32 vehicleRefHash,
        address indexed technicalDirector,
        InspectionResult result,
        bytes32 reportHash,
        uint256 timestamp
    );

    // ---------------------------------------------------------------
    // CONSTRUCTOR
    // ---------------------------------------------------------------

    /// @notice Initializes the registry and sets the authorization contract.
    /// @param authorizationAddress Address of RoadProofAuthorization.
    /// @dev The authorization address must belong to a deployed contract.

    constructor(address authorizationAddress) {
        if (authorizationAddress == address(0) || authorizationAddress.code.length == 0) {
            revert InvalidAuthorizationContract();
        }

        IRoadProofAuthorization authorization = IRoadProofAuthorization(authorizationAddress);

        // Checks that the contract responds correctly to the interface.
        try authorization.isAuthorized(bytes32(uint256(1)), address(this)) returns (
            bool
        ) {
        // The call returned a valid boolean.
        }
        catch {
            revert InvalidAuthorizationContract();
        }

        authorizationContract = authorization;
    }

    // ---------------------------------------------------------------
    // INSPECTION REGISTRATION
    // ---------------------------------------------------------------

    /// @notice Registers a vehicle inspection.
    /// @dev Queries RoadProofAuthorization to verify that the caller
    ///      is authorized for the specified workshop.
    ///      Records cannot be modified or deleted.
    /// @param inspectionId Unique inspection identifier.
    /// @param reportHash Hash of the inspection report.
    /// @param vehicleRefHash Hash of a vehicle reference.
    /// @param workshopId Workshop identifier.
    /// @param result Vehicle inspection result.

    function registerInspection(
        bytes32 inspectionId,
        bytes32 reportHash,
        bytes32 vehicleRefHash,
        bytes32 workshopId,
        InspectionResult result
    ) external {
        if (inspectionId == bytes32(0) || workshopId == bytes32(0)) {
            revert InvalidIdentifier();
        }

        if (reportHash == bytes32(0) || vehicleRefHash == bytes32(0)) {
            revert InvalidHash();
        }

        if (inspectionExists[inspectionId]) {
            revert DuplicateInspection();
        }

        // Contract interaction: query the authorization contract.
        bool authorized = authorizationContract.isAuthorized(workshopId, msg.sender);

        if (!authorized) {
            revert TechnicalDirectorNotAuthorized();
        }

        // Effects: store the inspection after validating the conditions.
        inspectionExists[inspectionId] = true;

        inspections[inspectionId] = Inspection({
            reportHash: reportHash,
            vehicleRefHash: vehicleRefHash,
            workshopId: workshopId,
            result: result,
            technicalDirector: msg.sender
        });

        emit InspectionRegistered(
            inspectionId, workshopId, vehicleRefHash, msg.sender, result, reportHash, block.timestamp
        );
    }

    // ---------------------------------------------------------------
    // INTEGRITY VERIFICATION
    // ---------------------------------------------------------------

    /// @notice Checks whether a hash matches the registered report.
    /// @dev A match does not prove that the report is truthful;
    ///      it proves that its hash matches the hash stored on-chain.
    /// @param inspectionId Inspection identifier.
    /// @param computedHash Computed hash of the report being verified.
    /// @return intact True if the hash matches the registered hash.

    function verifyIntegrity(bytes32 inspectionId, bytes32 computedHash) external view returns (bool intact) {
        if (!inspectionExists[inspectionId]) {
            revert InspectionNotFound();
        }

        if (computedHash == bytes32(0)) {
            revert InvalidHash();
        }

        return inspections[inspectionId].reportHash == computedHash;
    }
}
