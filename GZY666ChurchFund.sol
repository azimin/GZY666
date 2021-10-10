// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ReentrancyGuard.sol";
import "./IGZY666ChurchFund.sol";

contract GZY666ChurchFund is ReentrancyGuard, IGZY666ChurchFund {
    // Tokens contract
    IERC721 private _tokens;

    // Who can give permissions to create project
    address private _owner;

    // Last id
    uint256 private _lastProjectId = 0;

    // Who can create project
    mapping(address => CreateProjectPermissions) private _canCreateProject;

    // List of projects
    mapping(uint256 => Project) private _projects;

    // Votes for projects, project id => token id => VoteStatus
    mapping(uint256 => mapping(uint256 => VoteStatus)) private _votes;

    // Votes for projects, project id => for count
    mapping(uint256 => uint256) private _votesFor;

    // Votes for projects, project id => agains count
    mapping(uint256 => uint256) private _votesAgains;

    // Vote count by address, project id => address => votes count
    mapping(uint256 => mapping(address => uint256)) private _votesCount;
    
    // Base URI
    string private _baseFundURI;

    constructor(address owner_, IERC721 tokens_, string memory baseFundURI_) {
        _owner = owner_;
        _tokens = tokens_;
        _baseFundURI = baseFundURI_;
    }

    modifier existingProject(uint256 id) {
      require(_exists(id), "Nonexistent project");
      _;
    }

    modifier unfinishedProject(uint256 id) {
      require(isFinished(id) == false, "Finished project");
      _;
    }

    receive() external payable {
        emit MoneyReceived(msg.sender, msg.value);
    }

    fallback() external payable {
        emit MoneyReceived(msg.sender, msg.value);
    }
    
    function setBaseURI(string memory baseURI) public {
        require(msg.sender == _owner);
        _baseFundURI = baseURI;
    }

    function createProject(string memory title, uint value, address payable fund) public virtual lock returns (uint256) {
        require(fund != address(0), "Address should exist");
        require(canCreateProject(msg.sender), "Should have access");
        require(address(this).balance >= value, "Contract should has right amount");

        uint256 newId = _lastProjectId + 1;
        Project memory newProject = Project(newId, block.timestamp, title, value, fund, ProjectStatus.CREATED);
        _projects[newId] = newProject;
        _lastProjectId = newId;

        emit ProjectCreated(msg.sender, newId, title, newProject.date, value, fund);

        return newId;
    }

    function changeCreateProjectPermissions(address to, CreateProjectPermissions value) public virtual {
        require(to != address(0), "Address should exist");
        require(canGivePermissionsToCreateProject(msg.sender), "Should have access");

        if (value == CreateProjectPermissions.NO) {
            delete _canCreateProject[to];
        } else {
            _canCreateProject[to] = value;
        }

        emit ProjectCreatePermissionsChange(to, msg.sender, value);
    }

    function multiVoteForProject(
        uint256 projectId,
        uint256[] memory tokenIds,
        VoteStatus vote
    ) public virtual existingProject(projectId) unfinishedProject(projectId) lock {
        uint reduceVoteNumberChange = 0;
        uint reduceVotesFor = 0;
        uint reduceVotesAgainst = 0;

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(canVote(msg.sender, tokenId), "Should have access");
            VoteStatus preveousVote = voteStatus(projectId, tokenId);
            require(preveousVote != vote, "Vote should be different");

            if (preveousVote == VoteStatus.FOR) {
                reduceVotesFor += 1;
                reduceVoteNumberChange += 1;
            } else if  (preveousVote == VoteStatus.AGAINST) {
                reduceVotesAgainst += 1;
                reduceVoteNumberChange += 1;
            }
        }

        if (vote == VoteStatus.FOR) {
            _votesFor[projectId] = votesFor(projectId) + tokenIds.length - reduceVotesFor;
            _votesAgains[projectId] = votesAgains(projectId) - reduceVotesAgainst;
        } else if  (vote == VoteStatus.AGAINST) {
            _votesFor[projectId] = votesFor(projectId) - reduceVotesFor;
            _votesAgains[projectId] = votesAgains(projectId) + tokenIds.length - reduceVotesAgainst;
        } else {
            _votesFor[projectId] = votesFor(projectId) - reduceVotesFor;
            _votesAgains[projectId] = votesAgains(projectId) - reduceVotesAgainst;
        }

        if (vote == VoteStatus.SKIP) {
            uint newVotesTotalCount = votesCount(projectId, msg.sender) - reduceVoteNumberChange;
            _votesCount[projectId][msg.sender] = newVotesTotalCount;
        } else {
            uint voteNumberChange = tokenIds.length - reduceVoteNumberChange;
            uint newVotesTotalCount = votesCount(projectId, msg.sender) + voteNumberChange;
            require(newVotesTotalCount <= 7, "Each sender can vote only two times");
            _votesCount[projectId][msg.sender] = newVotesTotalCount;
        }

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            _votes[projectId][tokenId] = vote;
            emit ProjectVoted(msg.sender, projectId, tokenId, vote);
        }
    }

    function voteForProject(uint256 projectId, uint256 tokenId, VoteStatus vote) public virtual {
        uint[] memory tokenIds = new uint[](1);
        tokenIds[0] = tokenId;
        multiVoteForProject(projectId, tokenIds, vote);
    }

    function activateProject(
        uint256 projectId
    ) public virtual existingProject(projectId) unfinishedProject(projectId) lock {
        Project memory activatedProject = project(projectId);

        require(block.timestamp >= activatedProject.date + 7 days, "Should 7 days passed since project created");
        require(totalVotes(projectId) >= 777, "Should has at least 777 votes");
        require(percentage(projectId) >= 69, "Should has at least 69% for");

        activatedProject.status = ProjectStatus.FINISHED;
        _projects[projectId] = activatedProject;

        activatedProject.fund.transfer(activatedProject.value);

        emit ProjectActivated(msg.sender, projectId);
    }

    function deactivateProject(
        uint256 projectId
    ) public virtual existingProject(projectId) unfinishedProject(projectId) lock {
        Project memory activatedProject = project(projectId);
        require(canCreateProject(msg.sender), "Should have access");

        require(block.timestamp >= activatedProject.date + 33 days, "Should 33 days passed since project created");

        activatedProject.status = ProjectStatus.DEACTIVATED;
        _projects[projectId] = activatedProject;

        emit ProjectDeactivated(msg.sender, projectId);
    }

    function canCreateProject(address operator) public view virtual returns (bool) {
        return _canCreateProject[operator] == CreateProjectPermissions.HIGH
        || _canCreateProject[operator] == CreateProjectPermissions.LOW
        || operator == _owner;
    }

    function canGivePermissionsToCreateProject(address operator) public view virtual returns (bool) {
        return _canCreateProject[operator] == CreateProjectPermissions.HIGH
        || operator == _owner;
    }

    function totalVotes(uint256 projectId) public view virtual returns (uint256) {
        return votesFor(projectId) + votesAgains(projectId);
    }

    function percentage(uint256 projectId) public view virtual returns (uint256) {
        uint256 total = totalVotes(projectId);
        return votesFor(projectId) * 100 / total;
    }

    function numberOfProjects() public view override returns (uint256 count) {
        return _lastProjectId;
    }

    function projectStatus(uint256 projectId) public view override returns (ProjectStatus status) {
        return _projects[projectId].status;
    }

    function hasMadeContribution(uint256 projectId, address owner) public view override returns (bool) {
        return _votesCount[projectId][owner] > 0;
    }

    function name(uint256 projectId) public view override returns (string memory) {
        return project(projectId).title;
    }

    function canVote(address operator, uint256 tokenId) public view virtual returns (bool) {
        return tokens().ownerOf(tokenId) == operator;
    }

    function votesFor(uint256 projectId) public view virtual returns (uint256) {
        return _votesFor[projectId];
    }

    function votesAgains(uint256 projectId) public view virtual returns (uint256) {
        return _votesAgains[projectId];
    }

    function project(uint256 projectId) public view virtual returns (Project memory) {
        return _projects[projectId];
    }

    function voteStatus(uint256 projectId, uint256 tokenId) public view virtual returns (VoteStatus) {
        return _votes[projectId][tokenId];
    }

    function isFinished(uint256 projectId) public view virtual returns (bool) {
        return _projects[projectId].status != ProjectStatus.CREATED;
    }

    function balance() public view virtual returns (uint) {
        return address(this).balance;
    }

    function projectURI(uint256 projectId) public view override existingProject(projectId) returns (string memory) {
        return string(abi.encodePacked(_baseFundURI, Strings.toString(projectId)));
    }

    function votesCount(uint256 projectId, address operator) internal view virtual returns (uint256) {
        return _votesCount[projectId][operator];
    }

    function tokens() internal view returns (IERC721) {
        return _tokens;
    }

    function _exists(uint256 projectId) internal view virtual returns (bool) {
        return projectId > 0 && projectId <= numberOfProjects();
    }
}
