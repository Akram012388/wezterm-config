local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

-- Powerline arrow characters
local SOLID_RIGHT = utf8.char(0xe0b0)
local THIN_RIGHT = utf8.char(0xe0b1)

-- Workspace state file
local state_file = os.getenv("HOME") .. "/.config/wezterm/workspaces.json"

-- Layout templates directory
local layouts_dir = os.getenv("HOME") .. "/.config/wezterm/layouts"

-- Nav/Help mode flags (InputSelector doesn't use key tables)
local map_active = {}
local help_active = {}

-- Font
config.font = wezterm.font("JetBrainsMono Nerd Font")
config.font_size = 14.0

-- Window
config.window_decorations = "RESIZE"
config.window_padding = { left = 20, right = 20, top = 16, bottom = 16 }
config.macos_window_background_blur = 20
config.window_background_opacity = 0.92

-- Retro tab bar at bottom (needed for powerline arrows)
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = true
config.tab_max_width = 32

-- Color scheme
config.color_scheme = "Tokyo Night"

-- Tokyo Night palette
local bg = "#1a1b26"
local active_bg = "#7aa2f7"
local active_fg = "#1a1b26"
local inactive_bg = "#24283b"
local inactive_fg = "#565f89"

-- Mode colors
local mode_colors = {
  normal  = { bg = "#9ece6a", fg = "#1a1b26", label = " NORMAL " },
  copy_mode = { bg = "#bb9af7", fg = "#1a1b26", label = " COPY " },
  search_mode = { bg = "#e0af68", fg = "#1a1b26", label = " SEARCH " },
  scroll_mode = { bg = "#7dcfff", fg = "#1a1b26", label = " SCROLL " },
  ui_mode = { bg = "#f7768e", fg = "#1a1b26", label = " UI " },
  map_mode = { bg = "#ff9e64", fg = "#1a1b26", label = " MAP " },
  help_mode = { bg = "#73daca", fg = "#1a1b26", label = " HELP " },
}

config.colors = {
  tab_bar = {
    background = bg,
    new_tab = { bg_color = bg, fg_color = inactive_fg },
    new_tab_hover = { bg_color = "#292e42", fg_color = "#c0caf5" },
  },
}

-- Pane dividers
config.inactive_pane_hsb = { saturation = 0.8, brightness = 0.7 }
config.colors.split = "#7aa2f7"

-- Cursor
config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 500
config.colors.cursor_bg = "#7aa2f7"
config.colors.cursor_fg = "#1a1b26"
config.colors.cursor_border = "#7aa2f7"

-- Scrollback
config.scrollback_lines = 10000

-- Smooth scrolling
config.enable_scroll_bar = false
config.min_scroll_bar_height = "1cell"
config.use_resize_increments = false

-- Front-end rendering (WebGpu = smoother on Apple Silicon)
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"

-- Frame rate
config.max_fps = 120
config.animation_fps = 120

-- Leader key: Ctrl+Space (1s timeout)
config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1000 }

-------------------------------------------------------------------------------
-- Tab title formatting
-------------------------------------------------------------------------------

