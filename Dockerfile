FROM ubuntu:latest

RUN apt-get update && apt-get install -y \
  build-essential \
  sudo \
  curl \
  git

RUN mkdir -p /workspaces/.codespaces/.persistedshare/dotfiles

WORKDIR /workspaces/.codespaces/.persistedshare/dotfiles

COPY install.sh .
COPY Brewfile .
COPY bash ./bash
COPY bin ./bin
COPY bundler ./bundler
COPY fzf ./fzf
COPY gem ./gem
COPY git ./git
COPY nvim ./nvim
COPY rbenv ./rbenv
COPY script ./script
COPY starship ./starship
COPY tmux . ./tmux
COPY zsh . ./zsh

RUN useradd -m vscode
RUN usermod -aG sudo vscode
RUN chown -R vscode:vscode /workspaces/.codespaces/.persistedshare/dotfiles

RUN mkdir -p /workspaces/project
RUN chown -R vscode:vscode /workspaces/project

WORKDIR /workspaces/project

SHELL ["/bin/bash", "-c"]
