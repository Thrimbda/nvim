local M = {
  _installed = false,
  _state = {
    active = false,
    previous = nil,
    capture_started_at = nil,
    clock_injected = false,
  },
}

local Date = require("orgmode.objects.date")
local Duration = require("orgmode.objects.duration")

local function get_orgmode()
  local ok, orgmode = pcall(require, "orgmode")
  if not ok then
    return nil
  end
  return orgmode
end

local function run_clock_method(orgmode, method)
  if not orgmode or not orgmode.clock or type(orgmode.clock[method]) ~= "function" then
    return false
  end

  local ok, result = pcall(orgmode.clock[method], orgmode.clock)
  if not ok then
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

local function pause_active_clock(orgmode)
  local ok_punch, punch = pcall(require, "org_punch")
  if ok_punch and type(punch.clock_out_current_task) == "function" then
    local ok_call, result = pcall(punch.clock_out_current_task, {
      ignore_keep_running = true,
      silent = true,
    })
    if ok_call and result == true then
      return true
    end
  end

  return run_clock_method(orgmode, "org_clock_out")
end

local function snapshot_active_clock(orgmode)
  if not orgmode or not orgmode.clock then
    return nil
  end

  orgmode.clock:update_clocked_headline()
  local headline = orgmode.clock.clocked_headline
  if not headline or not headline:is_clocked_in() then
    return nil
  end

  return {
    file = headline.file.filename,
    line = headline:get_range().start_line,
  }
end

local function build_capture_clock_line(headline, started_at, ended_at)
  local indent = headline:get_indent()
  local start_ts = tonumber(started_at) or os.time()
  local end_ts = tonumber(ended_at) or os.time()
  if end_ts < start_ts then
    end_ts = start_ts
  end

  local minute_delta = math.floor(end_ts / 60) - math.floor(start_ts / 60)
  if minute_delta <= 0 then
    return nil
  end

  local start = Date.from_timestamp(start_ts, { active = false })
  local finish = Date.from_timestamp(end_ts, { active = false })
  local duration = Duration.from_minutes(minute_delta):to_string("HH:MM")

  return string.format(
    "%sCLOCK: %s--%s => %s",
    indent,
    start:to_wrapped_string(),
    finish:to_wrapped_string(),
    duration
  )
end

local function inject_capture_clock_line(headline, started_at, ended_at)
  if not headline then
    return false
  end

  local bufnr = headline.file:bufnr()
  if not bufnr or bufnr < 0 then
    return false
  end

  local clock_line = build_capture_clock_line(headline, started_at, ended_at)
  if not clock_line then
    return false
  end

  local logbook = headline:get_logbook()

  if logbook then
    local insert_at = math.max(logbook.range.start_line, logbook.range.end_line - 1)
    vim.api.nvim_buf_set_lines(bufnr, insert_at, insert_at, false, { clock_line })
    return true
  end

  local indent = headline:get_indent()
  local append_line = headline:get_append_line()
  vim.api.nvim_buf_set_lines(bufnr, append_line, append_line, false, {
    string.format("%s:LOGBOOK:", indent),
    clock_line,
    string.format("%s:END:", indent),
  })
  return true
end

local function clock_in_snapshot(orgmode, snapshot)
  if not orgmode or not snapshot then
    return false
  end

  local ok, err = pcall(function()
    local target_file = orgmode.files:get(snapshot.file)
    local target_headline = nil
    target_file
      :update(function(file)
        local headline = file:reload_sync():get_closest_headline({ snapshot.line, 0 })
        if not headline then
          error("capture resume target not found")
        end

        headline:clock_in()
        target_headline = headline
      end)
      :wait(2000)

    orgmode.clock.clocked_headline = target_headline
  end)

  if not ok then
    vim.notify(("org_capture_norang: failed to resume previous clock (%s)"):format(tostring(err)), vim.log.levels.WARN)
    return false
  end

  return true
end

function M.begin_capture_clock_handoff()
  if M._state.active then
    return
  end

  local orgmode = get_orgmode()
  if not orgmode then
    return
  end

  local previous = snapshot_active_clock(orgmode)
  M._state.active = true
  M._state.previous = previous
  M._state.capture_started_at = os.time()
  M._state.clock_injected = false

  if previous then
    pause_active_clock(orgmode)
  end
end

function M.finish_capture_clock_handoff()
  if not M._state.active then
    return
  end

  local previous = M._state.previous
  M._state.active = false
  M._state.previous = nil
  M._state.capture_started_at = nil
  M._state.clock_injected = false

  if not previous then
    return
  end

  local orgmode = get_orgmode()
  if not orgmode then
    return
  end

  clock_in_snapshot(orgmode, previous)
end

function M.capture_prompt()
  local orgmode = get_orgmode()
  if not orgmode or not orgmode.capture then
    vim.notify("org_capture_norang: orgmode capture is unavailable", vim.log.levels.ERROR)
    return
  end

  local ok, err = pcall(function()
    orgmode.capture:prompt()
  end)
  if not ok then
    vim.notify(("org_capture_norang: failed to open capture prompt (%s)"):format(tostring(err)), vim.log.levels.ERROR)
  end
end

function M.setup()
  if M._installed then
    return
  end

  local orgmode = get_orgmode()
  if not orgmode or not orgmode.capture then
    return
  end

  local capture = orgmode.capture
  local previous_on_pre_refile = capture.on_pre_refile

  capture.on_pre_refile = function(self, opts)
    if type(previous_on_pre_refile) == "function" then
      pcall(previous_on_pre_refile, self, opts)
    end

    if not M._state.active or M._state.clock_injected then
      return
    end

    if not opts or not opts.source_headline then
      return
    end

    local ok, err = pcall(function()
      inject_capture_clock_line(opts.source_headline, M._state.capture_started_at, os.time())
      if opts.source_file and type(opts.source_file.reload_sync) == "function" then
        opts.source_file = opts.source_file:reload_sync()
      end
      if opts.source_file and opts.template and not opts.template.whole_file then
        opts.source_headline = opts.source_file:get_headlines()[1]
      end
      M._state.clock_injected = true
    end)

    if not ok then
      vim.notify(("org_capture_norang: failed to inject capture clock (%s)"):format(tostring(err)), vim.log.levels.WARN)
    end
  end

  local original_open_template = capture.open_template
  capture.open_template = function(self, template)
    M.begin_capture_clock_handoff()

    local ok, result = pcall(original_open_template, self, template)
    if not ok then
      M.finish_capture_clock_handoff()
      error(result)
    end

    return result
  end

  local previous_on_post_refile = capture.on_post_refile
  capture.on_post_refile = function(self, opts)
    if type(previous_on_post_refile) == "function" then
      pcall(previous_on_post_refile, self, opts)
    end
    M.finish_capture_clock_handoff()
  end

  local previous_on_cancel_refile = capture.on_cancel_refile
  capture.on_cancel_refile = function(self)
    if type(previous_on_cancel_refile) == "function" then
      pcall(previous_on_cancel_refile, self)
    end
    M.finish_capture_clock_handoff()
  end

  M._installed = true
end

return M
