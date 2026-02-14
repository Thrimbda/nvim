local M = {}

M.cfg = {
  org_agenda_files = { "~/OneDrive/cone/**/*" },
  organization_task_id = "3CA66213-50ED-48B9-8E24-310B0959DA75",
  project_todo_keywords = { "TODO", "NEXT", "WAITING", "HOLD" },
}

M.state = {
  keep_clock_running = false,
  warned_norang_mismatch = false,
}

local function escape_pattern(text)
  if vim.pesc then
    return vim.pesc(text)
  end
  return (text:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"))
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

local function maybe_warn_norang_todo_mismatch()
  if M.state.warned_norang_mismatch then
    return
  end
  local ok, norang = pcall(require, "org_norang")
  if not ok or type(norang.get_config) ~= "function" then
    return
  end
  local cfg = norang.get_config()
  if not cfg or not cfg.todo or not cfg.todo.active then
    return
  end
  if same_items(M.cfg.project_todo_keywords, cfg.todo.active) then
    return
  end

  M.state.warned_norang_mismatch = true
  vim.notify(
    "org_punch: TODO keywords differ from org_norang.todo.active; punch keeps running unchanged",
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
    pattern = vim.fn.expand(pattern)
    local matches = vim.fn.glob(pattern, true, true)
    for _, file in ipairs(matches) do
      if vim.fn.filereadable(file) == 1 and file:match("%.org$") then
        table.insert(files, file)
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

local function find_task_by_id(id)
  if not id or id == "" then
    return nil
  end

  local files = expand_org_files()
  local id_pat = "^%s*:ID:%s*" .. escape_pattern(id) .. "%s*$"

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
          return { file = file, line = heading_line }
        end
      end
    end
  end

  return nil
end

local function call_org_action(action)
  local ok, orgmode = pcall(require, "orgmode")
  if not ok or type(orgmode.action) ~= "function" then
    return false
  end
  return pcall(orgmode.action, action)
end

local function feedkeys(keys)
  local termcodes = vim.api.nvim_replace_termcodes(keys, true, false, true)
  vim.api.nvim_feedkeys(termcodes, "n", true)
end

local function org_clock_in()
  if not call_org_action("clock.org_clock_in") then
    feedkeys("<Leader>oxi")
  end
end

local function org_clock_out()
  if not call_org_action("clock.org_clock_out") then
    feedkeys("<Leader>oxo")
  end
end

local function org_clock_goto()
  if not call_org_action("clock.org_clock_goto") then
    feedkeys("<Leader>oxj")
  end
end

local function with_view_restored(fn)
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()
  local view = vim.fn.winsaveview()

  local ok, err = pcall(fn)

  if vim.api.nvim_win_is_valid(win) and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_set_current_win(win)
    vim.cmd(("keepalt keepjumps buffer %d"):format(buf))
    vim.fn.winrestview(view)
  end

  if not ok then
    vim.notify(("org_punch error: %s"):format(err), vim.log.levels.ERROR)
  end
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

function M.setup(opts)
  M.cfg = vim.tbl_deep_extend("force", M.cfg, opts or {})
  maybe_warn_norang_todo_mismatch()
end

function M.clock_in_default()
  if not M.cfg.organization_task_id or M.cfg.organization_task_id == "" then
    vim.notify("org_punch: organization_task_id is required", vim.log.levels.ERROR)
    return
  end

  local loc = find_task_by_id(M.cfg.organization_task_id)
  if not loc then
    vim.notify("org_punch: default task not found by :ID:", vim.log.levels.ERROR)
    return
  end

  with_view_restored(function()
    vim.cmd("keepalt keepjumps silent edit " .. vim.fn.fnameescape(loc.file))
    vim.api.nvim_win_set_cursor(0, { loc.line, 0 })
    org_clock_in()
  end)
end

function M.punch_in()
  maybe_warn_norang_todo_mismatch()
  M.state.keep_clock_running = true
  M.clock_in_default()
  vim.notify("Org Punch In: keep clock running = true")
end

function M.punch_out()
  maybe_warn_norang_todo_mismatch()
  M.state.keep_clock_running = false

  with_view_restored(function()
    org_clock_goto()
    org_clock_out()
  end)

  vim.notify("Org Punch Out: keep clock running = false")
end

function M.clock_out_keep_running()
  maybe_warn_norang_todo_mismatch()
  with_view_restored(function()
    org_clock_goto()

    local parent_line = find_parent_project_line_in_current_buffer()

    org_clock_out()

    if M.state.keep_clock_running then
      if parent_line then
        vim.api.nvim_win_set_cursor(0, { parent_line, 0 })
        org_clock_in()
      else
        M.clock_in_default()
      end
    end
  end)
end

return M
