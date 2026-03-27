# wezterm-config

My WezTerm config. Built in one late-night session with Claude Code. 1000+ lines of Lua that turned a terminal emulator into a tiling window manager with a personality disorder.

## What's in the box

- **Tokyo Night** everything — tabs, status bar, mode indicators, all matched
- **Vim-inspired modal architecture** — 6 modes, each with its own keybindings and a colored status indicator:
  - `NORMAL` (green) — your default mode
  - `UI` (pink) — tab/pane/workspace management without leader prefix spam
  - `SCROLL` (teal) — man-page style scrolling (Space/b)
  - `COPY` (purple) — vim motions for text selection
  - `SEARCH` (yellow) — find in scrollback
  - `NAV` (orange) — fuzzy tree navigator across all workspaces/tabs/panes
- **Powerline tab bar** at the bottom with arrow separators
- **Workspace persistence** — save/restore full workspace state including pane splits and working directories
- **Zoxide-powered workspace picker** — fuzzy search your filesystem and running workspaces
- **Yazi integration** — terminal file manager opens in a new tab with `Leader+y`
- **Battery + clock** in the status bar because why not

## Keybindings

Leader key is `Ctrl+Space`.

### Normal Mode (Leader + key)

| Key | Action |
|-----|--------|
| `c` | New tab |
| `b` / `n` | Previous / next tab |
| `1`-`9` | Jump to tab by number |
| `\` | Vertical split |
| `-` | Horizontal split |
| `h/j/k/l` | Vim pane navigation |
| `x` | Close pane |
| `,` | Rename tab |
| `$` | Rename workspace |
| `w` | Workspace picker (zoxide) |
| `W` | Previous workspace |
| `y` | Open yazi file manager |
| `m` | NAV mode — tree navigator |

### Mode Entry (Leader + key)

| Key | Mode |
|-----|------|
| `u` | UI mode |
| `i` | Search mode |
| `o` | Scroll mode |
| `p` | Copy mode |
| `m` | Nav mode |

All modes exit with `Esc` or `q` (except Search — use `Esc` or `Ctrl+q`).

### Workspace Persistence (Leader + Shift + key)

| Key | Action |
|-----|--------|
| `S` | Save workspace (tabs + splits + cwds) |
| `R` | Restore saved workspace |
| `D` | Delete saved workspace |

Workspace state is saved to `workspaces.json` (gitignored — it's your local session data).

## Dependencies

```bash
brew install --cask wezterm@nightly
brew install zoxide          # smart cd, powers workspace picker
brew install yazi             # terminal file manager
```

Font: [JetBrainsMono Nerd Font](https://www.nerdfonts.com/)

## Install

```bash
# Back up your existing config
mv ~/.config/wezterm ~/.config/wezterm.bak

# Clone
git clone https://github.com/Akram012388/wezterm-config.git ~/.config/wezterm
```

## Philosophy

Ghostty for when you want a terminal that disappears.
WezTerm for when you want a terminal that does everything.

This config leans hard into the second one.

## License

MIT — take what you want, change what you don't.
