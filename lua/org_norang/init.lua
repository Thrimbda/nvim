local refresh = require("org_norang.refresh")
local cleanup = require("org_norang.cleanup")

local M = {}

local defaults = {
  enabled = true,
  org_agenda_files = { "~/OneDrive/cone/**/*.org" },
  refresh = {
    mode = "approx",
    on_buf_write = true,
    debounce_ms = 120,
    writeback = "memory_only",
    refresh_unloaded_files = true,
  },
  derived_tags = {
    project = "PROJECT",
    stuck = "STUCK",
    archive_candidate = "ARCHIVE_CANDIDATE",
  },
  todo = {
    active = { "TODO", "NEXT", "WAITING", "HOLD" },
    done = { "DONE", "CANCELLED" },
    next = "NEXT",
  },
  archive = {
    stale_days = 30,
    recent_month_window = 2,
  },
  observability = {
    notify = true,
    log_level = "info",
  },
}

M.state = {
  phase = "S0",
  cfg_error = nil,
}

M._cfg = nil
M._user_opts = {}

local function notify(cfg, msg, level)
  level = level or vim.log.levels.INFO
  if cfg and type(cfg.observability) == "table" and cfg.observability.notify == false then
    return
  end
  vim.notify(msg, level)
end

local function is_string_list(value)
  if type(value) ~= "table" then
    return false
  end
  for _, item in ipairs(value) do
    if type(item) ~= "string" or item == "" then
      return false
    end
  end
  return true
end

local function is_valid_derived_tag(tag)
  return type(tag) == "string" and tag ~= "" and tag:match("^[A-Z][A-Z0-9_]*$") ~= nil
end

local function validate_cfg(cfg)
  if type(cfg) ~= "table" then
    return false, "config must be a table"
  end
  if type(cfg.enabled) ~= "boolean" then
    return false, "enabled must be boolean"
  end

  if type(cfg.org_agenda_files) ~= "string" and not is_string_list(cfg.org_agenda_files) then
    return false, "org_agenda_files must be string or string[]"
  end

  if type(cfg.refresh) ~= "table" then
    return false, "refresh must be a table"
  end
  if type(cfg.refresh.mode) ~= "string" then
    return false, "refresh.mode must be string"
  end
  if type(cfg.refresh.on_buf_write) ~= "boolean" then
    return false, "refresh.on_buf_write must be boolean"
  end
  if type(cfg.refresh.debounce_ms) ~= "number" or cfg.refresh.debounce_ms < 0 then
    return false, "refresh.debounce_ms must be number >= 0"
  end
  if type(cfg.refresh.writeback) ~= "string" then
    return false, "refresh.writeback must be string"
  end
  if type(cfg.refresh.refresh_unloaded_files) ~= "boolean" then
    return false, "refresh.refresh_unloaded_files must be boolean"
  end

  if type(cfg.derived_tags) ~= "table" then
    return false, "derived_tags must be a table"
  end
  if not is_valid_derived_tag(cfg.derived_tags.project) then
    return false, "derived_tags.project must match ^[A-Z][A-Z0-9_]*$"
  end
  if not is_valid_derived_tag(cfg.derived_tags.stuck) then
    return false, "derived_tags.stuck must match ^[A-Z][A-Z0-9_]*$"
  end
  if not is_valid_derived_tag(cfg.derived_tags.archive_candidate) then
    return false, "derived_tags.archive_candidate must match ^[A-Z][A-Z0-9_]*$"
  end

  if type(cfg.todo) ~= "table" then
    return false, "todo must be a table"
  end
  if not is_string_list(cfg.todo.active) then
    return false, "todo.active must be string[]"
  end
  if not is_string_list(cfg.todo.done) then
    return false, "todo.done must be string[]"
  end
  if type(cfg.todo.next) ~= "string" or cfg.todo.next == "" then
    return false, "todo.next must be non-empty string"
  end

  if type(cfg.archive) ~= "table" then
    return false, "archive must be a table"
  end
  if type(cfg.archive.stale_days) ~= "number" or cfg.archive.stale_days < 1 then
    return false, "archive.stale_days must be number >= 1"
  end
  if type(cfg.archive.recent_month_window) ~= "number" or cfg.archive.recent_month_window < 1 then
    return false, "archive.recent_month_window must be number >= 1"
  end

  if type(cfg.observability) ~= "table" then
    return false, "observability must be a table"
  end
  if type(cfg.observability.notify) ~= "boolean" then
    return false, "observability.notify must be boolean"
  end
  if type(cfg.observability.log_level) ~= "string" then
    return false, "observability.log_level must be string"
  end

  if cfg.refresh.writeback ~= "memory_only" then
    return false, "refresh.writeback must be memory_only in V1"
  end
  if cfg.refresh.mode ~= "approx" and cfg.refresh.mode ~= "precise" then
    return false, "refresh.mode must be approx or precise"
  end

  local uniq = {}
  for _, tag in ipairs({ cfg.derived_tags.project, cfg.derived_tags.stuck, cfg.derived_tags.archive_candidate }) do
    if uniq[tag] then
      return false, "derived tags must be distinct"
    end
    uniq[tag] = true
  end

  local todo_keywords = {}
  for _, kw in ipairs(cfg.todo.active) do
    todo_keywords[kw] = true
  end
  for _, kw in ipairs(cfg.todo.done) do
    todo_keywords[kw] = true
  end
  for _, tag in ipairs({ cfg.derived_tags.project, cfg.derived_tags.stuck, cfg.derived_tags.archive_candidate }) do
    if todo_keywords[tag] then
      return false, "derived tags must not overlap todo keywords"
    end
  end

  local next_found = false
  for _, kw in ipairs(cfg.todo.active or {}) do
    if kw == cfg.todo.next then
      next_found = true
      break
    end
  end
  if not next_found then
    return false, "todo.next must be in todo.active"
  end
  return true
