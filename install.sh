#!/usr/bin/env bash

set -ex

sudo apt-get update

DOTFILES_DIR=$(cd $(dirname "$0")/.. && pwd)

sudo apt-get -y install build-essential procps curl file git less
sudo apt-get install -y silversearcher-ag
sudo apt-get -y install ruby-full
sudo apt-get -y install bash-completion


### GitHub CLI (gh)

GH_VERSION=`curl  "https://api.github.com/repos/cli/cli/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | cut -c2-`

echo $GH_VERSION

curl -sSL https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz -o gh_${GH_VERSION}_linux_amd64.tar.gz

tar xvf gh_${GH_VERSION}_linux_amd64.tar.gz
sudo cp gh_${GH_VERSION}_linux_amd64/bin/gh /usr/local/bin/
gh version

### VIM

sudo apt-get -y install vim

# https://github.com/carlhuda/janus
curl -L https://bit.ly/janus-bootstrap | bash
ln -s vim/vimrc.before "${DOTFILES_DIR}/.vimrc.before"
ln -s vim/vimrc.after "${DOTFILES_DIR}/.vimrc.after"

### Golang

docker pull quay.io/goswagger/swagger
alias swagger='docker run --rm -it  --user $(id -u):$(id -g) -e GOPATH=$(go env GOPATH):/go -v $HOME:$HOME -w $(pwd) quay.io/goswagger/swagger'

swagger version
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

