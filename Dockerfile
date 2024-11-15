FROM ubuntu:latest

RUN apt-get update && apt-get install -y \
  build-essential \
  sudo \
  curl \
  git

WORKDIR /dotfiles

COPY install.sh /dotfiles
COPY Brewfile /dotfiles
COPY bash /dotfiles/bash
COPY bin /dotfiles/bin
COPY bundler /dotfiles/bundler
COPY fzf /dotfiles/fzg
COPY gem /dotfiles/gem
COPY git /dotfiles/git
COPY nvim /dotfiles/nvim
COPY rbenv /dotfiles/rbenv
COPY script /dotfiles/script
COPY starship /dotfiles/starship
COPY tmux /dotfiles/tmux
COPY zsh /dotfiles/zsh
