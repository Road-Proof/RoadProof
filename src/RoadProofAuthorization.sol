// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable, Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IRoadProofAuthorization} from "./IRoadProofAuthorization.sol";

/// @title RoadProofAuthorization
/// @author RoadProof
/// @notice Manages technical director authorizations for each workshop.
/// @dev Only the owner can authorize or revoke technical directors.
///      Ownership transfers require acceptance by the pending owner.
///      Ownership renunciation is disabled to preserve permission management.
///      Other contracts can query these permissions.
contract RoadProofAuthorization is Ownable2Step, IRoadProofAuthorization {
    // ---------------------------------------------------------------
    // STATE
    // ---------------------------------------------------------------

    /// @notice Indicates which technical directors are authorized for each workshop.
    /// @dev workshopId => technical director => authorized.
    /// @return True if the supplied technical director is authorized for the supplied workshop.
    mapping(bytes32 => mapping(address => bool)) public authorizedDirectorsByWorkshop;

    // ---------------------------------------------------------------
    // CUSTOM ERRORS
    // ---------------------------------------------------------------

    /// @notice The workshop identifier cannot be zero.
    error InvalidIdentifier();

    /// @notice The technical director address cannot be zero.
    error InvalidAddress();

    /// @notice The technical director is already authorized for the workshop.
    error DirectorAlreadyAuthorized();

    /// @notice The technical director is not authorized for the workshop.
    error DirectorNotAuthorized();

    /// @notice Ownership cannot be renounced because director permissions require an administrator.
    error OwnershipRenunciationDisabled();

    // ---------------------------------------------------------------
    // EVENTS
    // ---------------------------------------------------------------

    /// @notice Emitted when a technical director is authorized.
    /// @param workshopId Workshop identifier.
    /// @param technicalDirector Address of the authorized director.
    /// @param administrator Address that authorized the director.
    event TechnicalDirectorAuthorized(
        bytes32 indexed workshopId, address indexed technicalDirector, address indexed administrator
    );

    /// @notice Emitted when a technical director's authorization is revoked.
    /// @param workshopId Workshop identifier.
    /// @param technicalDirector Address of the director whose authorization was revoked.
    /// @param administrator Address that revoked the authorization.
    event TechnicalDirectorRevoked(
        bytes32 indexed workshopId, address indexed technicalDirector, address indexed administrator
    );

    // ---------------------------------------------------------------
    // CONSTRUCTOR
    // ---------------------------------------------------------------

    /// @notice Initializes the contract.
    /// @dev The deployer becomes the initial owner.
    constructor() Ownable(msg.sender) {}

    // ---------------------------------------------------------------
    // OWNERSHIP MANAGEMENT
    // ---------------------------------------------------------------

    /// @notice Prevents the owner from permanently abandoning permission management.
    /// @dev Always reverts with OwnershipRenunciationDisabled when called by the owner.
    function renounceOwnership() public view override onlyOwner {
        revert OwnershipRenunciationDisabled();
    }

    // ---------------------------------------------------------------
    // AUTHORIZATION MANAGEMENT
    // ---------------------------------------------------------------

    /// @notice Authorizes a technical director for a workshop.
    /// @param workshopId Unique workshop identifier.
    /// @param technicalDirector Technical director address.
    function authorizeTechnicalDirector(bytes32 workshopId, address technicalDirector) external onlyOwner {
        if (workshopId == bytes32(0)) {
            revert InvalidIdentifier();
        }

        if (technicalDirector == address(0)) {
            revert InvalidAddress();
        }

        if (authorizedDirectorsByWorkshop[workshopId][technicalDirector]) {
            revert DirectorAlreadyAuthorized();
        }

        authorizedDirectorsByWorkshop[workshopId][technicalDirector] = true;

        emit TechnicalDirectorAuthorized(workshopId, technicalDirector, msg.sender);
    }

    /// @notice Revokes a technical director's authorization for a workshop.
    /// @param workshopId Unique workshop identifier.
    /// @param technicalDirector Technical director address.
    function revokeTechnicalDirector(bytes32 workshopId, address technicalDirector) external onlyOwner {
        if (workshopId == bytes32(0)) {
            revert InvalidIdentifier();
        }

        if (technicalDirector == address(0)) {
            revert InvalidAddress();
        }

        if (!authorizedDirectorsByWorkshop[workshopId][technicalDirector]) {
            revert DirectorNotAuthorized();
        }

        authorizedDirectorsByWorkshop[workshopId][technicalDirector] = false;

        emit TechnicalDirectorRevoked(workshopId, technicalDirector, msg.sender);
    }

    // ---------------------------------------------------------------
    // AUTHORIZATION QUERIES
    // ---------------------------------------------------------------

    /// @notice Checks whether a technical director is authorized for a workshop.
    /// @param workshopId Unique workshop identifier.
    /// @param technicalDirector Technical director address.
    /// @return authorized True if the director is authorized.
    function isAuthorized(bytes32 workshopId, address technicalDirector)
        external
        view
        override
        returns (bool authorized)
    {
        if (workshopId == bytes32(0)) {
            revert InvalidIdentifier();
        }

        if (technicalDirector == address(0)) {
            revert InvalidAddress();
        }

        return authorizedDirectorsByWorkshop[workshopId][technicalDirector];
    }
}
