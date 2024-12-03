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
        uint endTime = block.timestamp + 10 minutes; // Voting ends in 10 minutes
        voteChain.createPoll("Test Poll", "A test poll for winner calculation", options, startTime, endTime);
        console.log("Poll created with ID:", 0);

        // 3. Vote simulations
        voteChain.castVote(0, "Option A");
        voteChain.castVote(0, "Option A");
        voteChain.castVote(0, "Option B");
        console.log("Votes cast for Poll ID:", 0);

        // 4. End pool simulation
        vm.warp(block.timestamp + 11 minutes); // Move forward in time to ensure the poll ends
        voteChain.endPoll(0);
        console.log("Poll ended with ID:", 0);

        // 5. Print winner
        string memory winner = voteChain.getWinner(0);
        console.log("The winner of Poll ID 0 is:", winner);

        vm.stopBroadcast();
    }
}

//HOW TO COMPILE AND TEST

/*

1) Install foundry. In Windows, by using "git" terminal, type

curl -L https://foundry.paradigm.xyz | bash
foundryup

2) Build the file "VoteChain.sol"

forge build

(This command builds all the '.sol' files defined in the "src" folder)

3) Test the functions

forge script path/to/DeployVoteChain.s.sol --broadcast --rpc-url <RPC_URL>

(Instead of <RPC_URL>, tyoe the blockchain URL

*/