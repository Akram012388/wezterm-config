# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A personal WezTerm terminal-emulator config. Everything lives in a single `wezterm.lua`
(~1500 lines) — it is intentionally monolithic, not split into modules. The file is
organized top-to-bottom into sections separated by `---` ASCII dividers (font/window,
colors, mouse, cursor, events, workspace persistence, layout templates, key tables,
keybindings). Add new settings to the relevant existing section rather than creating new files.

## Formatting, linting, syntax-check

No build step or test suite. WezTerm auto-reloads `wezterm.lua` on save (the default;
`automatically_reload_config` is not set), so a syntax error breaks the live, running terminal.
Three tools guard `.lua` files, all configured to match this repo's style:

- Format: `stylua wezterm.lua` (`stylua.toml`)
- Lint: `selene wezterm.lua` (`selene.toml` + `wezterm.yml` std extension)
- Syntax-check: `luajit -bl wezterm.lua /dev/null` (parses/compiles without executing, so
  `require("wezterm")` never runs)

A PostToolUse hook (`.claude/settings.json`) runs all three on every `.lua` edit: stylua
auto-formats, then luajit and selene **block** (exit 2) on syntax errors or lint findings.
Keep the file stylua-clean and selene-clean — the baseline is zero findings.

Selene notes: prefix intentionally-unused function/callback params with `_` (WezTerm passes
positional args many handlers don't use). The Homebrew selene build ships only the Lua 5.1 std,
so `selene.toml` suppresses false positives against WezTerm's Lua 5.4 (`\x` escapes, the
compact single-line `if` style, intentional shared icons) and `wezterm.yml` adds the `utf8` library.

## Conventions

- Lua: `snake_case` for locals/functions, `UPPERCASE` for constants (e.g. `SOLID_RIGHT`), 2-space indent.
- Modern API: `config = wezterm.config_builder()`; assign settings to `config`; the file ends with `return config`.
- Targets WezTerm **nightly** — newer API features are expected to be available.

## Modal architecture

The config implements 8 modes, each with a colored status-bar pill (see the `mode_colors`
table). Most modes use WezTerm key tables, but MAP and HELP modes use `InputSelector`
(which can't use key tables), so their active state is tracked per-window in the
`map_active` / `help_active` tables. When changing mode logic, keep those tables in sync.

## Gotchas

- `workspaces.json` is local session state and is **gitignored** — never commit it. The `layouts/` JSON templates ARE version-controlled.
- Pane/tab cwds arrive as `file://host/path` URIs; strip the prefix with `:gsub("^file://[^/]*", "")` before using the path.
- Expand `~` manually with `:gsub("^~", home)` — WezTerm does not do it for you.
- Leader key is `Ctrl+Space` with a 1-second timeout.
- The config shells out to `zoxide` (workspace picker) and `yazi` (file manager, `Leader+y`); these are external dependencies.
