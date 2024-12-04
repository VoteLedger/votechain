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

//HOW TO COMPILE AND TEST

/*

1) Install foundry. In Windows, by using "git" terminal, type

curl -L https://foundry.paradigm.xyz | bash
foundryup

2) After the project has been opened in devcontainer, type

make anvil

This will result in an output like this, containing some useful informations
for both creating a blockchain in metamask and using some private keys as test

Starting anvil...


                             _   _
                            (_) | |
      __ _   _ __   __   __  _  | |
     / _` | | '_ \  \ \ / / | | | |
    | (_| | | | | |  \ V /  | | | |
     \__,_| |_| |_|   \_/   |_| |_|

    0.2.0 (995fd9e 2024-11-26T00:22:03.552319091Z)
    https://github.com/foundry-rs/foundry

Available Accounts
==================

(0) 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 (10000.000000000000000000 ETH)
(1) 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 (10000.000000000000000000 ETH)
(2) 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC (10000.000000000000000000 ETH)
(3) 0x90F79bf6EB2c4f870365E785982E1f101E93b906 (10000.000000000000000000 ETH)
(4) 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65 (10000.000000000000000000 ETH)
(5) 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc (10000.000000000000000000 ETH)
(6) 0x976EA74026E726554dB657fA54763abd0C3a0aa9 (10000.000000000000000000 ETH)
(7) 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955 (10000.000000000000000000 ETH)
(8) 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f (10000.000000000000000000 ETH)
(9) 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720 (10000.000000000000000000 ETH)

Private Keys
==================

(0) 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
(1) 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
(2) 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
(3) 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6
(4) 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a
(5) 0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba
(6) 0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e
(7) 0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356
(8) 0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97
(9) 0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6

Wallet
==================
Mnemonic:          test test test test test test test test test test test junk
Derivation path:   m/44'/60'/0'/0/


Chain ID
==================

31337

Base Fee
==================

1000000000

Gas Limit
==================

30000000

Genesis Timestamp
==================

1733321673

Listening on 0.0.0.0:8545
eth_blockNumber
eth_blockNumber
eth_getBalance

3) Build the file "VoteChain.sol"

forge build

(This command builds all the '.sol' files defined in the "src" folder)

4) Test the functions

forge script path/to/DeployVoteChain.s.sol --broadcast --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast

(Instead of <RPC_URL>, type the blockchain URL and, instead of <PRIVATE_KEY>, type one of the private keys gave by
make anvil)

For example, a possible script execution can be like

forge script script/VoteChain.s.sol:DeployVoteChain --rpc-url http://127.0.0.1:8545 --private-key
0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast

*/