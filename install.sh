#!/usr/bin/env bash

set -ex

DOTFILES_DIR=$(cd $(dirname "$0")/.. && pwd)

sudo apt update

sudo apt -y install build-essential procps curl file git less
sudo apt install -y silversearcher-ag
sudo apt -y install ruby-full
sudo apt -y install bash-completion


### GitHub CLI (gh)
curl -fsSL \
  https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | dd of=/etc/apt/trusted.gpg.d/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/trusted.gpg.d/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
  | tee /etc/apt/sources.list.d/github-cli.list > /dev/null

sudo apt -y gh

### VIM

sudo apt -y install vim

# https://github.com/carlhuda/janus
curl -L https://bit.ly/janus-bootstrap | bash
ln -s vim/vimrc.before "${DOTFILES_DIR}/.vimrc.before"
ln -s vim/vimrc.after "${DOTFILES_DIR}/.vimrc.after"

### Golang

sudo apt install -y apt-transport-https gnupg curl
curl -1sLf 'https://dl.cloudsmith.io/public/go-swagger/go-swagger/gpg.2F8CB673971B5C9E.key' \
  | sudo apt-key add -
curl -1sLf 'https://dl.cloudsmith.io/public/go-swagger/go-swagger/config.deb.txt?distro=debian&codename=any-version' \
  | sudo tee /etc/apt/sources.list.d/go-swagger-go-swagger.list
sudo apt update
sudo apt install swagger

# symlinking

ln -s bash/bash_profile "${DOTFILES_DIR}/.bash_profile"
ln -s bin "${DOTFILES_DIR}"
ln -s bundler/config "${DOTFILES_DIR}/.bundle/config"
ln -s gem/gemrc "${DOTFILES_DIR}/.gemrc"
ln -s git/config "${DOTFILES_DIR}/.gitconfig"
ln -s git/gitattributes "${DOTFILES_DIR}/.gitattributes"
ln -s git/ignore "${DOTFILES_DIR}/.gitignore"
ln -s tmux/tmux.conf "${DOTFILES_DIR}/.gitignore"

if [ "${CODESPACES}" ]; then

fi