wezterm.on("format-tab-title", function(tab, tabs, panes, cfg, hover, max_width)
  local index = tab.tab_index + 1
  local custom = tab.tab_title
  local title = (custom and #custom > 0) and custom or tab.active_pane.title
  if not title or #title == 0 then title = "shell" end
  -- Strip WezTerm's internal "Copy mode: " prefix from tab title
  title = title:gsub("^Copy mode: ", "")

  local is_active = tab.is_active
  local tab_bg = is_active and active_bg or inactive_bg
  local tab_fg = is_active and active_fg or inactive_fg

  local next_tab = tabs[tab.tab_index + 2]
  local next_bg = bg
  if next_tab then
    next_bg = next_tab.is_active and active_bg or inactive_bg
  end

  return {
    { Background = { Color = tab_bg } },
    { Foreground = { Color = tab_fg } },
    { Text = " " .. index .. ": " .. title .. " " },
    { Background = { Color = next_bg } },
    { Foreground = { Color = tab_bg } },
    { Text = SOLID_RIGHT },
  }
end)

-------------------------------------------------------------------------------
-- Status bar: workspace left, mode + battery + time right
-------------------------------------------------------------------------------

wezterm.on("update-status", function(window, pane)
  local workspace = window:active_workspace()

  -- Determine the first tab's bg color for the arrow transition
  local first_tab_bg = inactive_bg
  local mux_win = window:mux_window()
  if mux_win then
    local tabs = mux_win:tabs_with_info()
    if tabs and #tabs > 0 and tabs[1].is_active then
      first_tab_bg = active_bg
    end
  end

  window:set_left_status(wezterm.format({
    { Background = { Color = "#ff9e64" } },
    { Foreground = { Color = "#1a1b26" } },
    { Attribute = { Intensity = "Bold" } },
    { Text = "  " .. workspace .. " " },
    { Background = { Color = first_tab_bg } },
    { Foreground = { Color = "#ff9e64" } },
    { Text = SOLID_RIGHT },
  }))

  -- Detect current mode
  local key_table = window:active_key_table()
  local win_id = tostring(window:window_id())
  local leader_active = window:leader_is_active()
  local mode = mode_colors.normal
  if help_active[win_id] then
    mode = mode_colors.help_mode
  elseif map_active[win_id] then
    mode = mode_colors.map_mode
  elseif key_table == "copy_mode" then
    mode = mode_colors.copy_mode
  elseif key_table == "search_mode" then
    mode = mode_colors.search_mode
  elseif key_table == "scroll_mode" then
    mode = mode_colors.scroll_mode
  elseif key_table == "ui_mode" then
    mode = mode_colors.ui_mode
  end

  -- Right status: battery + time + leader indicator + mode indicator
  local date = wezterm.strftime("%a %b %-d  %H:%M")
  local bat = ""
  for _, b in ipairs(wezterm.battery_info()) do
    local charge = math.floor(b.state_of_charge * 100 + 0.5)
    local icon = ""
    if charge >= 75 then icon = "󰁹"
    elseif charge >= 50 then icon = "󰁾"
    elseif charge >= 25 then icon = "󰁼"
    else icon = "󰁺"
    end
    bat = icon .. " " .. charge .. "%%"
  end

  local right_elements = {
    { Foreground = { Color = inactive_fg } },
    { Background = { Color = bg } },
    { Text = bat .. "   " .. date .. "  " },
  }

  -- Leader key indicator: flash a pill when leader is active
  if leader_active then
    table.insert(right_elements, { Background = { Color = "#e0af68" } })
    table.insert(right_elements, { Foreground = { Color = "#1a1b26" } })
    table.insert(right_elements, { Attribute = { Intensity = "Bold" } })
    table.insert(right_elements, { Text = " ⌨ LEADER " })
    table.insert(right_elements, "ResetAttributes")
  end

  -- Mode indicator
  table.insert(right_elements, { Background = { Color = mode.bg } })
  table.insert(right_elements, { Foreground = { Color = mode.fg } })
  table.insert(right_elements, { Attribute = { Intensity = "Bold" } })
  table.insert(right_elements, { Text = mode.label })

  window:set_right_status(wezterm.format(right_elements))
end)

-------------------------------------------------------------------------------
-- Workspace persistence helpers
-------------------------------------------------------------------------------

local function read_state()
  local f = io.open(state_file, "r")
  if not f then return {} end
  local raw = f:read("*a")
  f:close()
  local ok, data = pcall(wezterm.json_parse, raw)
  if ok and data then return data end
  return {}
end

local function write_state(data)
  local f = io.open(state_file, "w")
  if not f then return end
  f:write(wezterm.json_encode(data))
  f:close()
end

-- Helper: clean cwd from file:// URI to path
local function clean_cwd(raw)
  if not raw then return os.getenv("HOME") end
  local s = tostring(raw):gsub("^file://[^/]*", "")
  if s == "" then return os.getenv("HOME") end
  return s
end

-- Helper: build a split tree from a list of panes with positions
-- Returns a tree node: either a leaf (single pane) or a split with two children
local function build_split_tree(panes)
  if #panes == 1 then
    local p = panes[1]
    return {
      type = "leaf",
      cwd = clean_cwd(p.pane:get_current_working_dir()),
      process = p.pane:get_foreground_process_name() or "",
      is_active = p.is_active,
      left = p.left,
      top = p.top,
      width = p.width,
      height = p.height,
    }
  end

  -- Find bounds of this group
  local min_left, min_top = math.huge, math.huge
  local max_right, max_bottom = 0, 0
  for _, p in ipairs(panes) do
    min_left = math.min(min_left, p.left)
    min_top = math.min(min_top, p.top)
    max_right = math.max(max_right, p.left + p.width)
    max_bottom = math.max(max_bottom, p.top + p.height)
  end
  local total_width = max_right - min_left
  local total_height = max_bottom - min_top

  -- Try vertical split (left | right) — find a column where panes divide cleanly
  local left_edges = {}
  for _, p in ipairs(panes) do
    left_edges[p.left + p.width] = true
  end
  for split_col, _ in pairs(left_edges) do
    if split_col > min_left and split_col < max_right then
      local left_group, right_group = {}, {}
      local clean = true
      for _, p in ipairs(panes) do
        if p.left + p.width <= split_col then
          table.insert(left_group, p)
        elseif p.left >= split_col then
          table.insert(right_group, p)
        else
          clean = false
          break
        end
      end
      if clean and #left_group > 0 and #right_group > 0 then
        return {
          type = "split",
          direction = "Right",
          ratio = (split_col - min_left) / total_width,
          children = {
            build_split_tree(left_group),
            build_split_tree(right_group),
          },
        }
      end
    end
  end

  -- Try horizontal split (top | bottom)
  local top_edges = {}
  for _, p in ipairs(panes) do
    top_edges[p.top + p.height] = true
  end
  for split_row, _ in pairs(top_edges) do
    if split_row > min_top and split_row < max_bottom then
      local top_group, bottom_group = {}, {}
      local clean = true
      for _, p in ipairs(panes) do
        if p.top + p.height <= split_row then
          table.insert(top_group, p)
        elseif p.top >= split_row then
          table.insert(bottom_group, p)
        else
          clean = false
          break
        end
      end
      if clean and #top_group > 0 and #bottom_group > 0 then
        return {
          type = "split",
          direction = "Bottom",
          ratio = (split_row - min_top) / total_height,
          children = {
            build_split_tree(top_group),
            build_split_tree(bottom_group),
          },
        }
      end
    end
  end

  -- Fallback: couldn't determine split, save first pane as leaf
  local p = panes[1]
  return {
    type = "leaf",
    cwd = clean_cwd(p.pane:get_current_working_dir()),
    process = p.pane:get_foreground_process_name() or "",
    is_active = p.is_active,
  }
end

-- Helper: restore a split tree into a given pane
-- Returns the pane that should be focused (if any)
local function restore_split_tree(tree, target_pane)
  if tree.type == "leaf" then
    -- Send cd command to reach the right directory
    local cwd = tree.cwd or os.getenv("HOME")
    target_pane:send_text("cd " .. wezterm.shell_quote_arg(cwd) .. " && clear\n")
    if tree.is_active then
      return target_pane
    end
    return nil
  end

  -- Calculate size for the new (second) pane as a fraction
  local size = 1.0 - tree.ratio

  -- Split the target pane
  local new_pane = target_pane:split({
    direction = tree.direction,
    size = size,
    cwd = os.getenv("HOME"),
  })

  -- Recurse: first child stays in target_pane, second child in new_pane
  local focus1 = restore_split_tree(tree.children[1], target_pane)
  local focus2 = restore_split_tree(tree.children[2], new_pane)

  return focus1 or focus2
end

-- Save workspace: full state with splits, processes, focus
wezterm.on("save-workspace", function(window, pane)
  local workspace = window:active_workspace()
  local tabs = {}
  local active_tab_idx = 0

  for _, tab in ipairs(window:mux_window():tabs()) do
    local tab_title = tab:get_title() or ""
    local panes = tab:panes_with_info()

    -- Build split tree for this tab
    local split_tree = build_split_tree(panes)

    -- Count panes and collect process info
    local process_list = {}
    for _, p in ipairs(panes) do
      local proc = p.pane:get_foreground_process_name() or ""
      if proc ~= "" then
        table.insert(process_list, proc)
      end
    end

    -- Check if this is the active tab
    local is_active_tab = false
    if tab:tab_id() == window:active_tab():tab_id() then
      is_active_tab = true
      active_tab_idx = #tabs
    end

    table.insert(tabs, {
      title = tab_title,
      split_tree = split_tree,
      pane_count = #panes,
      processes = process_list,
      is_active = is_active_tab,
    })
  end

  local state = read_state()
  state[workspace] = {
    tabs = tabs,
    active_tab = active_tab_idx,
    saved_at = os.date("%Y-%m-%d %H:%M:%S"),
  }
  write_state(state)

  -- Build summary
  local total_panes = 0
  for _, t in ipairs(tabs) do
    total_panes = total_panes + t.pane_count
  end
  window:toast_notification("WezTerm",
    "Workspace '" .. workspace .. "' saved\n" ..
    #tabs .. " tabs, " .. total_panes .. " panes",
    nil, 3000)
end)

-- Restore workspace: full state with splits
wezterm.on("restore-workspace", function(window, pane)
  local state = read_state()
  local choices = {}
  for name, data in pairs(state) do
    local n = data.tabs and #data.tabs or 0
    local total_panes = 0
    local procs = {}
    for _, t in ipairs(data.tabs or {}) do
      total_panes = total_panes + (t.pane_count or 1)
      for _, p in ipairs(t.processes or {}) do
        local short = p:match("([^/]+)$") or p
        procs[short] = true
      end
    end
    local proc_str = ""
    local proc_list = {}
    for p, _ in pairs(procs) do table.insert(proc_list, p) end
    if #proc_list > 0 then
      proc_str = " [" .. table.concat(proc_list, ", ") .. "]"
    end
    local saved_at = data.saved_at or "unknown"
    table.insert(choices, {
      label = name .. " (" .. n .. " tabs, " .. total_panes .. " panes)" .. proc_str .. " — " .. saved_at,
      id = name,
    })
  end
  if #choices == 0 then
    window:toast_notification("WezTerm", "No saved workspaces", nil, 3000)
    return
  end
  window:perform_action(
    act.InputSelector({
      title = "Restore Workspace",
      choices = choices,
      action = wezterm.action_callback(function(win, _, id, label)
        if not id then return end
        local ws = state[id]
        if not ws or not ws.tabs then return end

        -- Check if this workspace already exists (is running)
        local existing = false
        for _, name in ipairs(wezterm.mux.get_workspace_names()) do
          if name == id then
            existing = true
            break
          end
        end

        -- Use a unique restore name to avoid colliding with running workspaces
        local restore_name = id
        if existing then
          -- Find a unique name with incrementing suffix
          local n = 2
          restore_name = id .. " (2)"
          while true do
            local taken = false
            for _, name in ipairs(wezterm.mux.get_workspace_names()) do
              if name == restore_name then taken = true; break end
            end
            if not taken then break end
            n = n + 1
            restore_name = id .. " (" .. n .. ")"
          end
        end

        -- Create workspace with first tab
        local first_tab = ws.tabs[1]
        local first_cwd = os.getenv("HOME")
        if first_tab and first_tab.split_tree and first_tab.split_tree.cwd then
          first_cwd = first_tab.split_tree.cwd
        end

        win:perform_action(act.SwitchToWorkspace({
          name = restore_name,
          spawn = { cwd = first_cwd },
        }), pane)

        -- Delay for workspace switch to complete, then restore tabs with splits
        wezterm.time.call_after(0.5, function()
          -- Get the new workspace's window
          local target_win = nil
          for _, mux_win in ipairs(wezterm.mux.all_windows()) do
            if mux_win:get_workspace() == restore_name then
              target_win = mux_win
              break
            end
          end
          if not target_win then return end

          -- First tab already exists (created by SwitchToWorkspace), restore its splits
          local existing_tabs = target_win:tabs()
          if #existing_tabs > 0 and first_tab then
            restore_split_tree(first_tab.split_tree, existing_tabs[1]:active_pane())
            if first_tab.title and #first_tab.title > 0 then
              existing_tabs[1]:set_title(first_tab.title)
            end
          end

          -- Create remaining tabs with splits
          for i = 2, #ws.tabs do
            local tab_data = ws.tabs[i]
            local tab_cwd = os.getenv("HOME")
            if tab_data.split_tree and tab_data.split_tree.cwd then
              tab_cwd = tab_data.split_tree.cwd
            end

            local new_tab, new_pane, new_win = target_win:spawn_tab({
              cwd = tab_cwd,
            })

            if tab_data.split_tree then
              restore_split_tree(tab_data.split_tree, new_pane)
            end

            if tab_data.title and #tab_data.title > 0 then
              new_tab:set_title(tab_data.title)
            end
          end

          -- Activate the previously active tab
          local active_idx = ws.active_tab or 0
          local all_tabs = target_win:tabs()
          if all_tabs[active_idx + 1] then
            all_tabs[active_idx + 1]:activate()
          end
        end)

        win:toast_notification("WezTerm", "Restoring workspace '" .. id .. "'...", nil, 3000)
      end),
    }),
    pane
  )
end)

wezterm.on("delete-workspace", function(window, pane)
  local state = read_state()
  local choices = {}
  for name, _ in pairs(state) do
    table.insert(choices, { label = name, id = name })
  end
  if #choices == 0 then
    window:toast_notification("WezTerm", "No saved workspaces", nil, 3000)
    return
  end
  window:perform_action(
    act.InputSelector({
      title = "Delete Saved Workspace",
      choices = choices,
      action = wezterm.action_callback(function(win, _, id, label)
        if not id then return end
        state[id] = nil
        write_state(state)
        win:toast_notification("WezTerm", "Workspace '" .. id .. "' deleted", nil, 3000)
      end),
    }),
    pane
  )
end)

-------------------------------------------------------------------------------
-- Layout templates
-------------------------------------------------------------------------------

-- Helper: read all layout template files from layouts directory
local function read_layouts()
  local layouts = {}
  local handle = io.popen('ls "' .. layouts_dir .. '"/*.json 2>/dev/null')
  if handle then
    for file in handle:lines() do
      local f = io.open(file, "r")
      if f then
        local raw = f:read("*a")
        f:close()
        local ok, data = pcall(wezterm.json_parse, raw)
        if ok and data then
          data._file = file
          table.insert(layouts, data)
        end
      end
    end
    handle:close()
  end
  return layouts
end

-- Save current workspace as a layout template
wezterm.on("save-layout", function(window, pane)
  local workspace = window:active_workspace()
  local tabs = {}

  for _, tab in ipairs(window:mux_window():tabs()) do
    local tab_title = tab:get_title() or ""
    local panes = tab:panes_with_info()
    local split_tree = build_split_tree(panes)

    local process_list = {}
    for _, p in ipairs(panes) do
      local proc = p.pane:get_foreground_process_name() or ""
      if proc ~= "" then
        table.insert(process_list, proc:match("([^/]+)$") or proc)
      end
    end

    table.insert(tabs, {
      title = tab_title,
      split_tree = split_tree,
      pane_count = #panes,
      processes = process_list,
    })
  end

  -- Prompt for template name
  window:perform_action(
    act.PromptInputLine({
      description = "Template name (e.g. 'fullstack', 'claude-dev'):",
      action = wezterm.action_callback(function(win, p, line)
        if not line or #line == 0 then return end

        -- Sanitize name for filename
        local filename = line:gsub("[^%w%-_]", "-"):lower()
        local template = {
          name = line,
          description = "",
          created_at = os.date("%Y-%m-%d %H:%M:%S"),
          base_workspace = workspace,
          tabs = tabs,
        }

        -- Prompt for optional description
        win:perform_action(
          act.PromptInputLine({
            description = "Description (optional, Enter to skip):",
            action = wezterm.action_callback(function(w2, p2, desc)
              if desc and #desc > 0 then
                template.description = desc
              end

              local filepath = layouts_dir .. "/" .. filename .. ".json"
              local f = io.open(filepath, "w")
              if f then
                f:write(wezterm.json_encode(template))
                f:close()
                w2:toast_notification("WezTerm",
                  "Layout '" .. line .. "' saved\n" ..
                  #tabs .. " tabs",
                  nil, 3000)
              else
                w2:toast_notification("WezTerm", "Failed to save layout", nil, 3000)
              end
            end),
          }),
          p
        )
      end),
    }),
    pane
  )
end)

-- Select and launch a layout template
wezterm.on("select-layout", function(window, pane)
  local layouts = read_layouts()

  if #layouts == 0 then
    window:toast_notification("WezTerm",
      "No layout templates found.\nUse Leader+T to save one.",
      nil, 3000)
    return
  end

  local choices = {}
  for _, layout in ipairs(layouts) do
    local n = layout.tabs and #layout.tabs or 0
    local total_panes = 0
    for _, t in ipairs(layout.tabs or {}) do
      total_panes = total_panes + (t.pane_count or 1)
    end
    local desc = ""
    if layout.description and #layout.description > 0 then
      desc = " — " .. layout.description
    end
    table.insert(choices, {
      label = layout.name .. " (" .. n .. " tabs, " .. total_panes .. " panes)" .. desc,
      id = layout.name,
    })
  end

  -- First: pick the template
  window:perform_action(
    act.InputSelector({
      title = "Select Layout Template",
      choices = choices,
      fuzzy = true,
      action = wezterm.action_callback(function(win, p, id, label)
        if not id then return end

        -- Find the selected layout
        local layout = nil
        for _, l in ipairs(layouts) do
          if l.name == id then layout = l; break end
        end
        if not layout then return end

        -- Prompt for workspace name
        win:perform_action(
          act.PromptInputLine({
            description = "Workspace name (Enter for '" .. id .. "'):",
            action = wezterm.action_callback(function(w2, p2, ws_name)
              if not ws_name or #ws_name == 0 then
                ws_name = id
              end

              -- Check if workspace name already exists
              local existing = false
              for _, name in ipairs(wezterm.mux.get_workspace_names()) do
                if name == ws_name then existing = true; break end
              end
              if existing then
                local n = 2
                local base = ws_name
                while existing do
                  ws_name = base .. " (" .. n .. ")"
                  existing = false
                  for _, name in ipairs(wezterm.mux.get_workspace_names()) do
                    if name == ws_name then existing = true; break end
                  end
                  n = n + 1
                end
              end

              -- Prompt for base directory
              w2:perform_action(
                act.PromptInputLine({
                  description = "Base directory (Enter for home, or type path):",
                  action = wezterm.action_callback(function(w3, p3, base_dir)
                    local home = os.getenv("HOME")
                    if not base_dir or #base_dir == 0 then
                      base_dir = nil -- use template's original cwds
                    else
                      -- Expand ~
                      base_dir = base_dir:gsub("^~", home)
                    end

                    -- Create workspace with first tab
                    local first_tab = layout.tabs[1]
                    local first_cwd = home
                    if base_dir then
                      first_cwd = base_dir
                    elseif first_tab and first_tab.split_tree and first_tab.split_tree.cwd then
                      first_cwd = first_tab.split_tree.cwd
                    end

                    w3:perform_action(act.SwitchToWorkspace({
                      name = ws_name,
                      spawn = { cwd = first_cwd },
                    }), p3)

                    -- Restore tabs with splits after workspace switch
                    wezterm.time.call_after(0.5, function()
                      local target_win = nil
                      for _, mux_win in ipairs(wezterm.mux.all_windows()) do
                        if mux_win:get_workspace() == ws_name then
                          target_win = mux_win
                          break
                        end
                      end
                      if not target_win then return end

                      -- Helper to resolve cwd: use base_dir override or template's original
                      local function resolve_cwd(tree_cwd)
                        if base_dir then return base_dir end
                        return tree_cwd or home
                      end

                      -- Restore first tab splits
                      local existing_tabs = target_win:tabs()
                      if #existing_tabs > 0 and first_tab and first_tab.split_tree then
                        -- Override cwds if base_dir provided
                        local tree = first_tab.split_tree
                        if base_dir then
                          -- Deep-replace cwds in the tree
                          local function override_cwds(node)
                            if node.type == "leaf" then
                              node.cwd = base_dir
                            elseif node.children then
                              for _, child in ipairs(node.children) do
                                override_cwds(child)
                              end
                            end
                          end
                          -- Work on a copy concept: just override in restore
                          override_cwds(tree)
                        end
                        restore_split_tree(tree, existing_tabs[1]:active_pane())
                        if first_tab.title and #first_tab.title > 0 then
                          existing_tabs[1]:set_title(first_tab.title)
                        end
                      end

                      -- Create remaining tabs
                      for i = 2, #layout.tabs do
                        local tab_data = layout.tabs[i]
                        local tab_cwd = home
                        if base_dir then
                          tab_cwd = base_dir
                        elseif tab_data.split_tree and tab_data.split_tree.cwd then
                          tab_cwd = tab_data.split_tree.cwd
                        end

                        local new_tab, new_pane, _ = target_win:spawn_tab({
                          cwd = tab_cwd,
                        })

                        if tab_data.split_tree then
                          local tree = tab_data.split_tree
                          if base_dir then
                            local function override_cwds(node)
                              if node.type == "leaf" then
                                node.cwd = base_dir
                              elseif node.children then
                                for _, child in ipairs(node.children) do
                                  override_cwds(child)
                                end
                              end
                            end
                            override_cwds(tree)
                          end
                          restore_split_tree(tree, new_pane)
                        end

                        if tab_data.title and #tab_data.title > 0 then
                          new_tab:set_title(tab_data.title)
                        end
                      end

                      w3:toast_notification("WezTerm",
                        "Layout '" .. id .. "' launched as '" .. ws_name .. "'",
                        nil, 3000)
                    end)
                  end),
                }),
                p2
              )
            end),
          }),
          p
        )
      end),
    }),
    pane
  )
end)

-------------------------------------------------------------------------------
-- Help mode: searchable keybinding cheat sheet
-------------------------------------------------------------------------------

wezterm.on("show-help", function(window, pane)
  local win_id = tostring(window:window_id())
  help_active[win_id] = true

  local choices = {
    -- Section: Modes
    { label = "━━━ MODE ENTRY ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", id = "_" },
    { label = "Leader + u          UI mode (tab/pane/workspace mgmt)", id = "_" },
    { label = "Leader + i          Search mode (find in scrollback)", id = "_" },
    { label = "Leader + o          Scroll mode (man-page navigation)", id = "_" },
    { label = "Leader + p          Copy mode (vim selection/yank)", id = "_" },
    { label = "Leader + m          Map mode (tree navigator)", id = "_" },
    { label = "Leader + ?          Help mode (this screen)", id = "_" },
    { label = "Esc / q             Exit any mode back to Normal", id = "_" },

    -- Section: Tabs
    { label = "━━━ TABS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", id = "_" },
    { label = "Leader + c          New tab", id = "_" },
    { label = "Leader + b          Previous tab", id = "_" },
    { label = "Leader + n          Next tab", id = "_" },
    { label = "Leader + 1-9        Jump to tab by number", id = "_" },
    { label = "Leader + ,          Rename tab", id = "_" },

    -- Section: Panes
    { label = "━━━ PANES ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", id = "_" },
    { label = "Leader + \\          Vertical split", id = "_" },
    { label = "Leader + -          Horizontal split", id = "_" },
    { label = "Leader + h/j/k/l    Vim pane navigation", id = "_" },
    { label = "Leader + x          Close pane", id = "_" },

    -- Section: Workspaces
    { label = "━━━ WORKSPACES ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", id = "_" },
    { label = "Leader + w          Workspace picker (zoxide)", id = "_" },
    { label = "Leader + W          Previous workspace", id = "_" },
    { label = "Leader + $          Rename workspace", id = "_" },
    { label = "Leader + S          Save workspace state", id = "_" },
    { label = "Leader + R          Restore saved workspace", id = "_" },
    { label = "Leader + D          Delete saved workspace", id = "_" },

    -- Section: Layouts
    { label = "━━━ LAYOUT TEMPLATES ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", id = "_" },
    { label = "Leader + t          Select and launch a template", id = "_" },
    { label = "Leader + T          Save current workspace as template", id = "_" },

    -- Section: Tools
    { label = "━━━ TOOLS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", id = "_" },
    { label = "Leader + y          Open yazi file manager (new tab)", id = "_" },
    { label = "Cmd + Enter         Toggle fullscreen", id = "_" },

    -- Section: Scroll Mode
    { label = "━━━ SCROLL MODE (Leader + o) ━━━━━━━━━━━━━━━━━━━━━", id = "_" },
    { label = "b                   Half page up", id = "_" },
    { label = "Space               Half page down", id = "_" },
    { label = "u / d               Half page up / down", id = "_" },
    { label = "j / k               Line down / up", id = "_" },
    { label = "g / G               Top / bottom", id = "_" },
    { label = "/                   Search within scroll", id = "_" },

    -- Section: Copy Mode
    { label = "━━━ COPY MODE (Leader + p) ━━━━━━━━━━━━━━━━━━━━━━━", id = "_" },
    { label = "v / V / Ctrl+v      Selection: char / line / block", id = "_" },
    { label = "y                   Yank to clipboard and exit", id = "_" },
    { label = "h/j/k/l             Vim movement", id = "_" },
    { label = "w / b / e           Word forward / back / end", id = "_" },
    { label = "0 / $ / ^           Line start / end / first char", id = "_" },
    { label = "g / G               Scrollback top / bottom", id = "_" },
    { label = "/ / ?               Search forward / backward", id = "_" },
    { label = "n / N               Next / prev match", id = "_" },

    -- Section: UI Mode
    { label = "━━━ UI MODE (Leader + u) ━━━━━━━━━━━━━━━━━━━━━━━━━", id = "_" },
    { label = "c                   New tab", id = "_" },
    { label = "b / n               Prev / next tab", id = "_" },
    { label = "1-9                 Jump to tab", id = "_" },
    { label = "\\ / -               Vertical / horizontal split", id = "_" },
    { label = "h/j/k/l             Pane navigation", id = "_" },
    { label = "H/J/K/L             Pane resize", id = "_" },
    { label = "z                   Toggle pane zoom", id = "_" },
    { label = "x                   Close pane", id = "_" },

    -- Section: Search Mode
    { label = "━━━ SEARCH MODE (Leader + i) ━━━━━━━━━━━━━━━━━━━━━", id = "_" },
    { label = "Type to search      Incremental search", id = "_" },
    { label = "Ctrl+n / Ctrl+p     Next / prev match", id = "_" },
    { label = "Ctrl+r              Cycle match type (case/regex)", id = "_" },
    { label = "Enter               Accept match → copy mode", id = "_" },
    { label = "Esc / Ctrl+q        Exit search", id = "_" },
  }

  window:perform_action(
    act.InputSelector({
      title = "  Keybinding Help (type to search)",
      choices = choices,
      fuzzy = true,
      action = wezterm.action_callback(function(win, p, id, label)
        help_active[tostring(win:window_id())] = nil
      end),
    }),
    pane
  )
end)

-------------------------------------------------------------------------------
-- Navigation mode: tree view of all workspaces/tabs/panes
-------------------------------------------------------------------------------

wezterm.on("nav-tree", function(window, pane)
  local win_id = tostring(window:window_id())
  map_active[win_id] = true

  local choices = {}
  local current_workspace = window:active_workspace()

  -- Build tree from all running mux windows
  local workspaces = {}
  for _, mux_win in ipairs(wezterm.mux.all_windows()) do
    local ws_name = mux_win:get_workspace()
    if not workspaces[ws_name] then
      workspaces[ws_name] = {}
    end
    -- Collect tabs for this workspace
    for tab_index, tab in ipairs(mux_win:tabs()) do
      table.insert(workspaces[ws_name], {
        tab = tab,
        tab_index = tab_index - 1,
        mux_win_id = mux_win:window_id(),
      })
    end
  end

  -- Sort workspace names, current first
  local ws_names = {}
  for name, _ in pairs(workspaces) do
    table.insert(ws_names, name)
  end
  table.sort(ws_names, function(a, b)
    if a == current_workspace then return true end
    if b == current_workspace then return false end
    return a < b
  end)

  -- Build tree display
  for _, ws_name in ipairs(ws_names) do
    local tabs = workspaces[ws_name]
    local is_current = (ws_name == current_workspace)
    local ws_icon = is_current and "▶ " or "■ "
    local tab_count = #tabs

    -- Workspace header with tab count
    table.insert(choices, {
      label = ws_icon .. ws_name .. "  (" .. tab_count .. " tabs)",
      id = "ws:" .. ws_name,
    })

    -- Tabs under this workspace
    for t_idx, entry in ipairs(tabs) do
      local tab = entry.tab
      local tab_title = tab:get_title()
      if not tab_title or #tab_title == 0 then
        tab_title = tab:active_pane():get_title()
      end
      tab_title = tab_title:gsub("^Copy mode: ", "")
      local tab_num = tab:tab_id()

      local is_last_tab = (t_idx == #tabs)
      local tree_branch = is_last_tab and "    └── " or "    ├── "
      local tab_index = entry.tab_index + 1

      -- Get cwd for context (just the last dir name, not full path)
      local cwd = ""
      local pane_cwd = tab:active_pane():get_current_working_dir()
      if pane_cwd then
        local full = tostring(pane_cwd):gsub("^file://[^/]*", "")
        local short = full:gsub("^" .. os.getenv("HOME"), "~")
        -- Show just the last 2 path components for brevity
        local parts = {}
        for part in short:gmatch("[^/]+") do table.insert(parts, part) end
        if #parts > 2 then
          cwd = " ‹…/" .. parts[#parts - 1] .. "/" .. parts[#parts] .. "›"
        elseif #parts > 0 then
          cwd = " ‹" .. short .. "›"
        end
      end

      -- Tab icon based on process
      local proc = tab:active_pane():get_foreground_process_name() or ""
      local proc_short = proc:match("([^/]+)$") or ""
      local tab_icon = "  "
      if proc_short == "yazi" then tab_icon = "󰉋 "
      elseif proc_short == "nvim" or proc_short == "vim" then tab_icon = " "
      elseif proc_short == "claude" then tab_icon = "󰚩 "
      elseif proc_short == "node" then tab_icon = " "
      elseif proc_short == "python3" or proc_short == "python" then tab_icon = " "
      end

      table.insert(choices, {
        label = tree_branch .. tab_icon .. tab_index .. ":" .. tab_title .. cwd,
        id = "tab:" .. ws_name .. ":" .. tostring(entry.mux_win_id) .. ":" .. tostring(tab_num),
      })

      -- Panes under this tab (only if multiple panes)
      local panes = tab:panes_with_info()
      if #panes > 1 then
        for p_idx, p_info in ipairs(panes) do
          local p_title = p_info.pane:get_title():gsub("^Copy mode: ", "")
          local is_last_pane = (p_idx == #panes)
          local pane_indent = is_last_tab and "        " or "    │   "
          local pane_branch = is_last_pane and "└─ " or "├─ "
          local pane_marker = p_info.is_active and "● " or "○ "

          table.insert(choices, {
            label = pane_indent .. pane_branch .. pane_marker .. p_title,
            id = "pane:" .. ws_name .. ":" .. tostring(entry.mux_win_id) .. ":" .. tostring(tab_num) .. ":" .. tostring(p_info.pane:pane_id()),
          })
        end
      end
    end
  end

  -- Add saved (not running) workspaces — only if they exist
  local state = read_state()
  local has_saved = false
  for name, data in pairs(state) do
    if not workspaces[name] then
      if not has_saved then
        table.insert(choices, { label = "─── saved ───────────────────────────", id = "_" })
        has_saved = true
      end
      local n = data.tabs and #data.tabs or 0
      table.insert(choices, {
        label = "󰗁  " .. name .. "  (" .. n .. " tabs) saved " .. (data.saved_at or ""),
        id = "restore:" .. name,
      })
    end
  end

  window:perform_action(
    act.InputSelector({
      title = "  Navigate",
      choices = choices,
      fuzzy = true,
      action = wezterm.action_callback(function(win, p, id, label)
        map_active[tostring(win:window_id())] = nil
        if not id then return end

        if id:sub(1, 3) == "ws:" then
          -- Switch to workspace
          local ws = id:sub(4)
          win:perform_action(act.SwitchToWorkspace({ name = ws }), p)

        elseif id:sub(1, 4) == "tab:" then
          -- Parse tab:workspace:mux_win_id:tab_id
          local parts = {}
          for part in id:sub(5):gmatch("[^:]+") do
            table.insert(parts, part)
          end
          local ws = parts[1]
          local tab_id = tonumber(parts[3])

          -- Switch workspace first
          win:perform_action(act.SwitchToWorkspace({ name = ws }), p)

          -- Find and activate the tab
          for _, mux_win in ipairs(wezterm.mux.all_windows()) do
            if mux_win:get_workspace() == ws then
              for _, tab in ipairs(mux_win:tabs()) do
                if tab:tab_id() == tab_id then
                  tab:activate()
                  break
                end
              end
              break
            end
          end

        elseif id:sub(1, 5) == "pane:" then
          -- Parse pane:workspace:mux_win_id:tab_id:pane_id
          local parts = {}
          for part in id:sub(6):gmatch("[^:]+") do
            table.insert(parts, part)
          end
          local ws = parts[1]
          local tab_id = tonumber(parts[3])
          local pane_id = tonumber(parts[4])

          -- Switch workspace
          win:perform_action(act.SwitchToWorkspace({ name = ws }), p)

          -- Find tab, activate it, then activate pane
          for _, mux_win in ipairs(wezterm.mux.all_windows()) do
            if mux_win:get_workspace() == ws then
              for _, tab in ipairs(mux_win:tabs()) do
                if tab:tab_id() == tab_id then
                  tab:activate()
                  -- Activate the specific pane
                  for _, pi in ipairs(tab:panes_with_info()) do
                    if pi.pane:pane_id() == pane_id then
                      pi.pane:activate()
                      break
                    end
                  end
                  break
                end
              end
              break
            end
          end

        elseif id:sub(1, 8) == "restore:" then
          -- Restore saved workspace
          local name = id:sub(9)
          local ws = state[name]
          if ws and ws.tabs then
            local first = true
            for _, t in ipairs(ws.tabs) do
              local cwd = t.cwd:gsub("^file://[^/]*", "")
              if cwd == "" then cwd = os.getenv("HOME") end
              if first then
                win:perform_action(act.SwitchToWorkspace({
                  name = name,
                  spawn = { cwd = cwd },
                }), p)
                first = false
              else
                win:perform_action(act.SpawnCommandInNewTab({ cwd = cwd }), p)
              end
            end
            win:toast_notification("WezTerm", "Workspace '" .. name .. "' restored", nil, 3000)
          end
        end
      end),
    }),
    pane
  )
end)

-------------------------------------------------------------------------------
-- Normal mode keys (Leader bindings)
-------------------------------------------------------------------------------

config.keys = {
  -- Cmd shortcuts
  { key = "Enter", mods = "CMD", action = act.ToggleFullScreen },

  -- Tab management
  { key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
  { key = "b", mods = "LEADER", action = act.ActivateTabRelative(-1) },
  { key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
  { key = "1", mods = "LEADER", action = act.ActivateTab(0) },
  { key = "2", mods = "LEADER", action = act.ActivateTab(1) },
  { key = "3", mods = "LEADER", action = act.ActivateTab(2) },
  { key = "4", mods = "LEADER", action = act.ActivateTab(3) },
  { key = "5", mods = "LEADER", action = act.ActivateTab(4) },
  { key = "6", mods = "LEADER", action = act.ActivateTab(5) },
  { key = "7", mods = "LEADER", action = act.ActivateTab(6) },
  { key = "8", mods = "LEADER", action = act.ActivateTab(7) },
  { key = "9", mods = "LEADER", action = act.ActivateTab(8) },

  -- Splits
  { key = "\\", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

  -- Pane navigation
  { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
  { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
  { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
  { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },

  -- Pane/tab actions
  { key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },

  -- Leader + y = open yazi in a new tab
  {
    key = "y",
    mods = "LEADER",
    action = wezterm.action_callback(function(window, pane)
      local cwd = pane:get_current_working_dir()
      local dir = os.getenv("HOME")
      if cwd then
        dir = tostring(cwd):gsub("^file://[^/]*", "")
      end
      window:perform_action(act.SpawnCommandInNewTab({
        args = { "/opt/homebrew/bin/yazi", dir },
        cwd = dir,
      }), pane)
    end),
  },
  {
    key = ",",
    mods = "LEADER",
    action = act.PromptInputLine({
      description = "Enter new tab name:",
      action = wezterm.action_callback(function(window, pane, line)
        if line and #line > 0 then
          window:active_tab():set_title(line)
        end
      end),
    }),
  },
  {
    key = "$",
    mods = "LEADER|SHIFT",
    action = act.PromptInputLine({
      description = "Enter new workspace name:",
      action = wezterm.action_callback(function(window, pane, line)
        if line and #line > 0 then
          wezterm.mux.rename_workspace(window:active_workspace(), line)
        end
      end),
    }),
  },

  -- Workspace management
  {
    key = "w",
    mods = "LEADER",
    action = wezterm.action_callback(function(window, pane)
      local home = os.getenv("HOME")
      local success, stdout = wezterm.run_child_process({ "/opt/homebrew/bin/zoxide", "query", "-l" })
      local choices = {}
      for _, name in ipairs(wezterm.mux.get_workspace_names()) do
        table.insert(choices, { label = "● " .. name, id = "ws:" .. name })
      end
      if success and stdout then
        for dir in stdout:gmatch("[^\n]+") do
          local short = dir:gsub("^" .. home, "~")
          table.insert(choices, { label = "  " .. short, id = "dir:" .. dir })
        end
      end
      window:perform_action(
        act.InputSelector({
          title = "Switch Workspace",
          choices = choices,
          fuzzy = true,
          action = wezterm.action_callback(function(win, p, id, label)
            if not id then return end
            if id:sub(1, 3) == "ws:" then
              win:perform_action(act.SwitchToWorkspace({ name = id:sub(4) }), p)
            elseif id:sub(1, 4) == "dir:" then
              local dir = id:sub(5)
              local name = dir:match("([^/]+)$") or dir
              win:perform_action(act.SwitchToWorkspace({
                name = name,
                spawn = { cwd = dir },
              }), p)
            end
          end),
        }),
        pane
      )
    end),
  },
  { key = "W", mods = "LEADER|SHIFT", action = act.SwitchWorkspaceRelative(-1) },
  { key = "S", mods = "LEADER|SHIFT", action = act.EmitEvent("save-workspace") },
  { key = "R", mods = "LEADER|SHIFT", action = act.EmitEvent("restore-workspace") },
  { key = "D", mods = "LEADER|SHIFT", action = act.EmitEvent("delete-workspace") },

  ---------------------------------------------------------------------------
  -- Mode entry keys
  ---------------------------------------------------------------------------

  -- Leader + u = UI mode
  { key = "u", mods = "LEADER", action = act.ActivateKeyTable({ name = "ui_mode", one_shot = false }) },

  -- Leader + i = Search mode
  { key = "i", mods = "LEADER", action = act.Search({ CaseInSensitiveString = "" }) },

  -- Leader + o = Scroll mode
  { key = "o", mods = "LEADER", action = act.ActivateKeyTable({ name = "scroll_mode", one_shot = false }) },

  -- Leader + p = Copy mode
  { key = "p", mods = "LEADER", action = act.ActivateCopyMode },

  -- Leader + m = Map mode (tree navigator)
  { key = "m", mods = "LEADER", action = act.EmitEvent("nav-tree") },

  -- Leader + t = select and launch a layout template
  { key = "t", mods = "LEADER", action = act.EmitEvent("select-layout") },

  -- Leader + T = save current workspace as a layout template
  { key = "T", mods = "LEADER|SHIFT", action = act.EmitEvent("save-layout") },

  -- Leader + ? = help mode (searchable cheat sheet)
  { key = "?", mods = "LEADER|SHIFT", action = act.EmitEvent("show-help") },
}

-------------------------------------------------------------------------------
-- Key tables (modal bindings)
-------------------------------------------------------------------------------

config.key_tables = {
  ---------------------------------------------------------------------------
  -- Scroll mode: man-page style
  ---------------------------------------------------------------------------
  scroll_mode = {
    { key = "b", action = act.ScrollByPage(-0.5) },
    { key = "Space", action = act.ScrollByPage(0.5) },
    { key = "u", action = act.ScrollByPage(-0.5) },
    { key = "d", action = act.ScrollByPage(0.5) },
    { key = "k", action = act.ScrollByLine(-1) },
    { key = "j", action = act.ScrollByLine(1) },
    { key = "g", action = act.ScrollToTop },
    { key = "G", mods = "SHIFT", action = act.ScrollToBottom },
    -- Search within scroll mode
    { key = "/", action = act.Multiple({ act.PopKeyTable, act.Search({ CaseInSensitiveString = "" }) }) },
    -- Exit
    { key = "Escape", action = act.PopKeyTable },
    { key = "q", action = act.PopKeyTable },
  },

  ---------------------------------------------------------------------------
  -- UI mode: tab, pane, workspace management
  ---------------------------------------------------------------------------
  ui_mode = {
    -- Tab management
    { key = "c", action = act.SpawnTab("CurrentPaneDomain") },
    { key = "b", action = act.ActivateTabRelative(-1) },
    { key = "n", action = act.ActivateTabRelative(1) },
    { key = "1", action = act.ActivateTab(0) },
    { key = "2", action = act.ActivateTab(1) },
    { key = "3", action = act.ActivateTab(2) },
    { key = "4", action = act.ActivateTab(3) },
    { key = "5", action = act.ActivateTab(4) },
    { key = "6", action = act.ActivateTab(5) },
    { key = "7", action = act.ActivateTab(6) },
    { key = "8", action = act.ActivateTab(7) },
    { key = "9", action = act.ActivateTab(8) },
    -- Splits
    { key = "\\", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
    { key = "-", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
    -- Pane navigation
    { key = "h", action = act.ActivatePaneDirection("Left") },
    { key = "j", action = act.ActivatePaneDirection("Down") },
    { key = "k", action = act.ActivatePaneDirection("Up") },
    { key = "l", action = act.ActivatePaneDirection("Right") },
    -- Pane resize
    { key = "H", mods = "SHIFT", action = act.AdjustPaneSize({ "Left", 5 }) },
    { key = "J", mods = "SHIFT", action = act.AdjustPaneSize({ "Down", 5 }) },
    { key = "K", mods = "SHIFT", action = act.AdjustPaneSize({ "Up", 5 }) },
    { key = "L", mods = "SHIFT", action = act.AdjustPaneSize({ "Right", 5 }) },
    -- Close
    { key = "x", action = act.CloseCurrentPane({ confirm = true }) },
    -- Zoom pane toggle
    { key = "z", action = act.TogglePaneZoomState },
    -- Workspace
    { key = "W", mods = "SHIFT", action = act.SwitchWorkspaceRelative(-1) },
    { key = "S", mods = "SHIFT", action = act.EmitEvent("save-workspace") },
    { key = "R", mods = "SHIFT", action = act.EmitEvent("restore-workspace") },
    { key = "D", mods = "SHIFT", action = act.EmitEvent("delete-workspace") },
    -- Exit
    { key = "Escape", action = act.PopKeyTable },
    { key = "q", action = act.PopKeyTable },
  },

  ---------------------------------------------------------------------------
  -- Copy mode overrides (extend defaults with q to exit)
  ---------------------------------------------------------------------------
  copy_mode = {
    -- Movement
    { key = "h", action = act.CopyMode("MoveLeft") },
    { key = "j", action = act.CopyMode("MoveDown") },
    { key = "k", action = act.CopyMode("MoveUp") },
    { key = "l", action = act.CopyMode("MoveRight") },
    { key = "w", action = act.CopyMode("MoveForwardWord") },
    { key = "b", action = act.CopyMode("MoveBackwardWord") },
    { key = "e", action = act.CopyMode("MoveForwardWordEnd") },
    { key = "0", action = act.CopyMode("MoveToStartOfLine") },
    { key = "$", mods = "SHIFT", action = act.CopyMode("MoveToEndOfLineContent") },
    { key = "^", mods = "SHIFT", action = act.CopyMode("MoveToStartOfLineContent") },
    { key = "g", action = act.CopyMode("MoveToScrollbackTop") },
    { key = "G", mods = "SHIFT", action = act.CopyMode("MoveToScrollbackBottom") },
    { key = "H", mods = "SHIFT", action = act.CopyMode("MoveToViewportTop") },
    { key = "M", mods = "SHIFT", action = act.CopyMode("MoveToViewportMiddle") },
    { key = "L", mods = "SHIFT", action = act.CopyMode("MoveToViewportBottom") },
    -- Selection
    { key = "v", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
    { key = "V", mods = "SHIFT", action = act.CopyMode({ SetSelectionMode = "Line" }) },
    { key = "v", mods = "CTRL", action = act.CopyMode({ SetSelectionMode = "Block" }) },
    -- Yank and exit
    {
      key = "y",
      action = act.Multiple({
        act.CopyTo("ClipboardAndPrimarySelection"),
        act.CopyMode("Close"),
      }),
    },
    -- Search within copy mode
    { key = "/", action = act.CopyMode("EditPattern") },
    { key = "?", mods = "SHIFT", action = act.CopyMode("EditPattern") },
    { key = "n", action = act.CopyMode("NextMatch") },
    { key = "N", mods = "SHIFT", action = act.CopyMode("PriorMatch") },
    -- Scrolling
    { key = "u", mods = "CTRL", action = act.CopyMode("PageUp") },
    { key = "d", mods = "CTRL", action = act.CopyMode("PageDown") },
    -- Exit
    { key = "Escape", action = act.Multiple({ act.CopyMode("Close"), act.PopKeyTable }) },
    { key = "q", action = act.Multiple({ act.CopyMode("Close"), act.PopKeyTable }) },
  },

  ---------------------------------------------------------------------------
  -- Search mode overrides (extend defaults with q to exit)
  ---------------------------------------------------------------------------
  search_mode = {
    { key = "Escape", action = act.CopyMode("Close") },
    { key = "q", mods = "CTRL", action = act.CopyMode("Close") },
    { key = "Enter", action = act.CopyMode("AcceptPattern") },
    { key = "n", mods = "CTRL", action = act.CopyMode("NextMatch") },
    { key = "p", mods = "CTRL", action = act.CopyMode("PriorMatch") },
    { key = "r", mods = "CTRL", action = act.CopyMode("CycleMatchType") },
    { key = "u", mods = "CTRL", action = act.CopyMode("ClearPattern") },
  },
}

return config
