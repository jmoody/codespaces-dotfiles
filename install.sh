#!/usr/bin/env bash

set -e

source script/log.sh

banner "ENV"

DOTFILES_DIR=$(cd $(dirname "$0")/.. && pwd)
echo "DOTFILES_DIR=${DOTFILES_DIR}"

# $1 source
# $2 target
function symlink {
  ln -sf "${DOTFILES_DIR}/${1}" "${HOME}/${2}"
}

banner "apt-get"

sudo apt-get update
sudo apt-get -y install build-essential procps curl file git less
sudo apt-get -y install silversearcher-ag
sudo apt-get -y install ruby-full
sudo apt-get -y install bash-completion

banner "GitHub CLI (gh)"

if [ -f /usr/local/bin/gh ]; then
  version=$(gh version)
  info "gh ${version} is already installed"
else
  info "installing gh..."
  url="https://api.github.com/repos/cli/cli/releases/latest"
  version=$(curl "${url}" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | cut -c2-)
  info "will instal gh version ${version}"
  url="https://github.com/cli/cli/releases/download/v${version}/gh_${version}_linux_amd64.tar.gz"
  curl -sSL ${url} -o gh_${version}_linux_amd64.tar.gz
  tar xvf gh_${version}_linux_amd64.tar.gz
  sudo cp gh_${version}_linux_amd64/bin/gh /usr/local/bin/
  info "installed gh ${version}"
fi

banner "Installing Go Swagger"

if [ -f /usr/local/bin/swagger ]; then
  version=$(swagger version)
  info "swagger ${version} is already installed"
else
  url="https://api.github.com/repos/go-swagger/go-swagger/releases/latest"
  url=$(curl -s ${url} | jq -r '.assets[] | select(.name | contains("'"$(uname | tr '[:upper:]' '[:lower:]')"'_amd64")) | .browser_download_url')
  sudo curl -o /usr/local/bin/swagger -L'#' "$url"
  sudo chmod +x /usr/local/bin/swagger
  info "installed swagger ${version}"
fi

banner "vim"

sudo apt-get -y install vim
# https://github.com/carlhuda/janus
curl -L https://bit.ly/janus-bootstrap | bash
ln -sf ${DOTFILES_DIR}/vim/vimrc.before "${HOME}/.vimrc.before"
ln -sf vim/vimrc.after "${DOTFILES_DIR}/.vimrc.after"

banner "symlinking"
symlink bash/bash_profile .bash_profile
symlink bin bin
mkdir -p "${HOME}/.bundle"
symlink bundler/config .bundle/config
symlink gem/gemrc .gemrc
symlink git/config .gitconfig
symlink git/attributes .gitattributes
symlink git/ignore .gitignore
symlink tmux/tmux.conf .tmux.conf
