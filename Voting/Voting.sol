// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Voting {
    enum Status {
        NotStarted,
        Ongoing,
        Ended
    }

    struct VoteDetails {
        uint256 candidateId;
        string name;
        uint256 voteCount;
    }

    struct Election {
        string name;
        uint256 id;
        uint256 startTime; // When voting is allowed to begin
        uint256 endTime; // When voting ceases
        bool exists;
    }

    address public owner;

    mapping(uint256 => mapping(uint256 => VoteDetails)) public candidates;
    mapping(uint256 => uint256[]) public candidateIds;
    mapping(uint256 => Election) public elections;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(uint256 => Status) public electionStatus;
    uint256[] public electionIds;

    event ElectionCreated(uint256 indexed electionId, string name);
    event CandidateAdded(
        uint256 indexed electionId,
        uint256 candidateId,
        string name
    );
    event ElectionStarted(uint256 indexed electionId); // Event for administrative start
    event Voted(uint256 indexed electionId, uint256 candidateId, address voter);
    event ElectionEnded(uint256 indexed electionId);

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    modifier onlyIfOngoing(uint256 electionId) {
        require(
            electionStatus[electionId] == Status.Ongoing,
            "Election is not ongoing"
        );
        _;
    }

    modifier onlyIfNotEnded(uint256 electionId) {
        require(
            electionStatus[electionId] != Status.Ended,
            "Election has ended"
        );
        _;
    }

    // This modifier automatically updates the election status to Ended if its end time has passed.
    // It's useful to apply this to functions like `vote` or `getElectionStatus` to keep the status fresh.
    modifier updateElectionStatus(uint256 electionId) {
        if (
            electionStatus[electionId] == Status.Ongoing &&
            block.timestamp >= elections[electionId].endTime
        ) {
            electionStatus[electionId] = Status.Ended;
            emit ElectionEnded(electionId); // Emit event if status changes
        }
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createElection(
        string calldata _name,
        uint256 _id,
        uint256 _startTime, // This is the actual time voting begins
        uint256 _endTime // This is the actual time voting ends
    ) public onlyOwner {
        require(!elections[_id].exists, "Election already exists");
        require(_endTime > _startTime, "End time must be after start time");
        // Optional but recommended: Ensure start time is in the future
        require(
            _startTime > block.timestamp,
            "Start time must be in the future"
        );

        elections[_id] = Election({
            name: _name,
            id: _id,
            startTime: _startTime,
            endTime: _endTime,
            exists: true
        });

        electionIds.push(_id);
        electionStatus[_id] = Status.NotStarted;

        emit ElectionCreated(_id, _name);
    }

    function addCandidate(
        uint256 electionId,
        uint256 candidateId,
        string calldata name
    ) public onlyOwner {
        require(elections[electionId].exists, "Election does not exist");
        // Better check for candidate existence (assuming candidateId 0 is not used)
        require(
            candidates[electionId][candidateId].candidateId == 0,
            "Candidate with this ID already exists"
        );
        // Recommended: Prevent adding candidates after the election has been administratively started
        require(
            electionStatus[electionId] == Status.NotStarted,
            "Cannot add candidates after election has started"
        );

        candidates[electionId][candidateId] = VoteDetails({
            candidateId: candidateId,
            name: name,
            voteCount: 0
        });

        candidateIds[electionId].push(candidateId);
        emit CandidateAdded(electionId, candidateId, name);
    }

    // MODIFIED: Removed the `block.timestamp >= el.startTime` check
    function startElection(uint256 electionId) public onlyOwner {
        Election storage el = elections[electionId];
        require(el.exists, "Election does not exist");
        require(
            electionStatus[electionId] == Status.NotStarted,
            "Election already started or ended"
        );
        require(candidateIds[electionId].length > 0, "No candidates added");

        // Set the status to Ongoing, allowing the owner to "activate" the election setup
        // even if the actual voting time (el.startTime) has not arrived yet.
        electionStatus[electionId] = Status.Ongoing;
        emit ElectionStarted(electionId);
    }

    function vote(uint256 electionId, uint256 candidateId)
        public
        updateElectionStatus(electionId)
        onlyIfOngoing(electionId)
    {
        Election memory el = elections[electionId]; // Use memory for local struct copy

        // These are the crucial checks for allowing actual voting
        require(
            block.timestamp >= el.startTime,
            "Voting has not started yet for this election."
        );
        require(
            block.timestamp < el.endTime,
            "Voting has ended for this election."
        );

        require(!hasVoted[electionId][msg.sender], "You already voted");
        // Check if candidate exists by checking if its ID is non-zero
        require(
            candidates[electionId][candidateId].candidateId != 0,
            "Candidate does not exist"
        );

        candidates[electionId][candidateId].voteCount += 1;
        hasVoted[electionId][msg.sender] = true;

        emit Voted(electionId, candidateId, msg.sender);
    }

    function getCandidates(uint256 electionId)
        public
        view
        returns (VoteDetails[] memory)
    {
        // Removed onlyOwner, as anyone might want to see candidates
        uint256[] memory ids = candidateIds[electionId];
        VoteDetails[] memory details = new VoteDetails[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            details[i] = candidates[electionId][ids[i]];
        }

        return details;
    }

    function getAllElections() public view returns (Election[] memory) {
        Election[] memory result = new Election[](electionIds.length);
        for (uint256 i = 0; i < electionIds.length; i++) {
            result[i] = elections[electionIds[i]];
        }
        return result;
    }

    function getElectionById(uint256 electionId)
        public
        view
        returns (Election memory, Status)
    {
        // Added Status return
        require(elections[electionId].exists, "Election does not exist");
        // Call updateElectionStatus internally if you want the status to be fresh
        // However, view functions cannot modify state, so updateElectionStatus cannot be a modifier here.
        // You'd need a separate function to update status or rely on the `vote` function to do it.
        // For view functions, you can just return the current status and let the frontend interpret.
        return (elections[electionId], electionStatus[electionId]);
    }

    function getWinner(uint256 electionId)
        public
        view
        returns (VoteDetails memory)
    {
        // Removed onlyOwner, as anyone might want to see winner
        require(
            electionStatus[electionId] == Status.Ended,
            "Election is not ended"
        );

        uint256[] memory ids = candidateIds[electionId];
        require(ids.length > 0, "No candidates in this election"); // Ensure there are candidates

        VoteDetails memory winner;
        // Initialize winner with first candidate to avoid default values if all votes are 0
        if (ids.length > 0) {
            winner = candidates[electionId][ids[0]];
        }

        for (uint256 i = 0; i < ids.length; i++) {
            VoteDetails memory c = candidates[electionId][ids[i]];
            if (c.voteCount > winner.voteCount) {
                winner = c;
            }
        }

        return winner;
    }

    function manuallyEndElection(uint256 electionId) public onlyOwner {
        require(
            electionStatus[electionId] != Status.Ended,
            "Election already ended"
        );
        // Ensure election is ongoing to be manually ended
        require(
            electionStatus[electionId] == Status.Ongoing,
            "Election is not ongoing to be manually ended"
        );
        electionStatus[electionId] = Status.Ended;
        emit ElectionEnded(electionId);
    }
}
