FROM debian:bookworm-slim

# Install required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
  bash curl tar gzip tmux git openssh-client zip unzip \
  build-essential gcc g++ cmake gettext python3 python3-pip \
  nodejs npm rustc cargo ripgrep fzf neovim && \
  rm -rf /var/lib/apt/lists/*

# Install lazygit
RUN curl -Lo /usr/local/bin/lazygit https://github.com/jesseduffield/lazygit/releases/download/v0.44.1/lazygit_0.44.1_Linux_arm64.tar.gz && \
  tar -xvzf /usr/local/bin/lazygit -C /usr/local/bin && \
  chmod +x /usr/local/bin/lazygit

WORKDIR /tmp

# Clone neovim repository
RUN git clone https://github.com/neovim/neovim.git

WORKDIR /tmp/neovim

RUN make CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=/root/neovim/neovim" && make install
ENV PATH="/root/neovim/bin:${PATH}"

# Set working directory for subsequent operations
WORKDIR /root

# Install + setup Foundry
RUN curl -L https://foundry.paradigm.xyz | bash && \
  /root/.foundry/bin/foundryup

# Install tmux plugin manager + plugins + generate SSH keys
RUN git clone https://github.com/tmux-plugins/tpm .tmux/plugins/tpm && \
  TMUX_PLUGIN_MANAGER_PATH=~/.tmux/plugins/tpm ~/.tmux/plugins/tpm/bin/install_plugins && \
  ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 -N ""

# Set the default working directory
WORKDIR /workspace
