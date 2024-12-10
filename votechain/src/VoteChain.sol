// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VoteChain {
    struct Poll {
        uint id; // Unique identifier for the poll
        string name;
        string description;
        string[] options;
        uint created_at;
        uint start_time;
        uint end_time;
        mapping(string => uint) votes;
        string winner;
        bool is_ended;
        mapping(address => bool) has_voted;
        address owner; // Owner of this specific poll
    }

    uint public poll_count;
    mapping(uint => Poll) public polls;

    // Used to prevent replay attacks: (voter_address, poll_id, nonce) => bool
    mapping(address => mapping(uint => mapping(uint => bool))) public usedNonces;

    event PollCreated(uint indexed poll_id, address indexed owner, string name, string description);
    event VoteCast(uint indexed poll_id, address voter, string option);
    event PollEnded(uint indexed poll_id, string reason);
    event PollFinalized(uint indexed poll_id, string winner);
    event VoteReceiptSent(address indexed voter, uint indexed poll_id, string receipt);

    modifier pollExists(uint poll_id) {
        require(poll_id < poll_count, "Poll does not exist");
        _;
    }

    modifier onlyPollOwner(uint poll_id) {
        require(msg.sender == polls[poll_id].owner, "Not the poll owner");
        _;
    }

    // Users can create their own polls
    function create_poll(
        string memory _name,
        string memory _description,
        string[] memory _options,
        uint _start_time,
        uint _end_time
    ) 
        public 
        returns (uint) // Function now returns the poll ID
    {
        require(_start_time < _end_time, "Invalid time range");
        require(_options.length > 1, "At least two options required");

        uint poll_id = poll_count; // Assign current poll_count as the new poll's ID
        Poll storage new_poll = polls[poll_id];
        new_poll.id = poll_id; // Set the poll ID within the struct
        new_poll.name = _name;
        new_poll.description = _description;
        new_poll.options = _options;
        new_poll.created_at = block.timestamp; // Set the current timestamp
        new_poll.start_time = _start_time;
        new_poll.end_time = _end_time;
        new_poll.is_ended = false;
        new_poll.owner = msg.sender; // Set the poll owner

        emit PollCreated(poll_id, msg.sender, _name, _description);
        poll_count++;

        return poll_id; // Return the newly created poll ID to the user
    }

    // Return the pool options
    function poll_options(uint poll_id)
    public
    view
    pollExists(poll_id)
    returns (string[] memory _options, uint[] memory _numvotes)
    {
        Poll storage poll_instance = polls[poll_id];

        uint num_options = poll_instance.options.length;

        uint[] memory numvotes = new uint[](num_options);

        for (uint i = 0; i < num_options; i++) {
            string memory option = poll_instance.options[i];
            numvotes[i] = poll_instance.votes[option];
        }

        return (poll_instance.options, numvotes);
    }

    // Only the owner of a poll can close it
    function end_poll(uint poll_id) 
        public 
        pollExists(poll_id) 
        onlyPollOwner(poll_id) 
    {
        Poll storage poll_instance = polls[poll_id];
        require(block.timestamp > poll_instance.end_time, "Poll is still active");
        require(!poll_instance.is_ended, "Poll is already marked as ended");

        poll_instance.is_ended = true;

        emit PollEnded(poll_id, "Poll has ended by the owner");
    }

    // Users can cast their vote once for one of the valid options (direct method)
    function cast_vote(uint poll_id, uint option_index)
    public
    pollExists(poll_id)
    {
        Poll storage poll_instance = polls[poll_id];

        require(block.timestamp >= poll_instance.start_time, "Voting has not started yet");
        require(block.timestamp <= poll_instance.end_time, "Voting has ended");
        require(!poll_instance.has_voted[msg.sender], "You have already voted");
        require(option_index < poll_instance.options.length, "Invalid option index");

        // Increment the vote count for the selected option
        string memory option = poll_instance.options[option_index];
        poll_instance.votes[option]++;
        poll_instance.has_voted[msg.sender] = true;

        emit VoteCast(poll_id, msg.sender, option);
        emit VoteReceiptSent(msg.sender, poll_id, "Your vote has been successfully cast.");
    }

    // Check whether a user has already voted
    function has_voted(uint poll_id, address voter)
    public
    view
    pollExists(poll_id)
    returns (bool)
    {
        Poll storage poll_instance = polls[poll_id];
        return poll_instance.has_voted[voter];
    }

    // Finalize the poll: calculate the winner and emit the finalization event
    function finalize_poll(uint poll_id) 
        public 
        pollExists(poll_id) 
        onlyPollOwner(poll_id) 
    {
        Poll storage poll_instance = polls[poll_id];
        require(poll_instance.is_ended, "Poll must be ended before finalization");
        require(bytes(poll_instance.winner).length == 0, "Poll has already been finalized");

        uint max_votes = 0;
        bool tie = false;
        string memory winning_option;

        for (uint i = 0; i < poll_instance.options.length; i++) {
            string memory opt = poll_instance.options[i];
            uint option_votes = poll_instance.votes[opt];

            if (option_votes > max_votes) {
                max_votes = option_votes;
                winning_option = opt;
                tie = false;
            } else if (option_votes == max_votes && max_votes != 0) {
                tie = true;
            }
        }

        // If no votes or tie, set winner to "TIE"
        if (max_votes == 0 || tie) {
            poll_instance.winner = "TIE";
        } else {
            poll_instance.winner = winning_option;
        }

        emit PollFinalized(poll_id, poll_instance.winner);
    }

    // View the winner (if finalized)
    function get_winner(uint poll_id) 
        public 
        view 
        pollExists(poll_id) 
        returns (string memory) 
    {
        Poll storage poll_instance = polls[poll_id];
        require(bytes(poll_instance.winner).length != 0, "Poll has not been finalized yet");
        return poll_instance.winner;
    }

    // View function to get votes for a particular option
    function get_votes(uint poll_id, uint option_index)
    public
    view
    pollExists(poll_id)
    returns (uint)
    {
        Poll storage poll_instance = polls[poll_id];
        require(option_index < poll_instance.options.length, "Invalid option index");

        string memory option = poll_instance.options[option_index];
        return poll_instance.votes[option];
    }

    // Utility functions
    function uintToStr(uint _i) 
        internal 
        pure 
        returns (string memory) 
    {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        j = _i;
        while (j != 0) {
            k = k - 1;
            uint8 temp = uint8(48 + j % 10);
            bstr[k] = bytes1(temp);
            j /= 10;
        }
        return string(bstr);
    }
}
