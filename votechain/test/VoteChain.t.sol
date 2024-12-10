// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/VoteChain.sol";

contract vote_chain_test is Test {
    VoteChain public vote_chain_instance;
    address public nonOwner = address(0xBEEF);

    event PollCreated(uint indexed poll_id, address indexed owner, string name, string description);
    event VoteCast(uint indexed poll_id, address voter, string option);
    event PollEnded(uint indexed poll_id, string reason);
    event PollFinalized(uint indexed poll_id, string winner);
    event VoteReceiptSent(address indexed voter, uint indexed poll_id, string receipt);

    // Setup function to deploy the contract before each test
    function setUp() public {
        vote_chain_instance = new VoteChain();
    }

    function test_create_poll_anyone_can_create() public {
        string[] memory options = new string[](2);
        options[0] = "Option A";
        options[1] = "Option B";

        // Poll created by the deployer
        vote_chain_instance.create_poll("Owner Poll", "Created by owner", options, block.timestamp, block.timestamp + 1 days);

        // Impersonate a non-owner and attempt to create a poll
        vm.prank(nonOwner);
        vote_chain_instance.create_poll("Non Owner Poll", "Created by non-owner", options, block.timestamp, block.timestamp + 1 days);

        // Verify that both polls were successfully created
        ( , string memory ownerPollName, , , , , , , ) = vote_chain_instance.polls(0);
        assertEq(ownerPollName, "Owner Poll", "Poll created by owner should exist");

        ( , string memory nonOwnerPollName, , , , , , , ) = vote_chain_instance.polls(1);
        assertEq(nonOwnerPollName, "Non Owner Poll", "Poll created by non-owner should exist");
    }


    // Test creating a poll and accessing fields directly
    function test_create_poll() public {
        string[] memory options = new string[](2);
        options[0] = "Option A";
        options[1] = "Option B";

        // Since there are two indexed arguments (poll_id and owner),
        // and two non-indexed arguments (name and description),
        // set vm.expectEmit to (true, true, true, true).
        // 1st true: Check event signature
        // 2nd true: Check first indexed argument (poll_id)
        // 3rd true: Check second indexed argument (owner)
        // 4th true: Check non-indexed arguments (name and description)
        vm.expectEmit(true, true, true, true);
        emit PollCreated(0, address(this), "Test Poll", "A simple poll");

        uint current_timestamp = block.timestamp;

        vote_chain_instance.create_poll(
            "Test Poll",
            "A simple poll",
            options,
            block.timestamp,
            block.timestamp + 1 days
        );

        // Destructure the returned tuple from polls(0)
        ( , string memory name, string memory description, , uint256 created_at, , , bool is_ended, ) = vote_chain_instance.polls(0);

        assertEq(name, "Test Poll", "Poll name mismatch");
        assertEq(description, "A simple poll", "Poll description mismatch");
        assertEq(created_at, current_timestamp, "Created_at timestamp mismatch");
        assertEq(is_ended, false, "Poll should not be ended yet");

        // Check the poll options
        assertEq(options.length, 2, "Poll should have 2 options");
        assertEq(options[0], "Option A", "Option A mismatch");
        assertEq(options[1], "Option B", "Option B mismatch");
    }

    // Test correct id update
    function test_poll_id_autoincrement() public {
        string[] memory options = new string[](2);
        options[0] = "Option A";
        options[1] = "Option B";

        uint id1 = vote_chain_instance.create_poll("Poll 0", "First poll", options, block.timestamp, block.timestamp + 1 days);
        uint id2 = vote_chain_instance.create_poll("Poll 1", "Second poll", options, block.timestamp, block.timestamp + 1 days);

        assertEq(id1, 0); // Check that the first poll's ID is 0
        assertEq(id2, 1); // Check that the second poll's ID is 1
    }

    function test_poll_options() public {
        string memory name = "Test Poll";
        string memory description = "This is a test poll";
        string[] memory options = new string[](3);
        options[0] = "Option A";
        options[1] = "Option B";
        options[2] = "Option C";
        uint startTime = block.timestamp + 1;
        uint endTime = block.timestamp + 3600;

        uint pollId = vote_chain_instance.create_poll(name, description,
            options, startTime, endTime);

        (string[] memory poll_options, uint[] memory poll_votes) = vote_chain_instance.poll_options(pollId);

        assertEq(poll_options.length, options.length, "Options count mismatch");

        for (uint i = 0; i < options.length; i++) {
            assertEq(poll_options[i], options[i], "Option mismatch");
        }

        for (uint i = 0; i < poll_votes.length; i++) {
            assertEq(poll_votes[i], 0, "Initial vote count mismatch");
        }
    }

    // Test casting a valid vote
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

        vote_chain_instance.cast_vote(0, 0);

        uint256 votes = vote_chain_instance.get_votes(0, 0);
        assertEq(votes, 1, "Option A should have 1 vote");
    }

    // Test vote receipt event
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

        vm.expectEmit(true, true, true, true);
        emit VoteReceiptSent(address(this), 0, "Your vote has been successfully cast.");

        vote_chain_instance.cast_vote(0, 0);
    }

    // Test that voting before start time is not allowed
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
        vote_chain_instance.cast_vote(0, 0);
    }

    // Test voting after end time
    function test_cannot_vote_after_end() public {
        string[] memory options = new string[](2);
        options[0] = "Option A";
        options[1] = "Option B";

        vote_chain_instance.create_poll(
            "Expired Poll",
            "This poll is already expired",
            options,
            block.timestamp,
            block.timestamp + 1
        );

        vm.warp(block.timestamp + 2);

        vm.expectRevert(bytes("Voting has ended"));
        vote_chain_instance.cast_vote(0, 0);
    }

    // Test double voting is not allowed
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

        vote_chain_instance.cast_vote(0, 0);

        vm.expectRevert(bytes("You have already voted"));
        vote_chain_instance.cast_vote(0, 1);
    }

    // Test invalid option
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

    vm.expectRevert(bytes("Invalid option index"));
    vote_chain_instance.cast_vote(0, 2);
}

    // Test ending poll after expiration
    function test_end_poll_after_time() public {
        string[] memory options = new string[](2);
        options[0] = "Option A";
        options[1] = "Option B";

        vote_chain_instance.create_poll(
            "End Poll Test",
            "This poll can be ended",
            options,
            block.timestamp,
            block.timestamp + 1 days
        );

        vm.warp(block.timestamp + 2 days);

        vm.expectEmit(true, true, true, true);
        emit PollEnded(0, "Poll has ended by the owner");

        vote_chain_instance.end_poll(0);
    }

    // Test tie scenario
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

        vote_chain_instance.cast_vote(0, 0);

        vm.prank(nonOwner);
        vote_chain_instance.cast_vote(0, 1);

        vm.warp(block.timestamp + 2 days);
        vote_chain_instance.end_poll(0);
        vote_chain_instance.finalize_poll(0);

        string memory winner = vote_chain_instance.get_winner(0);
        assertEq(winner, "TIE", "Tie scenario failed");
    }
}
