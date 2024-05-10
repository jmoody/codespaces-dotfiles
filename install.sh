#!/usr/bin/env bash

set -e

source script/log.sh

mkdir -p "${HOME}/.config"

banner "ENV"

DOTFILES_DIR=$(cd $(dirname "$0")/.. && pwd)
echo "DOTFILES_DIR=${DOTFILES_DIR}"

# $1 source
# $2 target
function symlink {
  if [ "${2}" = "/" ]; then
    info "${DOTFILES_DIR}/dotfiles/${1} => ${HOME}/bin"
    ln -sf "${DOTFILES_DIR}/dotfiles/${1}" "${HOME}/"
  else
    info "${DOTFILES_DIR}/dotfiles/${1} => ${HOME}/${2}"
    ln -sf "${DOTFILES_DIR}/dotfiles/${1}" "${HOME}/${2}"
  fi
}

banner "apt-get"

sudo apt-get update
sudo apt-get -y install \
  build-essential procps curl file \
  less tree silversearcher-ag bash-completion \
  tmux zsh fzf \
  fonts-firacode \
  vim \
  jq \
  libssl-dev zlib1g-dev libreadline-dev autoconf bison libyaml-dev libncurses6 libffi-dev libgdbm-dev

if [ -f /usr/local/bin/ruby ]; then
  sudo apt remove -y ruby
  sudo apt clean
  sudo apt autoremove -y
  sudo apt -f install
fi

banner "zsh"

info "changing shell to $(which zsh) for $(whoami)"
sudo chsh -s $(which zsh) $(whoami)

banner "starship"

curl -fsSL https://starship.rs/install.sh -o install_starship.sh
chmod +x install_starship.sh
sudo ./install_starship.sh --force -y
rm ./install_starship.sh

banner "GitHub CLI (gh)"

if [ -f /usr/local/bin/gh ]; then
  version=$(gh version)
  info "gh ${version} is already installed"
else
  info "installing gh..."
  url="https://api.github.com/repos/cli/cli/releases/latest"
  version=$(curl -sSL "${url}" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | cut -c2-)
  info "will install gh version ${version}"
  url="https://github.com/cli/cli/releases/download/v${version}/gh_${version}_linux_amd64.tar.gz"
  curl -sSL ${url} -o gh_${version}_linux_amd64.tar.gz
  tar xvf gh_${version}_linux_amd64.tar.gz
  sudo cp gh_${version}_linux_amd64/bin/gh /usr/local/bin/
  sudo rm -rf gh_${version}_linux_amd64*
  info "installed gh ${version}"
fi

banner "goproxy/netrc"

echo "machine goproxy.githubapp.com login jmoody password ${GOPROXY_PAT}" > "${HOME}/.netrc"

info "set up goproxy in ${HOME}/.netrc"

banner "symlinking"

symlink bash/bashrc .bashrc
symlink bin "/"
mkdir -p "${HOME}/.bundle"
symlink bundler/config .bundle/config
symlink fzf .fzf
symlink gem/gemrc .gemrc
symlink git/config .gitconfig
symlink git/attributes .gitattributes
symlink git/ignore .gitignore
symlink tmux/tmux.conf .tmux.conf
symlink starship/starship.toml .config/starship.toml
symlink zsh/zshrc .zshrc
symlink vim/dotvimrc .vimrc
