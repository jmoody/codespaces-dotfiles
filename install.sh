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
  info "${DOTFILES_DIR}/dotfiles/${1} => ${HOME}/${2}"
  ln -sf "${DOTFILES_DIR}/dotfiles/${1}" "${HOME}/${2}"
}

banner "apt-get"

sudo apt-get update
sudo apt-get -y install \
  build-essential procps curl file \
  less tree silversearcher-ag bash-completion \
  tmux zsh fzf \
  fonts-firacode

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

banner "Go Swagger"

if [ -f /usr/local/bin/swagger ]; then
  version=$(swagger version)
  info "swagger ${version} is already installed"
else
  url="https://api.github.com/repos/go-swagger/go-swagger/releases/latest"
  url=$(curl -s ${url} | jq -r '.assets[] | select(.name | contains("'"$(uname | tr '[:upper:]' '[:lower:]')"'_amd64")) | .browser_download_url')
  sudo curl -sSL "${url}" -o /usr/local/bin/swagger
  sudo chmod +x /usr/local/bin/swagger
  info "installed swagger ${version}"
fi

banner "k9s"

if [ -f /usr/local/bin/k9s ]; then
  k9s version
else
  version="v0.25.18"
  mkdir -p tmp/k9s
  curl -sSL \
    https://github.com/derailed/k9s/releases/download/${version}/k9s_Linux_x86_64.tar.gz \
    -o tmp/k9s/k9s_Linux_x86_64.tar.gz
  pushd tmp/k9s
  tar xvf k9s_Linux_x86_64.tar.gz
  sudo cp k9s /usr/local/bin
  popd
  rm -rf tmp
  info "installed k9s ${version}"
fi

banner "ruby"

if [ -f /usr/local/bin/rbenv ]; then
  if [[ $(ruby --version | ag 3.1.0) ]]; then
    info "$(ruby --version)"
  else
    version="3.1.0"
    info "installing ruby ${version}"
    rbenv install 3.1.0
    rbenv global 3.1.0
  fi
else
  sudo apt-get -y install ruby-full
fi

banner "goproxy/netrc"

echo "machine goproxy.githubapp.com login jmoody password ${GOPROXY_PAT}" > "${HOME}/.netrc"

info "set up goproxy in ${HOME}/.netrc"

banner "vim"

sudo apt-get -y install vim
# https://github.com/carlhuda/janus
curl -sSL https://bit.ly/janus-bootstrap | bash
symlink vim/vimrc.before .vimrc.before
symlink vim/vimrc.after .vimrc.after

banner "exercism"

if [ -f /usr/local/bin/exercism ]; then
  info "$(exercism version)"
else
  version="3.0.13"
  release="exercism-${version}-linux-x86_64"
  mkdir -p "exercism"
  url="https://github.com/exercism/cli/releases/download/v${version}/${release}.tar.gz"
  curl -sSL "${url}" -o "exercism/${release}.tar.gz"
  pushd "exercism"
    tar xvf "${release}.tar.gz"
    sudo mv exercism /usr/local/bin/
  popd
  rm -rf exercism
  info "installed $(exercism version)"
fi

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
