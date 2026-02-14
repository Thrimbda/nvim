local parser = require("org_norang.parser")
local rules = require("org_norang.rules")

local M = {}

local locks = {}
local uv = vim.uv or vim.loop

local function uniq(list)
  local out, seen = {}, {}
  for _, item in ipairs(list) do
    if not seen[item] then
      seen[item] = true
      table.insert(out, item)
    end
  end
  return out
end

local function normalize_path(path)
  return vim.fn.fnamemodify(path, ":p")
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

local function extract_path(path_or_bufnr)
  if type(path_or_bufnr) == "number" then
    local bufnr = path_or_bufnr
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return nil, { code = "E_FILE_UNREADABLE", message = "invalid bufnr" }
    end
    local path = vim.api.nvim_buf_get_name(bufnr)
    if path == "" then
      return nil, { code = "E_FILE_UNREADABLE", message = "buffer has no file path" }
    end
    return normalize_path(path)
  end

  if type(path_or_bufnr) ~= "string" or path_or_bufnr == "" then
    return nil, { code = "E_FILE_UNREADABLE", message = "invalid target" }
  end

  return normalize_path(path_or_bufnr)
end

local function expand_agenda_files(cfg)
  local patterns = cfg.org_agenda_files
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
      if file:match("%.org$") and vim.fn.filereadable(file) == 1 then
        table.insert(files, normalize_path(file))
      end
    end
  end
  return uniq(files)
end

local function agenda_file_set(cfg)
  local set = {}
  for _, file in ipairs(expand_agenda_files(cfg)) do
    set[file] = true
  end
  return set
end

local function get_mtime(path)
  if not uv then
    return nil
  end
  local stat = uv.fs_stat(path)
  if not stat or not stat.mtime then
    return nil
  end
  local sec = stat.mtime.sec or 0
  local nsec = stat.mtime.nsec or 0
  return sec .. ":" .. nsec
end

local function is_loaded_buffer_for_path(path)
  local bufnr = vim.fn.bufnr(path)
  if bufnr == -1 then
    return nil
  end
  if vim.fn.bufloaded(bufnr) ~= 1 then
    return nil
  end
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end
  return bufnr
end

local function resolve_target(path_or_bufnr, allow_unloaded)
  if type(path_or_bufnr) == "number" then
    local bufnr = path_or_bufnr
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return nil, nil, { code = "E_FILE_UNREADABLE", message = "invalid bufnr" }
    end
    local path = vim.api.nvim_buf_get_name(bufnr)
    if path == "" then
      return nil, nil, { code = "E_FILE_UNREADABLE", message = "buffer has no file path" }
    end
    return bufnr, normalize_path(path)
  end

  if type(path_or_bufnr) ~= "string" or path_or_bufnr == "" then
    return nil, nil, { code = "E_FILE_UNREADABLE", message = "invalid target" }
  end

  local path = normalize_path(path_or_bufnr)
  local bufnr = is_loaded_buffer_for_path(path)
  if not bufnr then
    if allow_unloaded then
      return nil, path
    end
    return nil, nil, { code = "E_FILE_UNREADABLE", message = "buffer not loaded" }
  end
  return bufnr, path
end

function M.is_agenda_file(cfg, path_or_bufnr)
  local path, err = extract_path(path_or_bufnr)
  if err then
    return false
  end
  return agenda_file_set(cfg)[path] == true
end

local function build_derived_set(cfg)
  return {
    [cfg.derived_tags.project] = true,
    [cfg.derived_tags.stuck] = true,
    [cfg.derived_tags.archive_candidate] = true,
  }
end

local function compare_snapshot(bufnr, path, snap_tick, snap_mtime)
  local cur_tick = vim.api.nvim_buf_get_changedtick(bufnr)
  if cur_tick ~= snap_tick then
    return false
  end
  local cur_mtime = get_mtime(path)
  if cur_mtime ~= snap_mtime then
    return false
  end
  return true
end

local function compute_updated_lines(cfg, lines)
  local ok_parse, nodes = pcall(parser.parse_lines, lines)
  if not ok_parse then
    return { ok = false, error = { code = "E_PARSE_HEADLINE", message = tostring(nodes) } }
  end

  local ok_rules, desired = pcall(rules.compute, lines, nodes, cfg)
  if not ok_rules then
    return { ok = false, error = { code = "E_RUNTIME_INTERNAL", message = tostring(desired) } }
  end

  local changed = false
  local derived_set = build_derived_set(cfg)
  local updated_lines = vim.deepcopy(lines)

  for _, node in ipairs(nodes) do
    local merged_tags = parser.merge_tags(node, desired[node.index] or {}, derived_set)
    local new_line = parser.build_line_with_tags(node, merged_tags)
    if new_line ~= node.raw then
      updated_lines[node.line_nr] = new_line
      changed = true
    end
  end

  return {
    ok = true,
    changed = changed,
    lines = updated_lines,
  }
end

