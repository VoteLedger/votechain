// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract votechain {
    struct poll {
        string name;
        string description;
        string[] options; // Choice to vote
        uint start_time; // Time is managed by the Solidity property "block.timestamp"
        uint end_time;   // It expresses the current time in seconds starting from 1970/01/01
        mapping(string => uint) votes; // Votes for each option
        string winner;
        bool is_ended;
        mapping(address => bool) has_voted; // Tracks whether an address has already voted
    }

    uint public poll_count; // Counter of all the existent polls (including the closed ones)
    mapping(uint => poll) public polls; // Mapping polls -> ID
    address public owner; // Contract owner

    // Define events to log actions (helpful for front-end interaction)
    event poll_created(uint indexed poll_id, string name, string description);
    event vote_cast(uint indexed poll_id, address voter, string option);
    event poll_ended(uint indexed poll_id, string winner);
    event vote_receipt_sent(address indexed voter, uint indexed poll_id, string receipt); // Event for vote receipt notification

    // Modifier to ensure that only the owner can execute certain functions
    modifier only_owner() {
        require(msg.sender == owner, "Not the contract owner");
        _; // Placeholder for the actual function call
    }

    // Modifier to check if the poll exists
    modifier poll_exists(uint poll_id) {
        require(poll_id < poll_count, "Poll does not exist");
        _; // Placeholder for the actual function call
    }

    // Constructor to set the contract owner as the address that deploys it
    constructor() {
        owner = msg.sender;
    }

    // Create a new poll
    function create_poll(
        string memory _name,
        string memory _description,
        string[] memory _options,
        uint _start_time,
        uint _end_time
    ) public only_owner {
        // Validation checks to ensure the poll has a valid time range and at least two options
        require(_start_time < _end_time, "Invalid time range");
        require(_options.length > 1, "At least two options required");

        poll storage new_poll = polls[poll_count];
        new_poll.name = _name;
        new_poll.description = _description;
        new_poll.options = _options;
        new_poll.start_time = _start_time;
        new_poll.end_time = _end_time;
        new_poll.is_ended = false;

        emit poll_created(poll_count, _name, _description);
        poll_count++;
    }

    // Function to cast a vote in a poll
    function cast_vote(uint poll_id, string memory option) public poll_exists(poll_id) {
        poll storage poll_instance = polls[poll_id];

        // Check that the poll has started and has not ended
        require(block.timestamp >= poll_instance.start_time, "Voting has not started yet");
        require(block.timestamp <= poll_instance.end_time, "Voting has ended");

        // Ensure the user has not voted in that poll yet
        require(!poll_instance.has_voted[msg.sender], "You have already voted");

        // Validate that the chosen option is a valid one in the poll
        bool valid_option = false;
        for (uint i = 0; i < poll_instance.options.length; i++) {
            if (keccak256(abi.encodePacked(option)) == keccak256(abi.encodePacked(poll_instance.options[i]))) {
                valid_option = true;
                break;
            }
        }
        require(valid_option, "Invalid option");

        // Increment the vote count for the selected option and mark the address as having voted
        poll_instance.votes[option]++;
        poll_instance.has_voted[msg.sender] = true;

        // Emit event to notify that a vote was cast
        emit vote_cast(poll_id, msg.sender, option);

        // Send vote receipt to the voter (no option revealed)
        emit vote_receipt_sent(msg.sender, poll_id, "Your vote has been successfully cast.");
    }

    // Function to extract the number of votes for a specific option in a poll
    function get_votes(uint poll_id, string memory option) public view poll_exists(poll_id) returns (uint) {
        return polls[poll_id].votes[option];
    }

    // Function to end a poll and determine the winner
    function end_poll(uint poll_id) public poll_exists(poll_id) {
        poll storage poll_instance = polls[poll_id];
        require(block.timestamp > poll_instance.end_time, "Poll is still active");
        require(!poll_instance.is_ended, "Poll has already ended");

        uint max_votes = 0;
        string memory winning_option;

        // Loop through the options to determine which has the most votes
        for (uint i = 0; i < poll_instance.options.length; i++) {
            string memory option = poll_instance.options[i];
            if (poll_instance.votes[option] > max_votes) {
                max_votes = poll_instance.votes[option];
                winning_option = option;
            }
        }

        // Store the winner and mark the poll as ended
        poll_instance.winner = winning_option;
        poll_instance.is_ended = true;

        // Emit event to notify about the poll being ended
        emit poll_ended(poll_id, winning_option);
    }

    // Function to get the winner of a poll (can only be called after the poll ends)
    function get_winner(uint poll_id) public view poll_exists(poll_id) returns (string memory) {
        poll storage poll_instance = polls[poll_id];
        require(poll_instance.is_ended, "Poll has not ended yet");
        return poll_instance.winner;
    }
}

