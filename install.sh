#!/usr/bin/env bash

set -euo pipefail


DOTFILES_DIR=$(cd $(dirname "$0")/../dotfiles && pwd)

if [ ! -f "${DOTFILES_DIR}/script/log.sh" ]; then
  DOTFILES_DIR=$(cd $(dirname "$0")/.. && pwd)
fi

echo "DOTFILES_DIR=${DOTFILES_DIR}"
source "${DOTFILES_DIR}/script/log.sh"

mkdir -p "${HOME}/.config"
banner "ENV"

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
sudo apt-get -y install build-essential

# linuxbrew
NONINTERACTIVE=1 bash <(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
HOMEBREW_INSTALL_FROM_API=true  brew bundle install --no-lock --file ${DOTFILES_DIR}/Brewfile

banner "zsh"

info "changing shell to $(which zsh) for $(whoami)"
sudo chsh -s $(which zsh) $(whoami)

#banner "RUBY/RBENV"
#
#if ! command -v rbenv &> /dev/null; then
#  HOMEBREW_INSTALL_FROM_API=true  brew install --no-lock rbenv
#  rbenv install 3.3.5
#  echo "installed gem version: $(gem --version)"
#  echo "installed ruby version: $(ruby --version)"
#else
#  echo "gem is already installed: $(gem --version)"
#  echo "ruby is already installed: $(ruby --version)"
#fi
#
#banner "Node.js"
#
#if ! command -v node &> /dev/null; then
#  HOMEBREW_INSTALL_FROM_API=true  brew install --no-lock fnm
#  fnm install v22
#else
#  echo "Node.js version $(node -v) is already installed."
#fi
#
#banner "kubectl"
#
#if ! command -v kubectl &> /dev/null; then
#  echo "kubectl is not installed. Installing kubectl..."
#  curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
#  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
#  rm kubectl
#  echo "installed kubectl: $(kubectl version --client | head -n 1)"
#else
#  echo "kubectl is already installed: $(kubectl version --client | head -n 1)"
#fi
#
#sudo rm -rf "${HOME}/.fnm"
#curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell --install-dir "${HOME}/.fnm"
#"${HOME}/.fnm/fnm" install v18
#"${HOME}/.fnm/fnm" default v18
#
# banner "starship"

#curl -fsSL https://starship.rs/install.sh -o install_starship.sh
#chmod +x install_starship.sh
#sudo ./install_starship.sh --force -y
#rm ./install_starship.sh

#banner "GitHub CLI (gh)"
#
#if [ -f /usr/local/bin/gh ]; then
#  version=$(gh version)
#  info "gh ${version} is already installed"
#else
#  info "installing gh..."
#  url="https://api.github.com/repos/cli/cli/releases/latest"
#  version=$(curl -sSL "${url}" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | cut -c2-)
#  info "will install gh version ${version}"
#  url="https://github.com/cli/cli/releases/download/v${version}/gh_${version}_linux_amd64.tar.gz"
#  curl -sSL ${url} -o gh_${version}_linux_amd64.tar.gz
#  tar xvf gh_${version}_linux_amd64.tar.gz
#  sudo cp gh_${version}_linux_amd64/bin/gh /usr/local/bin/
#  sudo rm -rf gh_${version}_linux_amd64*
#  info "installed gh ${version}"
#fi

#banner "goproxy/netrc"
#
#echo "machine goproxy.githubapp.com login jmoody password ${GOPROXY_PAT}" > "${HOME}/.netrc"
#
#info "set up goproxy in ${HOME}/.netrc"

banner "symlinking"

mkdir -p "${HOME}/.bundle"
mkdir -p "${HOME}/.config"
mkdir -p "${HOME}/.config/nvim"
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
