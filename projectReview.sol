// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract ProjectReview {
    enum Rating {
        One,
        Two,
        Three,
        Four,
        Five
    }

    struct Review {
        Rating rating;
        string feedback;
        address reviewer;
    }

    // another approach is to store review array in project struct but it'll use far more gas
    struct Project {
        uint groupId;
        string name;
        address projectOwner;
        uint totalReviews;
        uint totalRating;
    }

    // Mapping from groupId to Project
    mapping(uint => Project) public projects;
    // Tracks if a user has reviewed a project (address => groupId => bool)
    mapping(address => mapping(uint => bool)) public hasReviewed;
    // Mapping of projectId to reviewId to Review (groupId => reviewId => Review)
    mapping(uint => mapping(uint => Review)) public reviews;
    // Counts the number of reviews per project
    mapping(uint => uint) public reviewCounts;
    // Tracks counts of each rating per project (groupId => rating => count)
    mapping(uint => mapping(uint => uint)) public ratingCounts;

    event ProjectSubmitted(
        uint indexed groupId,
        string name,
        address indexed projectOwner
    );
    event ReviewSubmitted(
        uint indexed groupId,
        Rating rating,
        string feedback,
        address indexed reviewer
    );

    // Submit a new project
    function submitProject(uint _groupId, string memory _name) public {
        // restricting name to 100 characters to reduce gas costs
        require(
            bytes(_name).length > 0 && bytes(_name).length <= 100,
            "Project name must be between 1 and 100 characters"
        );
        require(
            bytes(projects[_groupId].name).length == 0,
            "Project with this groupId already exists"
        );

        projects[_groupId] = Project({
            groupId: _groupId,
            name: _name,
            projectOwner: msg.sender,
            totalReviews: 0,
            totalRating: 0
        });

        emit ProjectSubmitted(_groupId, _name, msg.sender);
    }

    // Submit a review for a project
    function submitReview(
        uint _groupId,
        uint8 _ratingValue,
        string memory _feedback
    ) public {
        // validate input
        require(
            bytes(projects[_groupId].name).length > 0,
            "Project with this groupId does not exist"
        );
        require(
            _ratingValue >= 1 && _ratingValue <= 5,
            "Rating must be between 1 and 5"
        );
        // restricting feedback to 300 characters to reduce gas costs
        require(
            bytes(_feedback).length > 0 && bytes(_feedback).length <= 300,
            "Feedback must be between 1 and 300 characters"
        );
        require(
            !hasReviewed[msg.sender][_groupId],
            "You have already reviewed this project"
        );

        // using storage because we need to modify the state of the project
        Project storage project = projects[_groupId];

        require(
            project.projectOwner != msg.sender,
            "Project owners cannot review their own projects"
        );

        // Subtract 1 because enum values start at 0
        Rating _rating = Rating(_ratingValue - 1);
        project.totalReviews += 1;
        project.totalRating += _ratingValue;
        ratingCounts[_groupId][_ratingValue]++;

        uint reviewId = reviewCounts[_groupId];
        reviews[_groupId][reviewId] = Review(_rating, _feedback, msg.sender);
        reviewCounts[_groupId] = reviewId + 1;

        hasReviewed[msg.sender][_groupId] = true;

        emit ReviewSubmitted(_groupId, _rating, _feedback, msg.sender);
    }

    // Retrieve project details
    function getProject(
        uint _groupId
    )
        public
        view
        returns (
            string memory name,
            uint totalReviews,
            uint totalRating,
            address projectOwner
        )
    {
        require(
            bytes(projects[_groupId].name).length > 0,
            "Project with this groupId does not exist"
        );
        Project memory project = projects[_groupId];
        return (
            project.name,
            project.totalReviews,
            project.totalRating,
            project.projectOwner
        );
    }

    // Calculate the average rating (scaling by 100 to support 2 decimal places)
    function getAverageRating(uint _groupId) public view returns (uint) {
        require(
            bytes(projects[_groupId].name).length > 0,
            "Project with this groupId does not exist"
        );
        Project memory project = projects[_groupId];
        // No reviews yet
        if (project.totalReviews == 0) {
            return 0;
        }
        return (project.totalRating * 100) / project.totalReviews;
    }

    // Retrieve a specific review (for specific group) by its ID
    function getReview(
        uint _groupId,
        uint _reviewId
    )
        public
        view
        returns (Rating rating, string memory feedback, address reviewer)
    {
        require(
            bytes(projects[_groupId].name).length > 0,
            "Project with this groupId does not exist"
        );
        require(_reviewId < reviewCounts[_groupId], "Review does not exist");
        Review memory review = reviews[_groupId][_reviewId];
        return (review.rating, review.feedback, review.reviewer);
    }

    // Get the count of a specific rating for a project
    function getRatingCount(
        uint _groupId,
        uint _ratingValue
    ) public view returns (uint) {
        require(
            _ratingValue >= 1 && _ratingValue <= 5,
            "Rating value must be between 1 and 5"
        );
        return ratingCounts[_groupId][_ratingValue];
    }
}
