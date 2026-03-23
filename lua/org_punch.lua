local M = {}

M.cfg = {
  org_agenda_files = { "~/OneDrive/cone/**/*.org" },
  organization_task_id = "",
  project_todo_keywords = { "TODO", "NEXT", "WAITING", "HOLD" },
}

M.state = {
  keep_clock_running = false,
  warned_legion_mismatch = false,
}

local function escape_pattern(text)
  if vim.pesc then
    return vim.pesc(text)
  end
  return (text:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"))
end

local function expand_home(path)
  local home = vim.env.HOME or ""
  if path == "~" then
    return home ~= "" and home or path
  end
  if path:sub(1, 2) == "~/" and home ~= "" then
    return home .. path:sub(2)
  end
  return path
end

local function normalize_path(path)
  local absolute = vim.fn.fnamemodify(path, ":p")
  local real = nil
  if vim.uv and type(vim.uv.fs_realpath) == "function" then
    real = vim.uv.fs_realpath(absolute)
  elseif vim.loop and type(vim.loop.fs_realpath) == "function" then
    real = vim.loop.fs_realpath(absolute)
  end
  return real or absolute
end

local function current_file_path()
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" then
    return nil
  end
  return normalize_path(name)
end

local function uniq(list)
  local seen, out = {}, {}
  for _, item in ipairs(list) do
    if not seen[item] then
      seen[item] = true
      table.insert(out, item)
    end
  end
  return out
end

local function same_items(a, b)
  local sa, sb = {}, {}
  for _, item in ipairs(a or {}) do
    sa[item] = true
  end
  for _, item in ipairs(b or {}) do
    sb[item] = true
  end
  for k, _ in pairs(sa) do
    if not sb[k] then
      return false
    end
  end
  for k, _ in pairs(sb) do
    if not sa[k] then
      return false
    end
  end
  return true
end

local function maybe_warn_legion_todo_mismatch()
  if M.state.warned_legion_mismatch then
    return
  end
  local ok, legion = pcall(require, "org_legion")
  if not ok or type(legion.get_config) ~= "function" then
    return
  end
  local cfg = legion.get_config()
  if not cfg or not cfg.todo or not cfg.todo.active then
    return
  end
  if same_items(M.cfg.project_todo_keywords, cfg.todo.active) then
    return
  end

  M.state.warned_legion_mismatch = true
  vim.notify(
    "org_punch: TODO keywords differ from org_legion.todo.active; punch keeps running unchanged",
    vim.log.levels.WARN
  )
end

local function expand_org_files()
  local patterns = M.cfg.org_agenda_files
  if type(patterns) == "string" then
    patterns = { patterns }
  end

  local files = {}
  for _, pattern in ipairs(patterns or {}) do
    local expanded = expand_home(pattern)
    local matches = vim.fn.glob(expanded, true, true)

    if #matches == 0 and expanded:sub(-5) == "/**/*" then
      matches = vim.fn.glob(expanded:sub(1, -2) .. ".org", true, true)
    end

    if #matches == 0 and vim.fn.isdirectory(expanded) == 1 then
      matches = vim.fn.glob(expanded .. "/**/*.org", true, true)
    end

    for _, file in ipairs(matches) do
      if vim.fn.filereadable(file) == 1 and file:match("%.org$") then
        table.insert(files, normalize_path(file))
      end
    end
  end

  return uniq(files)
end

local function find_heading_line(lines, from_line)
  for i = from_line, 1, -1 do
    if lines[i]:match("^%*+") then
      return i
    end
  end
  return nil
end

local function heading_level(line)
  local stars = line:match("^(%*+)")
  return stars and #stars or nil
end

local function notify_once(message, level)
  if type(vim.notify_once) == "function" then
    vim.notify_once(message, level)
    return
  end
  vim.notify(message, level)
end

local function find_task_by_id(id)
  if not id or id == "" then
    return nil
  end

  local files = expand_org_files()
  local id_pat = "^%s*:ID:%s*" .. escape_pattern(id) .. "%s*$"
  local matches = {}

  for _, file in ipairs(files) do
    local ok, lines = pcall(vim.fn.readfile, file)
    if ok and lines then
      local id_line
      for i, line in ipairs(lines) do
        if line:match(id_pat) then
          id_line = i
          break
        end
      end
      if id_line then
        local heading_line = find_heading_line(lines, id_line)
        if heading_line then
          table.insert(matches, { file = file, line = heading_line })
        end
      end
    end
  end

  if #matches == 0 then
    return nil
  end

  local current_path = current_file_path()
  if current_path then
    for _, match in ipairs(matches) do
      if match.file == current_path then
        if #matches > 1 then
          notify_once(
            "org_punch: organization_task_id matched multiple files; preferring the current buffer and keeping IDs unique is recommended",
            vim.log.levels.WARN
          )
        end
        return match
      end
    end
  end

  if #matches > 1 then
    notify_once(
      "org_punch: organization_task_id matched multiple files; using the first match and keeping IDs unique is recommended",
      vim.log.levels.WARN
    )
  end

  return matches[1]
end

local function find_active_clocked_headline_in_tree(headline)
  if headline:is_clocked_in() then
    return headline
  end

  for _, child in ipairs(headline:get_child_headlines() or {}) do
    local active = find_active_clocked_headline_in_tree(child)
    if active then
      return active
    end
  end

  return nil
end

local function detect_clocked_headline(orgmode)
  if not orgmode or not orgmode.clock or not orgmode.files then
    return nil
  end

  orgmode.clock:update_clocked_headline()
  if orgmode.clock.clocked_headline then
    return orgmode.clock.clocked_headline
  end

  for _, file in ipairs(orgmode.files:all()) do
    local refreshed = file:reload_sync()
    for _, headline in ipairs(refreshed:get_headlines()) do
      local active = find_active_clocked_headline_in_tree(headline)
      if active then
        orgmode.clock.clocked_headline = active
        return active
      end
    end
  end

  orgmode.clock.clocked_headline = nil
  return nil
end

local function call_org_action(action)
  local ok, orgmode = pcall(require, "orgmode")
  if not ok or type(orgmode.action) ~= "function" then
    return false
  end

  local ok_action, result = pcall(orgmode.action, action)
  if not ok_action then
    return false
  end

  if type(result) == "table" and type(result.wait) == "function" then
    local ok_wait = pcall(result.wait, result, 2000)
    if not ok_wait then
      return false
    end
  end

  return true
end

local function call_org_clock_method(method)
  local ok, orgmode = pcall(require, "orgmode")
  if not ok or not orgmode.clock or type(orgmode.clock[method]) ~= "function" then
    return false
  end

  return pcall(function()
    local result = orgmode.clock[method](orgmode.clock)
    if type(result) == "table" and type(result.wait) == "function" then
      result:wait(2000)
    end
  end)
end

local function get_clocked_headline()
  local ok, orgmode = pcall(require, "orgmode")
  if not ok or not orgmode.clock then
    return nil
  end

  return detect_clocked_headline(orgmode)
end

local with_file_buffer

local function get_active_clock_context()
  local headline = get_clocked_headline()
  if not headline then
    return nil
  end

  local headline_line = headline:get_range().start_line
  local current = headline.file:reload_sync():get_closest_headline({ headline_line, 0 })
  if not current then
    return nil
  end

  local logbook = current:get_logbook()
  local active = logbook and logbook:get_active() or nil
  if not active or not active.start_time or not active.start_time.range then
    return nil
  end

  return {
    path = normalize_path(current.file.filename),
    headline_line = current:get_range().start_line,
    clock_line = active.start_time.range.start_line,
  }
end

local function get_active_clock_context_for_location(path, line)
  local target_path = normalize_path(path)
  local ok_ctx, context = with_file_buffer(target_path, function()
    local org_ok, orgmode = pcall(require, "orgmode")
    if not org_ok or not orgmode.files then
      return nil
    end

    local file = orgmode.files:get(target_path):reload_sync()
    local current = file:get_closest_headline({ line, 0 })
    if not current then
      return nil
    end

    local logbook = current:get_logbook()
    local active = logbook and logbook:get_active() or nil
    if not active or not active.start_time or not active.start_time.range then
      return nil
    end

    return {
      path = target_path,
      headline_line = current:get_range().start_line,
      clock_line = active.start_time.range.start_line,
    }
  end)

  if not ok_ctx then
    return nil
  end

  return context
end

local function cleanup_zero_duration_clock(context)
  if not context then
    return
  end

  local ok = with_file_buffer(context.path, function(bufnr)
    local line_nr = context.clock_line
    if not line_nr or line_nr < 1 then
      return
    end

    local line = vim.api.nvim_buf_get_lines(bufnr, line_nr - 1, line_nr, false)[1]
    if not line or not line:match("=>%s*0:00%s*$") then
      return
    end

    vim.api.nvim_buf_set_lines(bufnr, line_nr - 1, line_nr, false, {})

    local prev_line = line_nr > 1 and vim.api.nvim_buf_get_lines(bufnr, line_nr - 2, line_nr - 1, false)[1] or nil
    local next_line = vim.api.nvim_buf_get_lines(bufnr, line_nr - 1, line_nr, false)[1]
    if prev_line and next_line and prev_line:match("^%s*:LOGBOOK:%s*$") and next_line:match("^%s*:END:%s*$") then
      vim.api.nvim_buf_set_lines(bufnr, line_nr - 2, line_nr, false, {})
    end
  end)

  if not ok then
    vim.notify("org_punch: failed to cleanup 0:00 clock entry", vim.log.levels.WARN)
  end
end

local function has_todo_descendant(headline, todo_keys)
  for _, child in ipairs(headline:get_child_headlines() or {}) do
    local todo = child:get_todo()
    if todo and todo_keys[todo] then
      return true
    end
    if has_todo_descendant(child, todo_keys) then
      return true
    end
  end
  return false
end

local function classify_headline(headline)
  local todo = headline:get_todo()
  if not todo then
    return false, false
  end

  local todo_keys = headline.file:get_todo_keywords():keys()
  if not todo_keys[todo] then
    return false, false
  end

  local is_project = has_todo_descendant(headline, todo_keys)
  local is_task = not is_project
  return is_project, is_task
end

local function apply_clock_in_state_transition()
  local headline = get_clocked_headline()
  if not headline then
    return
  end

  local line = headline:get_range().start_line
  local file = headline.file:reload_sync()
  local current = file:get_closest_headline({ line, 0 })
  if not current then
    return
  end

  local todo = current:get_todo()
  if not todo then
    return
  end

  local is_project, is_task = classify_headline(current)
  local next_todo = nil
  if todo == "TODO" and is_task then
    next_todo = "NEXT"
  elseif todo == "NEXT" and is_project then
    next_todo = "TODO"
  end

  if not next_todo then
    return
  end

  local current_path = normalize_path(vim.api.nvim_buf_get_name(0))
  local target_path = normalize_path(current.file.filename)
  if current_path ~= "" and current_path == target_path then
    local ok_set = pcall(current.set_todo, current, next_todo)
    if ok_set then
      return
    end
  end

  local ok = with_file_buffer(target_path, function()
    local org_ok, orgmode = pcall(require, "orgmode")
    if not org_ok then
      return
    end
    local update_file = orgmode.files:get(target_path):reload_sync()
    local updated = update_file:get_closest_headline({ line, 0 })
    if updated then
      updated:set_todo(next_todo)
    end
  end)

  if not ok then
    vim.notify("org_punch: failed to update TODO state after clock in", vim.log.levels.WARN)
  end
end

local function org_clock_in()
  local active_clock = get_active_clock_context()
  local ok = call_org_action("clock.org_clock_in") or call_org_clock_method("org_clock_in")
  if not ok then
    vim.notify("org_punch: failed to clock in", vim.log.levels.ERROR)
    return false
  end
  cleanup_zero_duration_clock(active_clock)
  apply_clock_in_state_transition()
  return true
end

local function org_clock_out()
  local active_clock = get_active_clock_context()

  if not (call_org_action("clock.org_clock_out") or call_org_clock_method("org_clock_out")) then
    vim.notify("org_punch: failed to clock out", vim.log.levels.ERROR)
    return false
  end

  cleanup_zero_duration_clock(active_clock)
  return true
end

local function org_clock_goto()
  if not (call_org_action("clock.org_clock_goto") or call_org_clock_method("org_clock_goto")) then
    vim.notify("org_punch: failed to goto active clock", vim.log.levels.ERROR)
    return false
  end
  return true
end

local function with_view_restored(fn)
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()
  local view = vim.fn.winsaveview()
  local win_opts = {
    foldenable = vim.wo.foldenable,
    foldlevel = vim.wo.foldlevel,
    foldmethod = vim.wo.foldmethod,
    foldexpr = vim.wo.foldexpr,
    foldcolumn = vim.wo.foldcolumn,
  }

  local ok, result = pcall(fn)

  if vim.api.nvim_win_is_valid(win) and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_set_current_win(win)
    vim.cmd(("keepalt keepjumps buffer %d"):format(buf))
    vim.fn.winrestview(view)
    for opt, value in pairs(win_opts) do
      pcall(vim.api.nvim_set_option_value, opt, value, { win = win })
    end
  end

  if not ok then
    vim.notify(("org_punch error: %s"):format(result), vim.log.levels.ERROR)
    return false, nil
  end

  return true, result
end

local function run_with_preserved_view(fn)
  local ok, result = with_view_restored(fn)
  return ok and result == true
end

with_file_buffer = function(path, fn)
  local target_path = normalize_path(path)
  local current_win = vim.api.nvim_get_current_win()
  local current_buf = vim.api.nvim_get_current_buf()
  local current_view = vim.fn.winsaveview()
  local current_path = normalize_path(vim.api.nvim_buf_get_name(current_buf))

  if current_path ~= "" and current_path == target_path then
    return pcall(fn, current_buf)
  end

  local existing = vim.fn.bufnr(target_path)
  local existed_before = existing > 0
  local loaded_before = existed_before and vim.api.nvim_buf_is_loaded(existing)
  local bufnr = existed_before and existing or vim.fn.bufadd(target_path)

  pcall(vim.api.nvim_set_option_value, "modeline", false, { buf = bufnr })
  pcall(vim.api.nvim_set_option_value, "swapfile", false, { buf = bufnr })
  vim.fn.bufload(bufnr)

  local hidden_win = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    width = 1,
    height = 1,
    row = 99999,
    col = 99999,
    zindex = 1,
    style = "minimal",
    focusable = false,
    hide = true,
  })

  local ok, result = pcall(fn, bufnr)

  pcall(vim.api.nvim_win_close, hidden_win, true)
  if vim.api.nvim_win_is_valid(current_win) then
    vim.api.nvim_set_current_win(current_win)
    if vim.api.nvim_buf_is_valid(current_buf) and vim.api.nvim_get_current_buf() ~= current_buf then
      pcall(vim.cmd, ("keepalt keepjumps buffer %d"):format(current_buf))
    end
    pcall(vim.fn.winrestview, current_view)
  end

  if vim.api.nvim_buf_is_valid(bufnr) and not vim.bo[bufnr].modified and not loaded_before and not existed_before then
    pcall(vim.cmd, ("silent! bwipe! %d"):format(bufnr))
  end

  return ok, result
