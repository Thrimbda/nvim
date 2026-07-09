local parser = require("org_legion.parser")
local rules = require("org_legion.rules")

local M = {}

local uv = vim.uv or vim.loop
local locks = {}
local adapter_installed = false
local original_apply_search = nil

M._index = {}

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

local function uniq(list)
  local out, seen = {}, {}
  for _, item in ipairs(list or {}) do
    if not seen[item] then
      seen[item] = true
      table.insert(out, item)
    end
  end
  return out
end

local function configured_tags(cfg)
  local derived = cfg and cfg.derived_tags or {}
  local tags = {
    derived.project,
    derived.stuck,
    derived.project_task,
    derived.archive_candidate,
  }
  return vim.tbl_filter(function(tag)
    return type(tag) == "string" and tag ~= ""
  end, tags)
end

local function configured_tag_set(cfg)
  local set = {}
  for _, tag in ipairs(configured_tags(cfg)) do
    set[tag] = true
  end
  return set
end

function M.is_archive_candidate_query(cfg, term)
  if not cfg or cfg.enabled == false or type(term) ~= "string" then
    return false
  end
  return vim.trim(term) == "-REFILE/"
end

local function config_signature(cfg)
  local parts = {}
  vim.list_extend(parts, configured_tags(cfg))
  vim.list_extend(parts, cfg.todo and cfg.todo.active or {})
  table.insert(parts, "|")
  vim.list_extend(parts, cfg.todo and cfg.todo.done or {})
  table.insert(parts, cfg.todo and cfg.todo.next or "")
  table.insert(parts, tostring(cfg.archive and cfg.archive.stale_days or ""))
  table.insert(parts, tostring(cfg.archive and cfg.archive.recent_month_window or ""))
  return table.concat(parts, "\31")
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
  return ("%s:%s"):format(stat.mtime.sec or 0, stat.mtime.nsec or 0)
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

local function extract_path(path_or_bufnr)
  if type(path_or_bufnr) == "number" then
    if not vim.api.nvim_buf_is_valid(path_or_bufnr) then
      return nil, { code = "E_FILE_UNREADABLE", message = "invalid bufnr" }
    end
    local path = vim.api.nvim_buf_get_name(path_or_bufnr)
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

local function read_target_lines(path_or_bufnr, allow_unloaded)
  if type(path_or_bufnr) == "number" then
    if not vim.api.nvim_buf_is_valid(path_or_bufnr) then
      return nil, nil, nil, { code = "E_FILE_UNREADABLE", message = "invalid bufnr" }
    end
    local path = vim.api.nvim_buf_get_name(path_or_bufnr)
    if path == "" then
      return nil, nil, nil, { code = "E_FILE_UNREADABLE", message = "buffer has no file path" }
    end
    local ok, lines = pcall(vim.api.nvim_buf_get_lines, path_or_bufnr, 0, -1, false)
    if not ok then
      return nil, nil, nil, { code = "E_FILE_UNREADABLE", message = tostring(lines) }
    end
    local source_id = ("buf:%s:%s"):format(path_or_bufnr, vim.api.nvim_buf_get_changedtick(path_or_bufnr))
    return normalize_path(path), lines, source_id
  end

  local path, err = extract_path(path_or_bufnr)
  if err then
    return nil, nil, nil, err
  end

  local bufnr = loaded_buf_for_path(path)
  if bufnr then
    local ok, lines = pcall(vim.api.nvim_buf_get_lines, bufnr, 0, -1, false)
    if not ok then
      return nil, nil, nil, { code = "E_FILE_UNREADABLE", message = tostring(lines) }
    end
    local source_id = ("buf:%s:%s"):format(bufnr, vim.api.nvim_buf_get_changedtick(bufnr))
    return path, lines, source_id
  end

  if not allow_unloaded then
    return nil, nil, nil, { code = "E_FILE_UNREADABLE", message = "buffer not loaded" }
  end

  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or type(lines) ~= "table" then
    return nil, nil, nil, { code = "E_FILE_UNREADABLE", message = tostring(lines) }
  end
  return path, lines, "file:" .. tostring(get_mtime(path))
end

local function file_lines(file)
  if file then
    local ok_buf, bufnr = pcall(function()
      return file:bufnr()
    end)
    if ok_buf and type(bufnr) == "number" and bufnr > -1 and vim.api.nvim_buf_is_loaded(bufnr) then
      local ok_lines, lines = pcall(vim.api.nvim_buf_get_lines, bufnr, 0, -1, false)
      if ok_lines and type(lines) == "table" then
        return lines, ("buf:%s:%s"):format(bufnr, vim.api.nvim_buf_get_changedtick(bufnr))
      end
    end
  end

  if file and type(file.lines) == "table" then
    local meta = file.metadata or {}
    return file.lines, ("file:%s:%s"):format(meta.mtime_sec or "", meta.mtime or "")
  end

  if file and type(file.filename) == "string" then
    local ok, lines = pcall(vim.fn.readfile, file.filename)
    if ok and type(lines) == "table" then
      return lines, "file:" .. tostring(get_mtime(file.filename))
    end
  end

  return nil, nil
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

