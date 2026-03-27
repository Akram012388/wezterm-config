# wezterm-config

My WezTerm config. Built in one late-night session with Claude Code. 1200+ lines of Lua that turned a terminal emulator into a tiling window manager with a personality disorder.

## What's in the box

- **Tokyo Night** everything — tabs, status bar, mode indicators, all matched
- **Vim-inspired modal architecture** — 8 modes, each with its own keybindings and a colored status indicator:
  - `NORMAL` (green) — your default mode
  - `UI` (pink) — tab/pane/workspace management without leader prefix spam
  - `SCROLL` (teal) — man-page style scrolling (Space/b) with inline `/` search
  - `COPY` (purple) — vim motions for text selection
  - `SEARCH` (yellow) — find in scrollback
  - `MAP` (orange) — fuzzy tree navigator across all workspaces/tabs/panes with process icons
  - `HELP` (teal) — searchable keybinding cheat sheet
  - `LEADER` (yellow) — visual indicator when leader key is active
- **Powerline tab bar** at the bottom with arrow separators
- **Workspace persistence** — save/restore full workspace state including pane splits, working directories, and active tab/pane
- **Layout templates** — save your workspace arrangement as a reusable blueprint, launch it anytime with a custom name and base directory
- **Zoxide-powered workspace picker** — fuzzy search your filesystem and running workspaces
- **Yazi integration** — terminal file manager opens in a new tab with `Leader+y`
- **WebGPU rendering** — native Metal on Apple Silicon for smooth scrolling at 120fps
- **Battery + clock** in the status bar because why not

## Keybindings

Leader key is `Ctrl+Space`. A yellow `LEADER` pill appears in the status bar when active.

Press `Leader + ?` to open a fuzzy-searchable cheat sheet of all bindings from within WezTerm.

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
| `m` | MAP mode — tree navigator |
| `t` | Select and launch a layout template |
| `T` | Save current workspace as layout template |
| `?` | HELP mode — searchable keybinding reference |

### Mode Entry (Leader + key)

| Key | Mode |
|-----|------|
| `u` | UI mode |
| `i` | Search mode |
| `o` | Scroll mode |
| `p` | Copy mode |
| `m` | Map mode |
| `?` | Help mode |

All modes exit with `Esc` or `q` (except Search — use `Esc` or `Ctrl+q`).

### Workspace Persistence (Leader + Shift + key)

| Key | Action |
|-----|--------|
| `S` | Save workspace (tabs + splits + cwds + active pane) |
| `R` | Restore saved workspace (with full split reconstruction) |
| `D` | Delete saved workspace |

Workspace state is saved to `workspaces.json` (gitignored — it's your local session data).

### Layout Templates (Leader + key)

| Key | Action |
|-----|--------|
| `t` | Pick a template, name the workspace, set base directory, launch |
| `T` | Capture current workspace as a reusable template |

Templates are stored in `layouts/` as JSON — version controlled and shareable.

### Scroll Mode Keys

| Key | Action |
|-----|--------|
| `b` / `Space` | Half page up / down (man-page style) |
| `u` / `d` | Half page up / down |
| `j` / `k` | Line down / up |
| `g` / `G` | Top / bottom |
| `/` | Search inline (opens search without leaving scroll context) |

### Map Mode

Fuzzy-searchable tree of everything running:
- Workspaces with tab counts (`▶` marks current)
- Tabs with process icons (nvim, claude, yazi, node, python)
- Panes with active/inactive markers (`●` / `○`)
- Saved (not running) workspaces listed below a divider
- Select any item to jump directly to that workspace/tab/pane

## Companion tools

These aren't required but complete the setup:

```bash
# Terminal file manager
brew install yazi ffmpeg imagemagick poppler fd ripgrep fzf

# Shell enhancements
brew install zsh-autosuggestions zsh-syntax-highlighting

# Git diff tools
brew install git-delta difftastic
```

## Dependencies

```bash
brew install --cask wezterm@nightly
brew install zoxide          # smart cd, powers workspace picker
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
