// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {VoteChain} from "../src/VoteChain.sol";

//Test some functionalities directly in the blockchain
contract DeployVoteChain is Script {
    function run() public {
        vm.startBroadcast();

        // 1. Contract deployment
        VoteChain voteChain = new VoteChain();
        console.log("VoteChain deployed at:", address(voteChain));

        // 2. Create a pool
        string[] memory options = new string[](3);
        options[0] = "Option A";
        options[1] = "Option B";
        options[2] = "Option C";

        uint startTime = block.timestamp; // Start voting immediately
        console.log("Start time:", startTime);
        uint endTime = block.timestamp + 10 minutes; // Voting ends in 10 minutes
        console.log("Current block.timestamp:", block.timestamp);
        console.log("End time:", endTime);
        voteChain.createPoll("Test Poll", "A test poll for winner calculation", options, startTime, endTime);
        console.log("Poll created with ID:", uint256(0));

        // 3. Vote simulations
        console.log("Current block.timestamp:", block.timestamp);
        address userAddress = msg.sender;
        voteChain.castVote(0, "Option A"); //first, ok
        console.log("%s has successfully voted for Poll ID %s", userAddress, uint256(0));
        try voteChain.castVote(0, "Option B") {
            //the same user tries to vote a second time
            console.log("%s has successfully voted for Poll ID %s", userAddress, uint256(0));
        } catch Error(string memory reason) {
            console.log(reason); // "You have already voted"
        }

        // 4. End pool simulation
        vm.warp(block.timestamp + 11 minutes); // Move forward in time just a little after the poll ends (not 11 minutes)
        console.log("Current block.timestamp:", block.timestamp);

        // Ensure that the poll can be ended (check if the poll's end time has passed)
        try voteChain.endPoll(0) {
            console.log("Poll closed at time:", block.timestamp);
        } catch {
            console.log("Poll is still active, cannot close yet.");
        }

        // 5. Print winner
        string memory winner = voteChain.getWinner(uint256(0));
        console.log("The winner of Poll ID 0 is:", winner);

        vm.stopBroadcast();
    }
}
