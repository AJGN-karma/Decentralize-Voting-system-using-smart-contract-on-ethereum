// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleVoting {
    address public admin;
    bool public electionStarted;
    bool public electionEnded;

    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    mapping(uint => Candidate) public candidates;
    uint[] public candidateIds;

    mapping(address => bool) public hasVoted;

    event CandidateRegistered(uint id, string name);
    event ElectionStarted();
    event ElectionEnded();
    event Voted(address voter, uint candidateId);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyBeforeStart() {
        require(!electionStarted, "Election already started");
        _;
    }

    modifier onlyDuringElection() {
        require(electionStarted && !electionEnded, "Election is not active");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function registerCandidate(uint id, string memory name) public onlyAdmin onlyBeforeStart {
        require(bytes(name).length > 0, "Candidate name required");
        require(candidates[id].id == 0, "Candidate ID already registered");

        candidates[id] = Candidate(id, name, 0);
        candidateIds.push(id);

        emit CandidateRegistered(id, name);
    }

    function startElection() public onlyAdmin onlyBeforeStart {
        require(candidateIds.length > 0, "No candidates registered");
        electionStarted = true;
        emit ElectionStarted();
    }

    function endElection() public onlyAdmin {
        require(electionStarted, "Election hasn't started");
        electionEnded = true;
        emit ElectionEnded();
    }

    function vote(uint candidateId) public onlyDuringElection {
        require(msg.sender != admin, "Admin is not allowed to vote");
        require(!hasVoted[msg.sender], "You have already voted");
        require(candidates[candidateId].id != 0, "Candidate does not exist");

        candidates[candidateId].voteCount += 1;
        hasVoted[msg.sender] = true;

        emit Voted(msg.sender, candidateId);
    }

    function getAllCandidates() public view returns (Candidate[] memory) {
        Candidate[] memory all = new Candidate[](candidateIds.length);
        for (uint i = 0; i < candidateIds.length; i++) {
            all[i] = candidates[candidateIds[i]];
        }
        return all;
    }

    function getWinner() public view returns (string memory winnerName, uint maxVotes) {
        require(electionEnded, "Election not ended");

        uint highestVotes = 0;
        uint winnerId = 0;
        bool tie = false;

        for (uint i = 0; i < candidateIds.length; i++) {
            uint id = candidateIds[i];
            uint votes = candidates[id].voteCount;

            if (votes > highestVotes) {
                highestVotes = votes;
                winnerId = id;
                tie = false;
            } else if (votes == highestVotes && highestVotes != 0) {
                tie = true;
            }
        }

        if (highestVotes == 0) {
            return ("No votes cast", 0);
        }

        if (tie) {
            return ("Vote is tied", highestVotes);
        } else {
            return (candidates[winnerId].name, highestVotes);
        }
    }
}
