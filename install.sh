#!/usr/bin/env bash

set -euo pipefail


DOTFILES_DIR=$(cd $(dirname "$0")/../dotfiles && pwd)

if [ ! -f "${DOTFILES_DIR}/script/log.sh" ]; then
  DOTFILES_DIR=$(cd $(dirname "$0")/.. && pwd)
fi

echo "DOTFILES_DIR=${DOTFILES_DIR}"
source "${DOTFILES_DIR}/script/log.sh"
source "${DOTFILES_DIR}/script/wait-for-apt.sh"

mkdir -p "${HOME}/.config"
banner "ENV"

# $1 source
# $2 target
function symlink {
  if [ "${2}" = "/" ]; then
    info "${DOTFILES_DIR}/${1} => ${HOME}/bin"
    ln -sf "${DOTFILES_DIR}/${1}" "${HOME}/"
  else
    info "${DOTFILES_DIR}/${1} => ${HOME}/${2}"
    ln -sf "${DOTFILES_DIR}/${1}" "${HOME}/${2}"
  fi
}

banner "apt-get"

# Wait for any existing apt processes to complete before running our updates
wait_for_apt_lock || {
  echo "Failed to acquire apt lock within timeout, but continuing anyway..."
}

sudo apt-get update
sudo apt-get -y install build-essential

# linuxbrew
NONINTERACTIVE=1 bash <(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
HOMEBREW_INSTALL_FROM_API=true  brew bundle install --file ${DOTFILES_DIR}/Brewfile

banner "zsh"

info "changing shell to $(which zsh) for $(whoami)"
sudo chsh -s $(which zsh) $(whoami)

banner "symlinking"

mkdir -p "${HOME}/.bundle"
mkdir -p "${HOME}/.config"
mkdir -p "${HOME}/tmp"

symlink bash/bashrc .bashrc
symlink bin "/"
symlink bundler/config .bundle/config
symlink fzf .fzf
symlink gem/gemrc .gemrc
symlink git/config .gitconfig
symlink git/attributes .gitattributes
symlink git/ignore .gitignore
symlink tmux/tmux.conf .tmux.conf
symlink starship/starship.toml .config/starship.toml
symlink zsh/zshrc .zshrc
symlink nvim .config/nvim
