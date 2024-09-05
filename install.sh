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
  bash zsh \
  vim \
  curl file tree silversearcher-ag bash-completion \
  tmux fzf jq

if ! command -v gem &> /dev/null; then
  sudo apt-get install -y ruby-full
  echo "installed gem version: $(gem --version)"
  echo "installed ruby version: $(ruby --version)"
else
  echo "gem is already installed: $(gem --version)"
  echo "ruby is already installed: $(ruby --version)"
fi

if ! command -v node &> /dev/null; then
  echo "Node.js is not installed. Installing Node.js..."
  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
  sudo apt-get install -y nodejs

elif [[ $(node -v | cut -d'.' -f1 | sed 's/v//') -lt 18 ]]; then
  echo "Node.js version is less than 18. Installing Node.js v18..."
  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
  sudo apt-get install -y nodejs

else
  echo "Node.js version $(node -v) is already installed."
fi

sudo rm -rf "${HOME}/.fnm"
curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell --install-dir "${HOME}/.fnm"
"${HOME}/.fnm/fnm" install v18
"${HOME}/.fnm/fnm" default v18

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
symlink nvim/init.vim .config/nvim/init.vim

banner "neovim: binary"

sudo rm -rf "${HOME}/tmp/nvim.appimage"
sudo rm -rf "${HOME}/tmp/squashfs-root"

curl -L https://github.com/neovim/neovim/releases/latest/download/nvim.appimage -o "${HOME}/tmp/nvim.appimage"
set +e
$(
	cd "${HOME}/tmp"
	chmod u+x nvim.appimage
	./nvim.appimage --appimage-extract
	sudo mv ./squashfs-root/usr/bin/nvim /usr/local/bin/nvim
	sudo chown -R $(whoami) squashfs-root
	sudo rm -rf "${HOME}/tmp/squashfs-root"
)
set -e

banner "neovim: neovim node package"
npm install -g neovim --silent --no-audit --no-fund --no-progress

banner "neovim: ruby gem"
sudo gem install neovim


