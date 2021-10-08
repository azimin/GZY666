// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IGZY666.sol";

/**
 * @title GZY-666 Project ownership, optional metadata extension
 */
interface IGZY666Metadata is IGZY666 {
    /**
     * @dev Returns the name for `projectId` project.
     */
    function name(uint256 projectId) external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `projectId` project.
     */
    function projectURI(uint256 projectId) external view returns (string memory);
}
