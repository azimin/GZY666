// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IGZY666Metadata.sol";
import "./IGZY666Vote.sol";

interface IGZY666ChurchFund is IGZY666Metadata, IGZY666Vote {
    struct Project {
        uint256 id;
        uint date;
        string title;
        uint value;
        address payable fund;
        ProjectStatus status;
    }

    enum CreateProjectPermissions { NO, LOW, HIGH }

    event MoneyReceived(
        address indexed from,
        uint value
    );

    event ProjectCreated(
        address indexed from,
        uint256 indexed projectId,
        string indexed title,
        uint date,
        uint value,
        address fund
    );

    event ProjectCreatePermissionsChange(
        address indexed to,
        address indexed whoGave,
        CreateProjectPermissions value
    );

    event ProjectActivated(
        address indexed from,
        uint256 indexed projectId
    );

    event ProjectDeactivated(
        address indexed from,
        uint256 indexed projectId
    );
}
