// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/VoteChain.sol"; // Adjust the path as needed

contract vote_chain_test is Test {
    votechain public vote_chain_instance;
    address public nonOwner = address(0xBEEF);

    event poll_created(uint indexed poll_id, string name, string description);
    event vote_cast(uint indexed poll_id, address voter, string option);
    event poll_ended(uint indexed poll_id, string winner);
    event vote_receipt_sent(address indexed voter, uint indexed poll_id, string receipt);

    // Setup function to deploy the contract before each test
    function setUp() public {
        vote_chain_instance = new votechain();
    }

    // Test that only the owner can create a poll
    function test_create_poll_only_owner() public {
        // Prepare options
        string[] memory options = new string[](2);
        options[0] = "Option A";
        options[1] = "Option B";

        // This should succeed (default msg.sender is this test contract, which deployed vote_chain)
        vote_chain_instance.create_poll("Owner Poll", "Should work", options, block.timestamp, block.timestamp + 1 days);

        // Impersonate a non-owner and attempt to create a poll
        vm.prank(nonOwner);
        vm.expectRevert(bytes("Not the contract owner"));
        vote_chain_instance.create_poll("Non Owner Poll", "Should revert", options, block.timestamp, block.timestamp + 1 days);
    }

    // Test case for creating a new poll
    function test_create_poll() public {
        // Declare and initialize the options array.
        string[] memory options = new string[](2);
        options[0] = "Option A";
        options[1] = "Option B";

        // Expect the poll_created event
        vm.expectEmit(true, true, true, true);
        emit poll_created(0, "Test Poll", "A simple poll");

        // Create the poll
        vote_chain_instance.create_poll(
            "Test Poll",
            "A simple poll",
            options,
            block.timestamp,
            block.timestamp + 1 days
        );

        // Retrieve the created poll and verify details
        (, string memory description, , , , bool ended) = vote_chain_instance.polls(0);
        assertEq(description, "A simple poll", "Poll description mismatch");
        assertEq(ended, false, "Poll should not be ended yet");
    }

    // Test case for casting a valid vote
    function test_vote() public {
        string[] memory options = new string[](2);
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

        // Verify vote count
        uint256 votes = vote_chain_instance.get_votes(0, "Option A");
        assertEq(votes, 1, "Option A should have 1 vote");
    }

    // Test for the vote_receipt_sent event
    function test_vote_receipt_sent() public {
        string[] memory options = new string[](2);
        options[0] = "Option A";
        options[1] = "Option B";

        vote_chain_instance.create_poll(
            "Test Poll",
            "A simple poll",
            options,
            block.timestamp,
            block.timestamp + 1 days
        );

        // Expect the vote_receipt_sent event
        vm.expectEmit(true, true, true, true);
        emit vote_receipt_sent(address(this), 0, "Your vote has been successfully cast.");

        // Cast vote
        vote_chain_instance.cast_vote(0, "Option A");

        // Check votes
        uint votes = vote_chain_instance.get_votes(0, "Option A");
        assertEq(votes, 1, "Option A should have 1 vote");
    }

    // Test that you cannot vote before start_time
    function test_cannot_vote_before_start() public {
        string[] memory options = new string[](2);
        options[0] = "Option A";
        options[1] = "Option B";

        vote_chain_instance.create_poll(
            "Future Poll",
            "Votes start in the future",
            options,
            block.timestamp + 3600, // starts in an hour
            block.timestamp + 2 days
        );

        vm.expectRevert(bytes("Voting has not started yet"));
        vote_chain_instance.cast_vote(0, "Option A");
    }

    // Test that you cannot vote after end_time
    function test_cannot_vote_after_end() public {
        string[] memory options = new string[](2);
        options[0] = "Option A";
        options[1] = "Option B";

        vote_chain_instance.create_poll(
            "Expired Poll",
            "This poll is already expired",
            options,
            block.timestamp,
            block.timestamp
        );

        // Move time forward by 1 second to exceed end_time
        vm.warp(block.timestamp + 1);

        vm.expectRevert(bytes("Voting has ended"));
        vote_chain_instance.cast_vote(0, "Option A");
    }

    // Test that a user cannot vote twice in the same poll
    function test_double_voting_forbidden() public {
        string[] memory options = new string[](2);
        options[0] = "Option A";
        options[1] = "Option B";

        vote_chain_instance.create_poll(
            "Double Voting Test",
            "Testing double votes",
            options,
            block.timestamp,
            block.timestamp + 1 days
        );

        // Cast first vote
        vote_chain_instance.cast_vote(0, "Option A");

        // Attempt to cast a second vote from the same address
        vm.expectRevert(bytes("You have already voted"));
        vote_chain_instance.cast_vote(0, "Option B");
    }

    // Test voting with an invalid option
    function test_invalid_option() public {
        string[] memory options = new string[](2);
        options[0] = "Option A";
        options[1] = "Option B";

        vote_chain_instance.create_poll(
            "Invalid Option Test",
            "Testing invalid option votes",
            options,
            block.timestamp,
            block.timestamp + 1 days
        );

        vm.expectRevert(bytes("Invalid option"));
        vote_chain_instance.cast_vote(0, "Option C");
    }

    // Test ending the poll before end_time
    function test_end_poll_before_time() public {
        string[] memory options = new string[](2);
        options[0] = "Option A";
        options[1] = "Option B";

        vote_chain_instance.create_poll(
            "Early End Test",
            "Cannot end this yet",
            options,
            block.timestamp,
            block.timestamp + 1 days
        );

        vm.expectRevert(bytes("Poll is still active"));
        vote_chain_instance.end_poll(0);
    }

    // Test ending the poll after end_time by a non-owner (distributed control)
    function test_end_poll_after_time() public {
        string[] memory options = new string[](2);
        options[0] = "Option A";
        options[1] = "Option B";

        vote_chain_instance.create_poll(
            "End Poll Test",
            "This poll can be ended by anyone",
            options,
            block.timestamp,
            block.timestamp + 1 days
        );

        // Move time forward beyond the poll end
        vm.warp(block.timestamp + 2 days);

        // Anyone (including nonOwner) can end the poll now
        vm.prank(nonOwner);
        vote_chain_instance.end_poll(0);

        // Check that the poll is ended
        (, , , , , bool ended) = vote_chain_instance.polls(0);
        assertEq(ended, true, "Poll should be ended");
    }

    // Test a tie scenario
    function test_tie_scenario() public {
        string[] memory options = new string[](2);
        options[0] = "Option A";
        options[1] = "Option B";

        vote_chain_instance.create_poll(
            "Tie Test",
            "Testing tie scenario",
            options,
            block.timestamp,
            block.timestamp + 1 days
        );

        // Cast one vote for each option
        vote_chain_instance.cast_vote(0, "Option A");

        // Use another address to cast vote for Option B
        vm.prank(nonOwner);
        vote_chain_instance.cast_vote(0, "Option B");

        // Move time forward beyond the poll end
        vm.warp(block.timestamp + 2 days);
        vote_chain_instance.end_poll(0);

        // Winner should be TIE
        string memory winner = vote_chain_instance.get_winner(0);
        assertEq(winner, "TIE", "Should be a tie");
    }

    // Test no votes scenario (should also result in a TIE)
    function test_no_votes_scenario() public {
        string[] memory options = new string[](2);
        options[0] = "Option A";
        options[1] = "Option B";

        vote_chain_instance.create_poll(
            "No Votes Test",
            "No one votes",
            options,
            block.timestamp,
            block.timestamp + 1 days
        );

        // Move time forward beyond the poll end without any votes
        vm.warp(block.timestamp + 2 days);
        vote_chain_instance.end_poll(0);

        string memory winner = vote_chain_instance.get_winner(0);
        assertEq(winner, "TIE", "No votes should also result in TIE");
    }

    // Test that fetching votes for a non-existent poll reverts
    function test_non_existent_poll() public {
        vm.expectRevert(bytes("Poll does not exist"));
        vote_chain_instance.get_votes(999, "Option A");
    }
}
