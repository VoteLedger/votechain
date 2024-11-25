.PHONY: devcontainer

devcontainer:
	@echo "Creating devcontainer..."
	@devcontainer build --workspace-folder .
	@devcontainer up --workspace-folder .
	@devcontainer exec --workspace-folder . tmux new-session -A -s dev

devremove:
	@sudo ./scripts/kill-devcontainer.sh