end

local function clock_in_at_location(loc)
  local ok, orgmode = pcall(require, "orgmode")
  if not ok or not orgmode.clock or not orgmode.files then
    vim.notify("org_punch: orgmode clock is unavailable", vim.log.levels.ERROR)
    return false
  end

  local clock = orgmode.clock
  local target_headline = nil
  local ok_run, err = pcall(function()
    local active_headline = detect_clocked_headline(orgmode)

    if active_headline and active_headline:is_clocked_in() then
      local prev_path = normalize_path(active_headline.file.filename)
      local prev_line = active_headline:get_range().start_line
      local prev_context = get_active_clock_context_for_location(prev_path, prev_line)

      local ok_prev = with_file_buffer(prev_path, function()
        local prev_file = orgmode.files:get(prev_path):reload_sync()
        local previous = prev_file:get_closest_headline({ prev_line, 0 })
        if previous and previous:is_clocked_in() then
          previous:clock_out()
        end
      end)
      if not ok_prev then
        error("failed to clock out previous active task")
      end

      cleanup_zero_duration_clock(prev_context)
    end

    local target_path = normalize_path(loc.file)
    local ok_target = with_file_buffer(target_path, function()
      local target_file = orgmode.files:get(target_path):reload_sync()
      local target = target_file:get_closest_headline({ loc.line, 0 })
      if not target then
        error("default task headline not found")
      end

      target:clock_in()
      target_headline = target_file:reload_sync():get_closest_headline({ loc.line, 0 }) or target
    end)
    if not ok_target then
      error("failed to clock in default task")
    end

    clock.clocked_headline = target_headline or detect_clocked_headline(orgmode)
  end)

  if not ok_run then
    vim.notify(("org_punch: failed to clock in default task (%s)"):format(tostring(err)), vim.log.levels.ERROR)
    return false
  end

  apply_clock_in_state_transition()
  return true
