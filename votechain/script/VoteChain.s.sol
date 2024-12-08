// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {VoteChain} from "../src/VoteChain.sol";

// Test some functionalities directly in the blockchain
contract deploy_vote_chain is Script {
    function run() public {
        vm.startBroadcast();

        // 1. Contract deployment
        VoteChain vote_chain_instance = new VoteChain();
        console.log("vote_chain deployed at:", address(vote_chain_instance));

        // 2. Create a poll
        // ** Declare and initialize the options array properly **
        string[] memory options = new string[](3);
        options[0] = "Option A";
        options[1] = "Option B";
        options[2] = "Option C";

        uint start_time = block.timestamp;
        console.log("Start time:", start_time);
        uint end_time = block.timestamp + 10 minutes;
        console.log("Current block.timestamp:", block.timestamp);
        console.log("End time:", end_time);

        // Pass the options array to create_poll
        vote_chain_instance.create_poll("Test Poll", "A test poll for winner calculation", options, start_time, end_time);
        console.log("Poll created with ID:", uint256(0));

        // 3. Vote simulations
        console.log("Current block.timestamp:", block.timestamp);
        address user_address = msg.sender;
        vote_chain_instance.cast_vote(0, "Option A"); // First, OK
        console.log("%s has successfully voted for Poll ID %s", user_address, uint256(0));

        try vote_chain_instance.cast_vote(0, "Option B") {
            // The same user tries to vote a second time
            console.log("%s has successfully voted for Poll ID %s", user_address, uint256(0));
        } catch Error(string memory reason) {
            console.log(reason); // "You have already voted"
        }

        // 4. End poll simulation
        vm.warp(block.timestamp + 11 minutes); // Move forward in time just a little after the poll ends
        console.log("Current block.timestamp:", block.timestamp);

        // Check if the poll's end time has passed and update `is_ended`
        vote_chain_instance.end_poll(0);
        console.log("Poll marked as ended at time:", block.timestamp);

        // Finalize the poll (calculate winner)
        try vote_chain_instance.finalize_poll(0) {
            console.log("Poll finalized and winner determined at time:", block.timestamp);
        } catch {
            console.log("Poll is still not ready for finalization.");
        }

        // 5. Print winner
        string memory winner = vote_chain_instance.get_winner(uint256(0));
        console.log("The winner of Poll ID 0 is:", winner);

        vm.stopBroadcast();
    }
}
