PRIVATE_KEY ?= 0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e
CHAIN_ADDRESS = http://host.docker.internal:8545

# Create and attach to the devcontainer
devcontainer:
	@echo "Creating devcontainer..."
	@devcontainer build --workspace-folder .
	@devcontainer up --workspace-folder .
	@devcontainer exec --workspace-folder . tmux new-session -A -s dev

# Start local Ethereum testchain using Anvil
anvil:
	@echo "Starting anvil..."
	@anvil --host 0.0.0.0

# Build the contracts
build:
	@echo "Building contracts..."
	@forge build --root votechain/ 

# Run test suite
test:
	@echo "Starting tests..."
	@forge test --root votechain/

# Deploy contracts
deploy:
	@echo "Deploying VoteChain contract..."
	@forge create src/VoteChain.sol:VoteChain \
		--root votechain/ \
		--broadcast \
		--optimize true \
		--private-key ${PRIVATE_KEY} \
		--rpc-url ${CHAIN_ADDRESS}

# Remove build binaries and artifacts
clean:
	@echo "Cleaning up..."
	@forge clean --root votechain/

# Remove the devcontainer
devremove:
	@sudo ./scripts/kill-devcontainer.sh

.PHONY: devcontainer devremove anvil
