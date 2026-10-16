## Dotfiles

For codespaces.

### GitHub Copilot CLI

`script/install-copilot.sh` installs the Copilot CLI configuration into `$HOME/.copilot`. `install.sh` calls it after Homebrew, because the script needs `gh`. You can also run it on its own.

The steps that need the network warn instead of failing, so a container without credentials still gets the local files.

#### What it installs

| Item                      | Source                               | How                                |
| ------------------------- | ------------------------------------ | ---------------------------------- |
| `copilot-instructions.md` | `copilot/copilot-instructions.md.in` | rendered, `@HOME@` becomes `$HOME` |
| `settings.json`           | `copilot/settings.json`              | copy                               |
| `mcp-config.json`         | `copilot/mcp-config.json`            | symlink                            |
| vendored skills           | `copilot/skills/`                    | symlink for each skill             |
| managed skills            | GitHub repositories                  | `gh skill install`                 |
| plugins                   | marketplaces in `settings.json`      | `copilot plugin install`           |

`settings.json` is a copy, not a symlink, because `copilot plugin install` rewrites the file and the rewrite replaces a symlink. Edit `copilot/settings.json` and run the script again.

Vendored skills are the ones with no upstream repository, so this repository is their only source: `ace-fca-review-plan`, `adr-author`, `fix-markdown`, and `replan-batch-tasks`. Edit them here, not in `$HOME/.copilot/skills`.

Managed skills come from GitHub and are listed in `MANAGED_SKILLS`: `adversarial-review`, `ponytail-review`, and `dd-pup`. `gh skill install` copies files and keeps no git history, so any local edit to a managed skill is lost on the next install. Keep your changes in a vendored skill instead.

Plugins are listed in `PLUGINS`. A plugin is a bundle that can carry several skills and its own MCP servers, so `port` and `gho11y` are not in `MANAGED_SKILLS`. The `port` plugin also supplies the Port MCP server, which is why `copilot/mcp-config.json` must never declare one.

#### Requirements

- `gh` must be authenticated. In a codespace the `GITHUB_TOKEN` variable supplies this. The script sets `gh` as the git credential helper for `github.com`, because `copilot plugin install` clones the private marketplace repositories with git. It does not use `gh auth setup-git`, which refuses a token that comes from the environment.
- The Copilot CLI comes from npm on the `prerelease` tag, and `settings.json` sets `autoUpdatesChannel` to `prerelease` to match.
- `pup` comes from the Brewfile and needs `pup auth login` once, in a browser.

#### Secrets

Never copy `~/.copilot/mcp-config.json` from a workstation into this repository. It can hold tokens in cleartext and can call macOS-only tools such as `security find-generic-password`. The version here is written by hand and holds no credentials.

