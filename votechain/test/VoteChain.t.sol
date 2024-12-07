// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/VoteChain.sol";

contract vote_chain_test is Test {
    vote_chain public vote_chain_instance;

    // Setup function to deploy the contract before each test
    function set_up() public {
        vote_chain_instance = new vote_chain();
    }

    // Test case for creating a new poll
    function test_create_poll() public {
        // Declare and initialize the options array. For simplicity, we'll consider 2 options
        string; // Create an array in memory with 2 elements
        options[0] = "Option A";
        options[1] = "Option B";

        // Create a poll with the specified parameters
        vote_chain_instance.create_poll(
            "Test Poll",
            "A simple poll",
            options,
            block.timestamp,
            block.timestamp + 1 days
        );

        // Retrieve the created poll and verify the details
        (, string memory description, , , , bool ended) = vote_chain_instance.polls(0);
        assertEq(description, "A simple poll", "Poll description mismatch");
        assertEq(ended, false, "Poll should not be ended yet");
    }

    // Test case for casting a vote in a poll
    function test_vote() public {
        string;
        options[0] = "Option A";
        options[1] = "Option B";

        vote_chain_instance.create_poll(
            "Test Poll",
            "A simple poll",
            options,
            block.timestamp,
            block.timestamp + 1 days
        );

        // Simulate a vote for Option A
        vote_chain_instance.cast_vote(0, "Option A");

        // Verify that the vote counter for Option A is correctly incremented
        uint256 votes = vote_chain_instance.get_votes(0, "Option A");
        assertEq(votes, 1, "Option A should have 1 vote");
    }

    // Test for the vote_receipt_sent event
    function test_vote_receipt_sent() public {
        string;
        options[0] = "Option A";
        options[1] = "Option B";

        vote_chain_instance.create_poll(
            "Test Poll",
            "A simple poll",
            options,
            block.timestamp,
            block.timestamp + 1 days
        );

        // Listen for the vote_receipt_sent event
        vm.expectEmit(true, true, true, true);
        emit vote_chain.vote_receipt_sent(address(this), 0, "Your vote has been successfully cast.");

        // Cast vote
        vote_chain_instance.cast_vote(0, "Option A");

        // Check if the vote was registered
        uint votes = vote_chain_instance.get_votes(0, "Option A");
        console.log("Votes for Option A: ", votes); // Add log for debugging
        assertEq(votes, 1, "Option A should have 1 vote after casting the vote");
    }
}
