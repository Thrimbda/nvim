local M = {}

local precise_warned = false

local function setify(list)
  local out = {}
  for _, item in ipairs(list or {}) do
    out[item] = true
  end
  return out
end

local function parse_ymd(text)
  local y, m, d = text:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
  if not y then
    return nil
  end
  return os.time({
    year = tonumber(y),
    month = tonumber(m),
    day = tonumber(d),
    hour = 0,
    min = 0,
    sec = 0,
  })
end

local function month_start(ts)
  local t = os.date("*t", ts)
  return os.time({ year = t.year, month = t.month, day = 1, hour = 0, min = 0, sec = 0 })
end

local function shift_month(ts, delta)
  local t = os.date("*t", ts)
  local year = t.year
  local month = t.month + delta

  while month < 1 do
    month = month + 12
    year = year - 1
  end
  while month > 12 do
    month = month - 12
    year = year + 1
  end

  return os.time({ year = year, month = month, day = 1, hour = 0, min = 0, sec = 0 })
end

local function maybe_warn_precise(cfg)
  if cfg.refresh.mode == "precise" and not precise_warned then
    precise_warned = true
    if not (cfg.observability and cfg.observability.notify == false) then
      vim.notify("org_norang: refresh.mode=precise is not implemented in V1, fallback to approx", vim.log.levels.WARN)
    end
  end
end

local function find_last_activity_ts(lines, start_line, end_line)
  local latest = nil
  for i = start_line, end_line do
    local line = lines[i] or ""
    for ymd in line:gmatch("%d%d%d%d%-%d%d%-%d%d") do
      local ts = parse_ymd(ymd)
      if ts and (not latest or ts > latest) then
        latest = ts
      end
    end
  end
  return latest
end

local function for_each_descendant(nodes, node, cb)
  for i = node.index + 1, #nodes do
    local cand = nodes[i]
    if cand.line_nr > node.end_line then
      break
    end
    cb(cand)
  end
end

function M.compute(lines, nodes, cfg)
  maybe_warn_precise(cfg)

  local active_set = setify(cfg.todo.active)
  local done_set = setify(cfg.todo.done)
  local todo_set = setify(vim.list_extend(vim.deepcopy(cfg.todo.active or {}), cfg.todo.done or {}))
  local next_kw = cfg.todo.next
  local stale_days = cfg.archive.stale_days
  local recent_month_window = cfg.archive.recent_month_window

  local now = os.time()
  local stale_before = now - (stale_days * 24 * 60 * 60)
  local recent_cutoff = shift_month(month_start(now), -(recent_month_window - 1))

  local out = {}

  for _, node in ipairs(nodes) do
    local has_todo_descendant = false
    local has_next_descendant = false

    for_each_descendant(nodes, node, function(desc)
      if todo_set[desc.todo] then
        has_todo_descendant = true
      end
      if desc.todo == next_kw and not vim.tbl_contains(desc.tags or {}, "WAITING") then
        has_next_descendant = true
      end
    end)

    local is_project = active_set[node.todo] and has_todo_descendant
    local is_stuck = is_project and not has_next_descendant

    local archive_candidate = false
    if done_set[node.todo] then
      local last_activity = find_last_activity_ts(lines, node.line_nr, node.end_line)
      local stale = (not last_activity) or (last_activity <= stale_before)
      local has_recent_activity = last_activity and (last_activity >= recent_cutoff)
      archive_candidate = stale and (not has_recent_activity)
    end

    out[node.index] = {
      [cfg.derived_tags.project] = is_project,
      [cfg.derived_tags.stuck] = is_stuck,
      [cfg.derived_tags.archive_candidate] = archive_candidate,
    }
  end

  return out
end

return M
