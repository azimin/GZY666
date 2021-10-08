// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IGZY666Metadata.sol";

/**
 * @title GZY-666 Project ownership, optional vote extension
 */
interface IGZY666Vote is IGZY666 {
    /**
     * @dev Vote status for project
     *
     * Values:
     *
     * - `SKIP` don't vote
     * - `FOR` voted for project
     * - `AGRAINS` voted against project
     */
    enum VoteStatus { SKIP, FOR, AGAINST }

    /**
     * @dev Emitted when `from` owner with `tokenId` token vote for `projectId` project with `vote` vote status.
     */
    event ProjectVoted(
        address indexed from,
        uint256 indexed projectId,
        uint256 indexed tokenId,
        VoteStatus vote
    );
}