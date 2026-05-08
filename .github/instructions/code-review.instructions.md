---
description: Instructions for GitHub Copilot when reviewing pull requests for the codespaces-dotfiles repository
applyTo: "**/*.*"
---

# Code review instructions

This is a GitHub Codespaces dotfiles repository. It configures development environments by symlinking configuration files and installing tools via Homebrew when a codespace is created.

Review priority (highest to lowest): 1. correctness, 2. portability, 3. security, 4. style.

## Repository structure

- `install.sh` - Main entry point executed by Codespaces on creation
- `script/` - Helper scripts (logging, apt lock waiting, testing)
- `Brewfile` - Homebrew packages to install
- `Dockerfile` - For local testing of the install process
- `bash/`, `zsh/`, `tmux/`, `git/`, `nvim/`, `starship/`, `fzf/`, `bundler/`, `gem/`, `rbenv/` - Configuration directories symlinked to `$HOME`
- `bin/` - Scripts symlinked to `$HOME/bin`

## Shell script checks

All scripts in this repo must follow `.github/instructions/bash-scripting.instructions.md`. Key checks:

- `set -euo pipefail` required at the top of every script
- `[[ ]]` required instead of `[ ]` for conditionals
- Variable quoting: `"${var}"` not `$var`
- Flag working directory assumptions (relative paths without resolving script dir first)
- Flag sourcing files without checking the file exists first
- Flag `2>/dev/null` on commands whose failure matters
- `set -e` gotchas: command substitution inside `local` or `readonly` masks the exit code. Declare and assign separately.
- `set -u` interactions: expanding an unset variable exits before reaching `test -n` or `-z`. Use `"${VAR:-}"` to provide an empty default.
- For each `jq`, `curl`, or command substitution, what happens if it returns empty, null, or malformed data?

## Symlink and path checks

- Verify symlink source paths in `install.sh` match actual files/directories in the repo
- Verify symlink target paths use correct `$HOME` relative locations
- Flag symlinks that would overwrite important existing files without backup
- Verify `mkdir -p` is called for parent directories before symlinking into them

## Brewfile checks

- Flag packages without a clear purpose in a codespace environment
- Verify package names are valid Homebrew formulae
- Flag `brew cask` entries (not available on Linux)
- Prefer explicit tap declarations when packages come from non-default taps

## Dockerfile checks

- Multiline `RUN` commands must use HEREDOC syntax, not backslash continuations (see `.github/instructions/docker.instructions.md`)
- Verify `COPY` paths match actual repo structure
- Flag `latest` tags in `FROM` statements (pin to a specific version for reproducibility)
- Flag secrets passed via `ARG` or `ENV`
- Verify the Dockerfile mirrors what `install.sh` expects (same directory structure, same user)

## Configuration file checks

For dotfiles (zsh, git, tmux, nvim, starship, etc.):

- Flag hardcoded absolute paths that assume a specific username or home directory
- Flag references to tools not installed by the Brewfile or install script
- Verify environment variable exports are consistent across shell configs
- Flag duplicate `PATH` entries or conflicting `PATH` modifications
- For git config: flag user-specific settings that should not be committed (credentials, signing keys)

## Portability concerns

- This repo targets Linux (Ubuntu) in GitHub Codespaces
- Flag macOS-only commands (`pbcopy`, `open`, `brew cask`) without Linux alternatives
- Flag assumptions about the shell being bash when zsh is the configured default
- Verify `apt-get` commands work on Ubuntu and include `-y` for non-interactive use
- Flag commands that require user interaction without providing non-interactive alternatives

## Security

- Flag secrets, tokens, or credentials hardcoded in any file
- Flag overly permissive file permissions on sensitive config files
- Verify `sudo` usage is necessary and scoped appropriately
- Flag `curl | bash` patterns without checksum verification (acceptable for well-known installers like Homebrew with explicit acknowledgment)

## Documentation accuracy

- Comments, script usage text, and inline comments must match actual behavior
- README should reflect the current state of what gets installed and configured
- When a file or directory is removed, verify references in install.sh and README are also updated

## Review tone

- Prioritize reliability and portability across codespace environments
- Provide specific examples of improvements
- Reference relevant patterns already established in the codebase