end

local function find_parent_project_line_in_current_buffer()
  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  local cur_heading = find_heading_line(lines, cur)
  if not cur_heading then
    return nil
  end

  local cur_level = heading_level(lines[cur_heading])
  if not cur_level then
    return nil
  end

  local keywords = M.cfg.project_todo_keywords or {}
  if #keywords == 0 then
    return nil
  end

  local escaped = {}
  for _, kw in ipairs(keywords) do
    table.insert(escaped, escape_pattern(kw))
  end
  local kw_pat = table.concat(escaped, "|")
  local todo_re = "^%*+%s+(" .. kw_pat .. ")%s+"

  for i = cur_heading - 1, 1, -1 do
    local line = lines[i]
    local level = heading_level(line)
    if level and level < cur_level then
      cur_level = level
      if line:match(todo_re) then
        return i
      end
    end
  end

  return nil
end

local function find_parent_project_location_for_active_clock()
  local active = get_clocked_headline()
  if not active then
    return nil
  end

  local target_path = normalize_path(active.file.filename)
  local target_line = active:get_range().start_line
  local keywords = {}
  for _, kw in ipairs(M.cfg.project_todo_keywords or {}) do
    keywords[kw] = true
  end

  if vim.tbl_isempty(keywords) then
    return nil
  end

  local ok_loc, loc = with_file_buffer(target_path, function()
    local org_ok, orgmode = pcall(require, "orgmode")
    if not org_ok or not orgmode.files then
      return nil
    end

    local file = orgmode.files:get(target_path):reload_sync()
    local current = file:get_closest_headline({ target_line, 0 })
    if not current then
      return nil
    end

    local parent = current:get_parent_headline()
    while parent do
      local todo = parent:get_todo()
      if todo and keywords[todo] then
        return {
          file = target_path,
          line = parent:get_range().start_line,
        }
      end
      parent = parent:get_parent_headline()
    end

    return nil
  end)

  if not ok_loc then
    return nil
  end

  return loc
