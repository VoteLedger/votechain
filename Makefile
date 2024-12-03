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

# Remove the devcontainer
devremove:
	@sudo ./scripts/kill-devcontainer.sh

.PHONY: devcontainer devremove anvil