function M.is_agenda_file(cfg, path_or_bufnr)
  local path, err = extract_path(path_or_bufnr)
  if err then
    return false
  end
  return agenda_file_set(cfg)[path] == true
end

function M.has_virtual_query(cfg, term)
  if not cfg or cfg.enabled == false or type(term) ~= "string" or term == "" then
    return false
  end

  if M.is_archive_candidate_query(cfg, term) then
    return true
  end

  local wanted = configured_tag_set(cfg)
  for token in term:gmatch("[%w_@#%%]+") do
    if wanted[token] then
      return true
    end
  end
  return false
end

function M.index_lines(cfg, path, lines, source_id)
  local ok_parse, nodes = pcall(parser.parse_lines, lines)
  if not ok_parse then
    return { ok = false, error = { code = "E_PARSE_HEADLINE", message = tostring(nodes) } }
  end

  local ok_rules, desired = pcall(rules.compute, lines, nodes, cfg)
  if not ok_rules then
    return { ok = false, error = { code = "E_RUNTIME_INTERNAL", message = tostring(desired) } }
  end

  local tags_by_line = {}
  local tag_sets_by_line = {}
  for _, node in ipairs(nodes) do
    local tags = {}
    local tag_set = {}
    local wanted = desired[node.index] or {}
    for _, tag in ipairs(configured_tags(cfg)) do
      if wanted[tag] then
        table.insert(tags, tag)
        tag_set[tag] = true
      end
    end
    tags_by_line[node.line_nr] = tags
    tag_sets_by_line[node.line_nr] = tag_set
  end

  M._index[normalize_path(path)] = {
    source_id = config_signature(cfg) .. "|" .. tostring(source_id or ""),
    tags_by_line = tags_by_line,
    tag_sets_by_line = tag_sets_by_line,
  }

  return { ok = true, changed = false, indexed = true }
end

function M.refresh_file(cfg, path_or_bufnr)
  local refresh_unloaded = cfg.refresh and cfg.refresh.refresh_unloaded_files == true
  local path, lines, source_id, err = read_target_lines(path_or_bufnr, refresh_unloaded)
  if err then
    return { ok = false, error = err }
  end
  if not path:match("%.org$") then
    return { ok = false, error = { code = "E_FILE_UNREADABLE", message = "not an org file" } }
  end
  if not M.is_agenda_file(cfg, path) then
    return { ok = false, error = { code = "E_FILE_UNREADABLE", message = "file is not in org_agenda_files" } }
  end

  return with_lock(path, function()
    return M.index_lines(cfg, path, lines, source_id)
  end)
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
    local bufnr = loaded_buf_for_path(path)
    if not bufnr and not refresh_unloaded then
      summary.skipped_unloaded = summary.skipped_unloaded + 1
      table.insert(summary.results, { path = path, ok = false, skipped = "unloaded" })
    else
      local result = M.refresh_file(cfg, bufnr or path)
      table.insert(summary.results, vim.tbl_extend("keep", { path = path }, result))
      if result.ok then
        summary.ok = summary.ok + 1
      else
        summary.fail = summary.fail + 1
      end
    end
  end

  summary.conserved = summary.total == (summary.ok + summary.fail + summary.skipped_conflict + summary.skipped_unloaded)
  return summary
end

local function get_file_index(cfg, file)
  if not file or type(file.filename) ~= "string" then
    return nil, { code = "E_FILE_UNREADABLE", message = "org file is missing filename" }
  end

  local path = normalize_path(file.filename)
  local lines, source_id = file_lines(file)
  if type(lines) ~= "table" then
    return nil, { code = "E_FILE_UNREADABLE", message = "org file has no readable lines" }
  end

  local index_id = config_signature(cfg) .. "|" .. tostring(source_id or "")
  local existing = M._index[path]
  if existing and existing.source_id == index_id then
    return existing
  end

  local result = M.index_lines(cfg, path, lines, source_id)
  if not result.ok then
    return nil, result.error
  end
  return M._index[path]
end

local function headline_start_line(headline)
  local ok, range = pcall(function()
    return headline:get_range()
  end)
  if ok and range and type(range.start_line) == "number" then
    return range.start_line
  end
  return nil
