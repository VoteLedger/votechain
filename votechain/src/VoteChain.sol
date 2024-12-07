// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract votechain {
    struct poll {
        string name;
        string description;
        string[] options;
        uint start_time;
        uint end_time;
        mapping(string => uint) votes;
        string winner;
        bool is_ended;
        mapping(address => bool) has_voted;
    }

    uint public poll_count;
    mapping(uint => poll) public polls;
    address public owner;

    event poll_created(uint indexed poll_id, string name, string description);
    event vote_cast(uint indexed poll_id, address voter, string option);
    event poll_ended(uint indexed poll_id, string winner);
    event vote_receipt_sent(address indexed voter, uint indexed poll_id, string receipt);

    modifier only_owner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier poll_exists(uint poll_id) {
        require(poll_id < poll_count, "Poll does not exist");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Owners can create polls
    function create_poll(
        string memory _name,
        string memory _description,
        string[] memory _options,
        uint _start_time,
        uint _end_time
    ) public only_owner {
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

    // Users can cast their vote once for one of the valid options
    function cast_vote(uint poll_id, string memory option) public poll_exists(poll_id) {
        poll storage poll_instance = polls[poll_id];

        require(block.timestamp >= poll_instance.start_time, "Voting has not started yet");
        require(block.timestamp <= poll_instance.end_time, "Voting has ended");
        require(!poll_instance.has_voted[msg.sender], "You have already voted");

        bool valid_option = false;
        for (uint i = 0; i < poll_instance.options.length; i++) {
            if (keccak256(abi.encodePacked(option)) == keccak256(abi.encodePacked(poll_instance.options[i]))) {
                valid_option = true;
                break;
            }
        }
        require(valid_option, "Invalid option");

        poll_instance.votes[option]++;
        poll_instance.has_voted[msg.sender] = true;

        emit vote_cast(poll_id, msg.sender, option);
        emit vote_receipt_sent(msg.sender, poll_id, "Your vote has been successfully cast.");
    }

    // View function to get votes for a particular option
    function get_votes(uint poll_id, string memory option) public view poll_exists(poll_id) returns (uint) {
        return polls[poll_id].votes[option];
    }

    // Anyone can end the poll after the end_time has passed
    function end_poll(uint poll_id) public poll_exists(poll_id) {
        poll storage poll_instance = polls[poll_id];
        require(block.timestamp > poll_instance.end_time, "Poll is still active");
        require(!poll_instance.is_ended, "Poll has already ended");

        uint max_votes = 0;
        bool tie = false;
        string memory winning_option;

        for (uint i = 0; i < poll_instance.options.length; i++) {
            string memory option = poll_instance.options[i];
            uint option_votes = poll_instance.votes[option];

            if (option_votes > max_votes) {
                max_votes = option_votes;
                winning_option = option;
                tie = false; 
            } else if (option_votes == max_votes && max_votes != 0) {
                // A tie for top votes
                tie = true;
            }
        }

        // If no votes at all, consider it a tie
        if (max_votes == 0) {
            tie = true;
        }

        if (tie) {
            poll_instance.winner = "TIE";
        } else {
            poll_instance.winner = winning_option;
        }

        poll_instance.is_ended = true;
        emit poll_ended(poll_id, poll_instance.winner);
    }

    // View the winner (if ended)
    function get_winner(uint poll_id) public view poll_exists(poll_id) returns (string memory) {
        poll storage poll_instance = polls[poll_id];
        require(poll_instance.is_ended, "Poll has not ended yet");
        return poll_instance.winner;
    }
}
