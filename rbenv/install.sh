#!/usr/bin/env bash

set -e

source script/log.sh

DOTFILES_DIR="${1}"
RUBY_VERSION="${2}"
RBENV_DIR="${HOME}/.rbenv"

if [ ! -d "${RBENV_DIR}" ]; then
  git clone https://github.com/rbenv/rbenv.git "${RBENV_DIR}"
  cd "${RBENV_DIR}" && src/configure && make -C src
  export PATH="${RBENV_DIR}/bin:${PATH}"
  mkdir -p "${RBENV_DIR}/plugins"
  git clone https://github.com/rbenv/ruby-build.git "${RBENV_DIR}/plugins/ruby-build"
  git clone https://github.com/rbenv/rbenv-default-gems.git \
    "${RBENV_DIR}/plugins/rbenv-default-gems"
  ln -sf "${DOTFILES_DIR}/dotfiles/rbenv/default-gems" "${RBENV_DIR}"
  ln -sf "${DOTFILES_DIR}/dotfiles/rbenv/gemrc" "${RBENV_DIR}"
  rbenv install "${RUBY_VERSION}"
  rbenv global "${RUBY_VERSION}"
else
  export PATH="${RBENV_DIR}/bin:${PATH}"
  eval "$(rbenv init - bash)"
  cd "${RBENV_DIR}" && git pull
  cd "${RBENV_DIR}/plugins/ruby-build" && git pull
  cd "${RBENV_DIR}/plugins/rbenv-default-gems" && git pull

  gem update --system
  gem update
fi
