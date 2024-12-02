// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VoteChain {
    struct Poll {
        string name;
        string description;
        string[] options; // Choice to vote
        uint startTime; // Time is managed by the Solidity property "block.timestamp"
        uint endTime;   // It express the current time in seconds starting from 1970/01/01
        mapping(string => uint) votes; // Votes for each option
        string winner;
        bool isEnded;
        mapping(address => bool) hasVoted; // Tracks whether an address has already voted
    }

    uint public pollCount; // Counter of all the existent pools (including the closed one)
    mapping(uint => Poll) public polls; // Mapping pools -> ID
    address public owner; // Contract owner

    // Define events to log actions (helpful for front-end interaction)
    event PollCreated(uint indexed pollId, string name, string description);
    event VoteCast(uint indexed pollId, address voter, string option);
    event PollEnded(uint indexed pollId, string winner);
    event VoteReceiptSent(address indexed voter, uint indexed pollId, string receipt); // Event for vote receipt notification


    // Modifier to ensure that only the owner can execute certain functions
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _; // Placeholder for the actual function call
    }

    // Modifier to check if the poll exists
    modifier pollExists(uint pollId) {
        require(pollId < pollCount, "Poll does not exist");
        _; // Placeholder for the actual function call
    }

    // Constructor to set the contract owner as the address that deploys it
    constructor() {
        owner = msg.sender;
    }

    // Create a new poll
    function createPoll(
        string memory _name,
        string memory _description,
        string[] memory _options,
        uint _startTime,
        uint _endTime
    ) public onlyOwner {
        // Validation checks to ensure the poll has a valid time range and at least two options
        require(_startTime < _endTime, "Invalid time range");
        require(_options.length > 1, "At least two options required");

        Poll storage newPoll = polls[pollCount];
        newPoll.name = _name;
        newPoll.description = _description;
        newPoll.options = _options;
        newPoll.startTime = _startTime;
        newPoll.endTime = _endTime;
        newPoll.isEnded = false;

        emit PollCreated(pollCount, _name, _description);
        pollCount++;
    }

    // Function to cast a vote in a poll
    function castVote(uint pollId, string memory option) public pollExists(pollId) {
        Poll storage poll = polls[pollId];

        // Check that the poll has started and has not ended
        require(block.timestamp >= poll.startTime, "Voting has not started yet");
        require(block.timestamp <= poll.endTime, "Voting has ended");

        // Ensure the user hass not voted in that poll yet
        require(!poll.hasVoted[msg.sender], "You have already voted");

        // Validate that the chosen option is a valid one in the poll
        bool validOption = false;
        for (uint i = 0; i < poll.options.length; i++) {
            if (keccak256(abi.encodePacked(option)) == keccak256(abi.encodePacked(poll.options[i]))) {
                validOption = true;
                break;
            }
        }
        require(validOption, "Invalid option");

        // Increment the vote count for the selected option and mark the address as having voted
        poll.votes[option]++;
        poll.hasVoted[msg.sender] = true;

        // Emit event to notify that a vote was cast
        emit VoteCast(pollId, msg.sender, option);

        // Send vote receipt to the voter (no option revealed)
        emit VoteReceiptSent(msg.sender, pollId, "Your vote has been successfully cast.");
    }

    // Function to extracts the number of votes for a specific option in a poll
    function getVotes(uint pollId, string memory option) public view pollExists(pollId) returns (uint) {
        return polls[pollId].votes[option];
    }


    // Function to end a poll and determine the winner
    function endPoll(uint pollId) public pollExists(pollId) {
        Poll storage poll = polls[pollId];
        require(block.timestamp > poll.endTime, "Poll is still active");
        require(!poll.isEnded, "Poll has already ended");

        uint maxVotes = 0;
        string memory winningOption;

        // Loop through the options to determine which has the most votes
        for (uint i = 0; i < poll.options.length; i++) {
            string memory option = poll.options[i];
            if (poll.votes[option] > maxVotes) {
                maxVotes = poll.votes[option];
                winningOption = option;
            }
        }

        // Store the winner and mark the poll as ended
        poll.winner = winningOption;
        poll.isEnded = true;

        // Emit event to notify about the poll being ended
        emit PollEnded(pollId, winningOption);
    }

    // Function to get the winner of a poll (can only be called after the poll ends)
    function getWinner(uint pollId) public view pollExists(pollId) returns (string memory) {
        Poll storage poll = polls[pollId];
        require(poll.isEnded, "Poll has not ended yet");
        return poll.winner;
    }
}

//HOW TO COMPILE AND TEST

/*

1) Install foundry. In Windows, by using "git" terminal, type

curl -L https://foundry.paradigm.xyz | bash
foundryup

2) Build the file "VoteChain.sol"

forge test

(This command builds all the '.sol' files defined in the "src" folder)

3) Test the functions

Forge test

(This command test all the '.t.sol' defined in the "test" folder)

*/