local function apply_refresh_once(cfg, bufnr, path)
  local ok_lines, lines = pcall(vim.api.nvim_buf_get_lines, bufnr, 0, -1, false)
  if not ok_lines then
    return { ok = false, error = { code = "E_FILE_UNREADABLE", message = tostring(lines) } }
  end

  local snapshot_tick = vim.api.nvim_buf_get_changedtick(bufnr)
  local snapshot_mtime = get_mtime(path)

  local computed = compute_updated_lines(cfg, lines)
  if not computed.ok then
    return computed
  end

  if not compare_snapshot(bufnr, path, snapshot_tick, snapshot_mtime) then
    return { ok = false, error = { code = "E_CONFLICT_STALE_SNAPSHOT", message = "snapshot changed before writeback" } }
  end

  if not computed.changed then
    return { ok = true, changed = false }
  end

  if not compare_snapshot(bufnr, path, snapshot_tick, snapshot_mtime) then
    return { ok = false, error = { code = "E_CONFLICT_STALE_SNAPSHOT", message = "snapshot changed during writeback" } }
  end

  vim.b[bufnr].org_norang_internal_write = true
  local ok_set, err_set = pcall(vim.api.nvim_buf_set_lines, bufnr, 0, -1, false, computed.lines)
  vim.b[bufnr].org_norang_internal_write = false

  if not ok_set then
    return { ok = false, error = { code = "E_WRITE_FAILED", message = tostring(err_set) } }
  end

  return { ok = true, changed = true }
end

local function apply_refresh_unloaded_once(cfg, path)
  local snapshot_mtime = get_mtime(path)
  local ok_lines, lines = pcall(vim.fn.readfile, path)
  if not ok_lines or type(lines) ~= "table" then
    return { ok = false, error = { code = "E_FILE_UNREADABLE", message = tostring(lines) } }
  end

  local computed = compute_updated_lines(cfg, lines)
  if not computed.ok then
    return computed
  end

  if not computed.changed then
    return { ok = true, changed = false }
  end

  if get_mtime(path) ~= snapshot_mtime then
    return { ok = false, error = { code = "E_CONFLICT_STALE_SNAPSHOT", message = "snapshot changed before file writeback" } }
  end

  local ok_write, ret = pcall(vim.fn.writefile, computed.lines, path)
  if not ok_write or ret ~= 0 then
    return { ok = false, error = { code = "E_WRITE_FAILED", message = tostring(ret) } }
  end

  return { ok = true, changed = true }
end

local function with_lock(path, fn)
  local lock = locks[path]
  if lock and lock.busy then
    lock.pending = true
    return { ok = true, coalesced = true }
  end

  if not lock then
    lock = { busy = false, pending = false }
    locks[path] = lock
  end

  lock.busy = true
  lock.pending = false

  local last_result = nil
  repeat
    lock.pending = false
    local ok, result = xpcall(fn, debug.traceback)
    if not ok then
      lock.busy = false
      lock.pending = false
      return { ok = false, error = { code = "E_RUNTIME_INTERNAL", message = tostring(result) } }
    end
    last_result = result
  until not lock.pending

  lock.busy = false
  return last_result
end

function M.refresh_file(cfg, path_or_bufnr)
  local refresh_unloaded = cfg.refresh and cfg.refresh.refresh_unloaded_files == true
  local bufnr, path, err = resolve_target(path_or_bufnr, refresh_unloaded)
  if err then
    return { ok = false, error = err }
  end
  if not path:match("%.org$") then
    return { ok = false, error = { code = "E_FILE_UNREADABLE", message = "not an org file" } }
  end
  if not M.is_agenda_file(cfg, path) then
    return { ok = false, error = { code = "E_FILE_UNREADABLE", message = "file is not in org_agenda_files" } }
  end

  local ok, result = pcall(with_lock, path, function()
    if not bufnr then
      if not refresh_unloaded then
        return { ok = false, error = { code = "E_FILE_UNREADABLE", message = "buffer not loaded" } }
      end
      return apply_refresh_unloaded_once(cfg, path)
    end
    return apply_refresh_once(cfg, bufnr, path)
  end)

  if not ok then
    return { ok = false, error = { code = "E_RUNTIME_INTERNAL", message = tostring(result) } }
  end
  return result
end

function M.refresh_all(cfg)
  local files = expand_agenda_files(cfg)
  local refresh_unloaded = cfg.refresh and cfg.refresh.refresh_unloaded_files == true
  local summary = {
    total = #files,
    ok = 0,
    fail = 0,
    skipped_conflict = 0,
    skipped_unloaded = 0,
    results = {},
  }

  for _, path in ipairs(files) do
    local bufnr = is_loaded_buffer_for_path(path)
    if not bufnr and not refresh_unloaded then
      summary.skipped_unloaded = summary.skipped_unloaded + 1
      table.insert(summary.results, { path = path, ok = false, skipped = "unloaded" })
    else
      local target = bufnr or path
      local result = M.refresh_file(cfg, target)
      table.insert(summary.results, vim.tbl_extend("keep", { path = path }, result))
      if result.ok then
        summary.ok = summary.ok + 1
      elseif result.error and result.error.code == "E_CONFLICT_STALE_SNAPSHOT" then
        summary.skipped_conflict = summary.skipped_conflict + 1
      else
        summary.fail = summary.fail + 1
      end
    end
  end

  summary.conserved = summary.total == (summary.ok + summary.fail + summary.skipped_conflict + summary.skipped_unloaded)
  return summary
end

return M