end

local function combined_tags(cfg, index, headline)
  local line_nr = headline_start_line(headline)
  local virtual_tags = line_nr and index.tags_by_line[line_nr] or {}
  local virtual_set = configured_tag_set(cfg)
  local out, seen = {}, {}

  local actual_tags = headline:get_tags()
  for _, tag in ipairs(actual_tags or {}) do
    if not virtual_set[tag] and not seen[tag] then
      table.insert(out, tag)
      seen[tag] = true
    end
  end

  for _, tag in ipairs(virtual_tags or {}) do
    if not seen[tag] then
      table.insert(out, tag)
      seen[tag] = true
    end
  end

  return out
end

local function searchable_item(cfg, index, headline)
  local deadline = headline:get_deadline_date()
  local scheduled = headline:get_scheduled_date()
  local closed = headline:get_closed_date()
  local properties = headline:get_own_properties()
  local priority = headline:get_priority()
  local level = headline:get_level()
  local todo = headline:get_todo() or ""

  return {
    props = vim.tbl_extend("keep", {}, properties or {}, {
      category = headline:get_category(),
      deadline = deadline and deadline:to_wrapped_string(true),
      scheduled = scheduled and scheduled:to_wrapped_string(true),
      closed = closed and closed:to_wrapped_string(false),
      priority = priority,
      todo = todo,
      level = level,
    }),
    tags = combined_tags(cfg, index, headline),
    todo = todo,
  }
end

local function headline_has_virtual_tag(cfg, index, headline, tag)
  local line_nr = headline_start_line(headline)
  local tag_set = line_nr and index.tag_sets_by_line[line_nr] or nil
  return tag_set and tag_set[tag] == true
end

function M.apply_search(cfg, file, search, todo_only)
  if file:is_archive_file() then
    return {}
  end

  local index, err = get_file_index(cfg, file)
  if not index then
    error(err and err.message or "failed to build org_legion virtual tag index")
  end

  local archive_candidate_query = M.is_archive_candidate_query(cfg, search and search.term)

  return vim.tbl_filter(function(headline)
    if headline:is_archived() or (todo_only and not headline:is_todo()) then
      return false
    end
    if archive_candidate_query and not headline_has_virtual_tag(cfg, index, headline, cfg.derived_tags.archive_candidate) then
      return false
    end
    return search:check(searchable_item(cfg, index, headline))
  end, file:get_headlines())
end

function M.match_headline(cfg, headline, query, opts)
  opts = opts or {}
  local ok_search, Search = pcall(require, "orgmode.files.elements.search")
  if not ok_search then
    return false, { code = "E_RUNTIME_INTERNAL", message = tostring(Search) }
  end

  local search = Search:new(query or "")
  local index, err = get_file_index(cfg, headline.file)
  if not index then
    return false, err
  end
  if opts.todo_only and not headline:is_todo() then
    return false
  end
  if M.is_archive_candidate_query(cfg, query) and not headline_has_virtual_tag(cfg, index, headline, cfg.derived_tags.archive_candidate) then
    return false
  end
  return search:check(searchable_item(cfg, index, headline))
end

function M.get_tags_for_line(cfg, path_or_bufnr, line_nr)
  local path, err = extract_path(path_or_bufnr)
  if err then
    return {}, err
  end

  local refresh_result = M.refresh_file(cfg, path_or_bufnr)
  if not refresh_result.ok and not M._index[normalize_path(path)] then
    return {}, refresh_result.error
  end

  local index = M._index[normalize_path(path)]
  return vim.deepcopy((index and index.tags_by_line[line_nr]) or {})
end

function M.setup_search_adapter(cfg_provider)
  if adapter_installed then
    return true
  end

  local ok_file, OrgFile = pcall(require, "orgmode.files.file")
  if not ok_file then
    return false, tostring(OrgFile)
  end
  if type(OrgFile.apply_search) ~= "function" then
    return false, "orgmode OrgFile.apply_search is unavailable"
  end

  original_apply_search = OrgFile.apply_search
  OrgFile.apply_search = function(file, search, todo_only)
    local cfg = cfg_provider and cfg_provider() or nil
    if cfg and M.has_virtual_query(cfg, search and search.term) then
      local ok, result = pcall(M.apply_search, cfg, file, search, todo_only)
      if ok then
        return result
      end
      if not (cfg.observability and cfg.observability.notify == false) then
        vim.notify("org_legion virtual agenda search failed: " .. tostring(result), vim.log.levels.WARN)
      end
    end

    return original_apply_search(file, search, todo_only)
  end

  adapter_installed = true
  return true
end

return M
