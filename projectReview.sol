// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract ProjectReview {
    address owner;

    // Enum for Rating (1 to 5)
    enum Rating {
        One,
        Two,
        Three,
        Four,
        Five
    }

    struct Project {
        uint8 id;
        string name;
        address creator;
        uint8 totalReviews;
        uint8 totalRatings;
    }

    struct Review {
        uint8 projectId;
        Rating rating;
        string feedback;
        address reviewer;
    }

    Project[] public projects;
    Review[] public reviews;

    mapping(uint => Review[]) public projectReviews;
    mapping(address => bool) public hasReviewed;

    event ProjectSubmitted(uint projectId, string name, address creator);
    event ReviewSubmitted(
        uint projectId,
        Rating rating,
        string feedback,
        address reviewer
    );

    constructor() {
        owner = msg.sender;
    }

    function submitProject(string memory _name) public {
        uint8 projectId = uint8(projects.length);
        projects.push(Project(projectId, _name, msg.sender, 0, 0));
        emit ProjectSubmitted(projectId, _name, msg.sender);
    }
}
