FROM rust:alpine

# Install required packages + Neovim from registry
RUN apk add --no-cache \
  bash curl tar gzip tmux git openssh zip unzip \
  build-base gcc g++ cmake gettext gettext-dev \
  python3 py3-pip nodejs npm \
  ripgrep fzf lazygit neovim

# Set working directory for subsequent operations
WORKDIR /root

# Set ASH as the default shell
ENV SHELL=/bin/ash

# Install forgery
RUN curl -L https://foundry.paradigm.xyz | ash

# Install tmux plugin manager + plugins + generate SSH keys
RUN git clone https://github.com/tmux-plugins/tpm .tmux/plugins/tpm && \
  TMUX_PLUGIN_MANAGER_PATH=~/.tmux/plugins/tpm ~/.tmux/plugins/tpm/bin/install_plugins && \
  ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 -N ""

# Set the default working directory
WORKDIR /workspace
