// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/VoteChain.sol";

contract VoteChainTest is Test {
    VoteChain public voteChain;

    // Setup function to deploy the contract before each test
    function setUp() public {
        voteChain = new VoteChain();
    }

    // Test case for creating a new poll
    function testCreatePoll() public {
        // Declare and initialize the options array. For simplicity, we'll consider 2 options
        string[] memory options = new string[](2); // Create an array in memory with 2 elements
        options[0] = "Option A";
        options[1] = "Option B";

        // Create a poll with the specified parameters
        voteChain.createPoll(
            "Test Poll",
            "A simple poll",
            options,
            block.timestamp,
            block.timestamp + 1 days
        );

        // Retrieve the created poll and verify the details
        (, string memory description, , , , bool ended) = voteChain.polls(0);
        assertEq(description, "A simple poll", "Poll description mismatch");
        assertEq(ended, false, "Poll should not be ended yet");
    }

    // Test case for casting a vote in a poll
    function testVote() public {
        string[] memory options = new string[](2);
        options[0] = "Option A";
        options[1] = "Option B";

        voteChain.createPoll(
            "Test Poll",
            "A simple poll",
            options,
            block.timestamp,
            block.timestamp + 1 days
        );

        // Simulate a vote for Option A
        voteChain.castVote(0, "Option A");

        // Verify that the vote counter for Option A is correctly incremented
        uint256 votes = voteChain.getVotes(0,  "Option A");
        assertEq(votes, 1, "Option A should have 1 vote");
    }

    // Test for the VoteReceiptSent event
    function testVoteReceiptSent() public {
        string[] memory options = new string[](2);
        options[0] = "Option A";
        options[1] = "Option B";

        voteChain.createPoll(
            "Test Poll",
            "A simple poll",
            options,
            block.timestamp,
            block.timestamp + 1 days
        );

        // Listen for the VoteReceiptSent event
        vm.expectEmit(true, true, true, true);
        emit VoteChain.VoteReceiptSent(address(this), 0, "Your vote has been successfully cast.");

        // Cast vote
        voteChain.castVote(0, "Option A");

        // Check if the vote was registered
        uint votes = voteChain.getVotes(0, "Option A");
        console.log("Votes for Option A: ", votes); // Aggiungi un log per il debug
        assertEq(votes, 1, "Option A should have 1 vote after casting the vote");
    }

}