end

function M.setup(opts)
  M.cfg = vim.tbl_deep_extend("force", M.cfg, opts or {})
  maybe_warn_legion_todo_mismatch()
end

function M.clock_in_default()
  return run_with_preserved_view(function()
    if not M.cfg.organization_task_id or M.cfg.organization_task_id == "" then
      vim.notify("org_punch: organization_task_id is required (set vim.g.org_organization_task_id)", vim.log.levels.ERROR)
      return false
    end

    local loc = find_task_by_id(M.cfg.organization_task_id)
    if not loc then
      vim.notify("org_punch: default task not found by :ID:", vim.log.levels.ERROR)
      return false
    end

    return clock_in_at_location(loc)
  end)
end

function M.punch_in()
  return run_with_preserved_view(function()
    maybe_warn_legion_todo_mismatch()
    M.state.keep_clock_running = true

    local ok = M.clock_in_default()
    if not ok then
      M.state.keep_clock_running = false
      return false
    end

    vim.notify("Org Punch In: keep clock running = true")
    return true
  end)
end

function M.clock_in_current_task()
  maybe_warn_legion_todo_mismatch()
  return run_with_preserved_view(function()
    return org_clock_in()
  end)
end

function M.clock_out_current_task(opts)
  opts = opts or {}

  return run_with_preserved_view(function()
    if not opts.silent then
      maybe_warn_legion_todo_mismatch()
    end

    if M.state.keep_clock_running and not opts.ignore_keep_running then
      return M.clock_out_keep_running()
    end

    return org_clock_out()
  end)
end

function M.punch_out()
  return run_with_preserved_view(function()
    maybe_warn_legion_todo_mismatch()
    M.state.keep_clock_running = false

    local ok = org_clock_out()
    if not ok then
      return false
    end

    vim.notify("Org Punch Out: keep clock running = false")
    return true
  end)
end

function M.clock_out_keep_running()
  maybe_warn_legion_todo_mismatch()

  local ok, result = with_view_restored(function()
    if not org_clock_goto() then
      return false
    end

    local parent_line = find_parent_project_line_in_current_buffer()
    local parent_location = nil
    if parent_line then
      local current_path = normalize_path(vim.api.nvim_buf_get_name(0))
      if current_path ~= "" then
        parent_location = {
          file = current_path,
          line = parent_line,
        }
      end
    else
      parent_location = find_parent_project_location_for_active_clock()
    end

    if not org_clock_out() then
      return false
    end

    if M.state.keep_clock_running then
      if parent_location then
        return clock_in_at_location(parent_location)
      end
      return M.clock_in_default()
    end

    return true
  end)

  return ok and result == true
end

return M