end

local function command_guard(cfg, allow_dry_cleanup)
  if M.state.phase ~= "S5" then
    return true
  end
  if allow_dry_cleanup then
    return true
  end
  notify(cfg, "org_norang: in error state (E_CFG_INVALID), run :OrgNorangReload", vim.log.levels.ERROR)
  return false
end

local function setup_autocmd(cfg)
  local group = vim.api.nvim_create_augroup("OrgNorang", { clear = true })
  if type(cfg.refresh) ~= "table" or not cfg.refresh.on_buf_write then
    return
  end

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = "*.org",
    callback = function(args)
      if vim.b[args.buf].org_norang_internal_write then
        vim.b[args.buf].org_norang_internal_write = false
        return
      end
      if M.state.phase == "S5" then
        return
      end
      local path = vim.api.nvim_buf_get_name(args.buf)
      if path == "" or not refresh.is_agenda_file(M._cfg, args.buf) then
        return
      end
      M.refresh_file(args.buf)
    end,
  })
end

local function clear_autocmds()
  vim.api.nvim_create_augroup("OrgNorang", { clear = true })
end

local function register_commands()
  pcall(vim.api.nvim_del_user_command, "OrgNorangRefresh")
  pcall(vim.api.nvim_del_user_command, "OrgNorangReload")
  pcall(vim.api.nvim_del_user_command, "OrgNorangCleanupDerivedTags")

  vim.api.nvim_create_user_command("OrgNorangRefresh", function()
    M.refresh_all()
  end, { desc = "Refresh derived Norang tags for org_agenda_files" })

  vim.api.nvim_create_user_command("OrgNorangReload", function()
    M.reload()
  end, { desc = "Reload org_norang config and recover from error state" })

  vim.api.nvim_create_user_command("OrgNorangCleanupDerivedTags", function(args)
    M.cleanup_derived_tags({ apply = args.bang })
  end, {
    bang = true,
    desc = "Cleanup derived tags only (! applies changes; default dry-run)",
  })
end

function M.get_config()
  return M._cfg
end

