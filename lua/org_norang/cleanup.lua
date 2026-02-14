local parser = require("org_norang.parser")

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

local function expand_agenda_files(cfg)
  local patterns = cfg.org_agenda_files
  if type(patterns) == "string" then
    patterns = { patterns }
  end

  local files = {}
  for _, pattern in ipairs(patterns or {}) do
    local expanded = vim.fn.expand(pattern)
    local matches = vim.fn.glob(expanded, true, true)
    for _, file in ipairs(matches) do
      if file:match("%.org$") and vim.fn.filereadable(file) == 1 then
        table.insert(files, normalize_path(file))
      end
    end
  end
  return uniq(files)
end

local function loaded_buf_for_path(path)
  local bufnr = vim.fn.bufnr(path)
  if bufnr == -1 or vim.fn.bufloaded(bufnr) ~= 1 then
    return nil
  end
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end
  return bufnr
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

local function derived_set(cfg)
  return {
    [cfg.derived_tags.project] = true,
    [cfg.derived_tags.stuck] = true,
    [cfg.derived_tags.archive_candidate] = true,
  }
end

local function cleanup_buffer(cfg, bufnr, path, apply)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local snapshot_tick = vim.api.nvim_buf_get_changedtick(bufnr)
  local snapshot_mtime = get_mtime(path)

  local nodes = parser.parse_lines(lines)
  local dset = derived_set(cfg)

  local changed = false
  local changed_lines = 0
  local new_lines = vim.deepcopy(lines)

  for _, node in ipairs(nodes) do
    local kept = {}
    local seen = {}
    for _, tag in ipairs(node.tags) do
      if not dset[tag] and not seen[tag] then
        table.insert(kept, tag)
        seen[tag] = true
      end
    end

    local newline = parser.build_line_with_tags(node, kept)
    if newline ~= node.raw then
      changed = true
      changed_lines = changed_lines + 1
      if apply then
        new_lines[node.line_nr] = newline
      end
    end
  end

  if changed and apply then
    if not compare_snapshot(bufnr, path, snapshot_tick, snapshot_mtime) then
      return { ok = false, error = { code = "E_CONFLICT_STALE_SNAPSHOT", message = "snapshot changed before cleanup writeback" } }
    end

    vim.b[bufnr].org_norang_internal_write = true
    local ok_set, err_set = pcall(vim.api.nvim_buf_set_lines, bufnr, 0, -1, false, new_lines)
    vim.b[bufnr].org_norang_internal_write = false

    if not ok_set then
      return { ok = false, error = { code = "E_WRITE_FAILED", message = tostring(err_set) } }
    end
  end

  return {
    ok = true,
    changed = changed,
    changed_lines = changed_lines,
  }
end

function M.cleanup_derived_tags(cfg, opts)
  opts = opts or {}
  local apply = opts.apply == true

  local files = expand_agenda_files(cfg)
  local summary = {
    apply = apply,
    total = #files,
    touched = 0,
    changed_files = 0,
    changed_lines = 0,
    fail = 0,
    skipped_conflict = 0,
    skipped_unloaded = 0,
    results = {},
  }

  for _, path in ipairs(files) do
    local bufnr = loaded_buf_for_path(path)
    if not bufnr then
      summary.skipped_unloaded = summary.skipped_unloaded + 1
      table.insert(summary.results, { path = path, ok = false, skipped = "unloaded" })
    else
      local ok, result = pcall(with_lock, path, function()
        return cleanup_buffer(cfg, bufnr, path, apply)
      end)
      summary.touched = summary.touched + 1
      if ok then
        if result.ok and result.changed then
          summary.changed_files = summary.changed_files + 1
          summary.changed_lines = summary.changed_lines + result.changed_lines
        elseif not result.ok and result.error and result.error.code == "E_CONFLICT_STALE_SNAPSHOT" then
          summary.skipped_conflict = summary.skipped_conflict + 1
        elseif not result.ok then
          summary.fail = summary.fail + 1
        end
        table.insert(summary.results, vim.tbl_extend("keep", { path = path }, result))
      else
        summary.fail = summary.fail + 1
        table.insert(summary.results, {
          path = path,
          ok = false,
          error = { code = "E_RUNTIME_INTERNAL", message = tostring(result) },
        })
      end
    end
  end

  return summary
end

return M
