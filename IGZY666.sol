// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an GZY666 compliant contract.
 */
interface IGZY666 {
    /**
     * @dev Project status
     *
     * Values:
     *
     * - `CREATED` created project
     * - `FINISHED` activated (accepted) project
     * - `DEACTIVATED` deactivated (cancelled) project
     */
    enum ProjectStatus { CREATED, FINISHED, DEACTIVATED }

    /**
     * @dev Returns if the `owner` owner made contribution to `projectId` project.
     *
     * Requirements:
     *
     * - `projectId` must exist.
     * - `owner` must exist.
     */
    function hasMadeContribution(
        uint256 projectId,
        address owner
    ) external view returns (bool);

    /**
     * @dev Returns status of `projectId` project.
     *
     * Requirements:
     *
     * - `projectId` must exist.
     */
    function projectStatus(
        uint256 projectId
    ) external view returns (ProjectStatus status);

    /**
     * @dev Returns number of projects.
     */
    function numberOfProjects() external view returns (uint256 count);
}
