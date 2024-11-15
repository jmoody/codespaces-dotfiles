#!/usr/bin/env bash

set -euo pipefail

docker build --platform linux/amd64 -t dotfiles .
docker run --platform linux/amd64 --rm -it dotfiles:latest bash