function M.setup(opts)
  if opts ~= nil and type(opts) ~= "table" then
    register_commands()
    clear_autocmds()
    M.state.phase = "S5"
    M.state.cfg_error = "setup opts must be a table"
    notify(nil, "org_norang: invalid config (E_CFG_INVALID): setup opts must be a table", vim.log.levels.ERROR)
    return false, M.state.cfg_error
  end

  if opts then
    M._user_opts = opts
  elseif type(M._user_opts) ~= "table" then
    M._user_opts = {}
  end

  M._cfg = vim.tbl_deep_extend("force", defaults, M._user_opts)

  register_commands()
  clear_autocmds()

  local ok_call, ok, err = pcall(validate_cfg, M._cfg)
  if not ok_call then
    local crashed = ok
    ok = false
    err = "config validation crashed: " .. tostring(crashed)
  end

  if not ok then
    M.state.phase = "S5"
    M.state.cfg_error = err
    notify(M._cfg, "org_norang: invalid config (E_CFG_INVALID): " .. err, vim.log.levels.ERROR)
    return false, err
  end

  setup_autocmd(M._cfg)

  M.state.phase = M._cfg.enabled and "S1" or "S0"
  M.state.cfg_error = nil
  return true
end

function M.reload(opts)
  if opts ~= nil and type(opts) ~= "table" then
    notify(M._cfg, "org_norang: reload failed (E_CFG_INVALID): reload opts must be a table", vim.log.levels.ERROR)
    return false, "reload opts must be a table"
  end
  if opts then
    M._user_opts = vim.tbl_deep_extend("force", M._user_opts or {}, opts)
  end
  local ok, err = M.setup(M._user_opts)
  if ok then
    notify(M._cfg, "org_norang: reload completed", vim.log.levels.INFO)
  else
    notify(M._cfg, "org_norang: reload failed (E_CFG_INVALID): " .. tostring(err), vim.log.levels.ERROR)
  end
  return ok, err
end

function M.refresh_file(path_or_bufnr)
  local cfg = M._cfg or defaults
  if not command_guard(cfg, false) then
    return { ok = false, error = { code = "E_CFG_INVALID", message = M.state.cfg_error } }
  end
  if M.state.phase == "S0" then
    return { ok = true, skipped = "disabled" }
  end

  M.state.phase = "S2"
  local result = refresh.refresh_file(cfg, path_or_bufnr)
  M.state.phase = result.ok and "S1" or "S4"
  return result
end

function M.refresh_all()
  local cfg = M._cfg or defaults
  if not command_guard(cfg, false) then
    return { ok = false, error = { code = "E_CFG_INVALID", message = M.state.cfg_error } }
  end
  if M.state.phase == "S0" then
    return { total = 0, ok = 0, fail = 0, skipped_conflict = 0, skipped_unloaded = 0, conserved = true }
  end

  M.state.phase = "S3"
  local summary = refresh.refresh_all(cfg)
  M.state.phase = (summary.fail > 0 or summary.skipped_conflict > 0) and "S4" or "S1"

  notify(
    cfg,
    string.format(
      "org_norang refresh: total=%d ok=%d fail=%d skipped_conflict=%d skipped_unloaded=%d",
      summary.total,
      summary.ok,
      summary.fail,
      summary.skipped_conflict,
      summary.skipped_unloaded
    ),
    summary.fail > 0 and vim.log.levels.WARN or vim.log.levels.INFO
  )

  return summary
end

function M.cleanup_derived_tags(opts)
  local cfg = M._cfg or defaults
  opts = opts or {}
  local apply = opts.apply == true

  if M.state.phase == "S5" and apply then
    notify(cfg, "org_norang: cleanup apply blocked in error state; use dry-run or :OrgNorangReload", vim.log.levels.ERROR)
    return { ok = false, error = { code = "E_CFG_INVALID", message = M.state.cfg_error } }
  end
  if not command_guard(cfg, true) then
    return { ok = false, error = { code = "E_CFG_INVALID", message = M.state.cfg_error } }
  end

  local summary = cleanup.cleanup_derived_tags(cfg, { apply = apply })
  notify(
    cfg,
    string.format(
      "org_norang cleanup (%s): total=%d touched=%d changed_files=%d changed_lines=%d fail=%d skipped_conflict=%d skipped_unloaded=%d",
      apply and "apply" or "dry-run",
      summary.total,
      summary.touched,
      summary.changed_files,
      summary.changed_lines,
      summary.fail,
      summary.skipped_conflict,
      summary.skipped_unloaded
    ),
    vim.log.levels.INFO
  )
  return summary
end

return M
