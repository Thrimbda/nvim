local M = {}

local precise_warned = false

local function setify(list)
  local out = {}
  for _, item in ipairs(list or {}) do
    out[item] = true
  end
  return out
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
      vim.notify("org_legion: refresh.mode=precise is not implemented in V1, fallback to approx", vim.log.levels.WARN)
    end
  end
end

local function archive_month_prefixes(now)
  local this_month = month_start(now)
  local last_month = shift_month(this_month, -1)
  return {
    os.date("%Y-%m-", this_month),
    os.date("%Y-%m-", last_month),
  }
end

local function subtree_has_current_archive_timestamp(lines, start_line, end_line, month_prefixes)
  for i = start_line, end_line do
    local line = lines[i] or ""
    for _, prefix in ipairs(month_prefixes) do
      if line:find(prefix, 1, true) then
        return true
      end
    end
  end
  return false
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
  local archive_current_months = archive_month_prefixes(os.time())

  local out = {}
  local project_by_index = {}
  local stuck_by_index = {}
  local archive_by_index = {}

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
      archive_candidate = not subtree_has_current_archive_timestamp(lines, node.line_nr + 1, node.end_line, archive_current_months)
    end

    project_by_index[node.index] = is_project
    stuck_by_index[node.index] = is_stuck
    archive_by_index[node.index] = archive_candidate
  end

  for _, node in ipairs(nodes) do
    local has_project_ancestor = false
    local parent_idx = node.parent
    while parent_idx do
      if project_by_index[parent_idx] then
        has_project_ancestor = true
        break
      end
      parent_idx = nodes[parent_idx] and nodes[parent_idx].parent or nil
    end

    local is_project_task = active_set[node.todo] and not project_by_index[node.index] and has_project_ancestor

    out[node.index] = {
      [cfg.derived_tags.project] = project_by_index[node.index],
      [cfg.derived_tags.stuck] = stuck_by_index[node.index],
      [cfg.derived_tags.project_task] = is_project_task,
      [cfg.derived_tags.archive_candidate] = archive_by_index[node.index],
    }
  end

  return out
end

return M
