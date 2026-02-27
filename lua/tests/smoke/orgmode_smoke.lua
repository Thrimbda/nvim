local M = {}

local DEFAULT_TODOS = { "TODO", "NEXT", "WAITING", "HOLD", "|", "DONE", "CANCELLED" }
local DEFAULT_ACTIVE = { "TODO", "NEXT", "WAITING", "HOLD" }
local DEFAULT_DONE = { "DONE", "CANCELLED" }
local DEFAULT_TASK_ID = "3CA66213-50ED-48B9-8E24-310B0959DA75"

local function assert_true(value, message)
  if not value then
    error(message, 0)
  end
end

local function write_temp_org(lines)
  local path = vim.fn.tempname() .. ".org"
  local ok, err = pcall(vim.fn.writefile, lines, path)
  assert_true(ok and err == 0, "failed to write temp org file: " .. tostring(path))
  return path
end

local function read_lines(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  assert_true(ok and type(lines) == "table", "failed to read file: " .. tostring(path))
  return lines
end

local function read_line(path, line_nr)
  local lines = read_lines(path)
  return lines[line_nr] or ""
end

local function setup_orgmode(paths)
  local orgmode = require("orgmode")
  local ok, err = pcall(orgmode.setup, {
    org_agenda_files = paths,
    org_default_notes_file = paths[1],
    org_todo_keywords = DEFAULT_TODOS,
    mappings = {
      disable_all = true,
    },
    notifications = {
      enabled = false,
      cron_enabled = false,
      reminder_time = false,
      repeater_reminder_time = false,
      deadline_warning_reminder_time = false,
    },
  })

  assert_true(ok, "orgmode setup failed: " .. tostring(err))
end

local function setup_punch(paths, organization_task_id)
  local punch = require("org_punch")
  punch.setup({
    org_agenda_files = paths,
    organization_task_id = organization_task_id,
    project_todo_keywords = DEFAULT_ACTIVE,
  })
  return punch
end

local function setup_norang(paths)
  local norang = require("org_norang")
  local ok, err = norang.setup({
    org_agenda_files = paths,
    refresh = {
      mode = "approx",
      on_buf_write = false,
      debounce_ms = 50,
      writeback = "memory_only",
      refresh_unloaded_files = true,
    },
    derived_tags = {
      project = "PROJECT",
      stuck = "STUCK",
      archive_candidate = "ARCHIVE_CANDIDATE",
    },
    todo = {
      active = DEFAULT_ACTIVE,
      done = DEFAULT_DONE,
      next = "NEXT",
    },
    archive = {
      stale_days = 30,
      recent_month_window = 2,
    },
    observability = {
      notify = false,
      log_level = "info",
    },
  })

  assert_true(ok == true, "org_norang setup failed: " .. tostring(err))
  return norang
end

local function test_punch_in_requires_id()
  local punch = require("org_punch")
  punch.setup({
    organization_task_id = "",
  })

  local old_notify = vim.notify
  vim.notify = function() end
  local ok = punch.punch_in()
  vim.notify = old_notify

  assert_true(ok == false, "punch_in should fail when organization_task_id is empty")
  assert_true(punch.state.keep_clock_running == false, "keep_clock_running should rollback to false on failure")
end

local function test_punch_in_clocks_default_task()
  local path = write_temp_org({
    "* Tasks",
    "** TODO Organization",
    "   :PROPERTIES:",
    "   :ID: " .. DEFAULT_TASK_ID,
    "   :END:",
  })

  setup_orgmode({ path })
  local punch = setup_punch({ path }, DEFAULT_TASK_ID)

  local ok = punch.punch_in()
  assert_true(ok == true, "punch_in should succeed")
  assert_true(punch.state.keep_clock_running == true, "keep_clock_running should be true after success")

  local lines = read_lines(path)
  local has_clock = false
  for _, line in ipairs(lines) do
    if line:match("^%s*CLOCK:%s*%[") then
      has_clock = true
      break
    end
  end
  assert_true(has_clock, "default task should have active CLOCK line after punch_in")

  punch.punch_out()
end

local function test_punch_in_preserves_current_buffer()
  local default_path = write_temp_org({
    "* Tasks",
    "** TODO Organization",
    "   :PROPERTIES:",
    "   :ID: " .. DEFAULT_TASK_ID,
    "   :END:",
  })
  local current_path = write_temp_org({
    "* TODO Current Task",
  })

  setup_orgmode({ current_path, default_path })
  local punch = setup_punch({ current_path, default_path }, DEFAULT_TASK_ID)

  vim.cmd("silent edit " .. vim.fn.fnameescape(current_path))
  local before = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p")
  assert_true(punch.punch_in() == true, "punch_in should succeed")
  local after = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p")
  assert_true(before == after, "punch_in should preserve current buffer")

  punch.punch_out()
end

local function test_punch_out_preserves_current_buffer()
  local default_path = write_temp_org({
    "* Tasks",
    "** TODO Organization",
    "   :PROPERTIES:",
    "   :ID: " .. DEFAULT_TASK_ID,
    "   :END:",
  })
  local current_path = write_temp_org({
    "* TODO Current Task",
  })

  setup_orgmode({ current_path, default_path })
  local punch = setup_punch({ current_path, default_path }, DEFAULT_TASK_ID)

  vim.cmd("silent edit " .. vim.fn.fnameescape(current_path))
  assert_true(punch.punch_in() == true, "punch_in should succeed")
  local before = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p")
  assert_true(punch.punch_out() == true, "punch_out should succeed")
  local after = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p")
  assert_true(before == after, "punch_out should preserve current buffer")
end

local function test_clock_in_todo_task_switches_to_next()
  local path = write_temp_org({
    "* TODO Project A",
    "** TODO Task 1",
  })

  setup_orgmode({ path })
  local punch = setup_punch({ path }, "")

  vim.cmd("silent edit " .. vim.fn.fnameescape(path))
  vim.api.nvim_win_set_cursor(0, { 2, 0 })

  local ok = punch.clock_in_current_task()
  assert_true(ok == true, "clock_in_current_task should succeed")
  assert_true(read_line(path, 2):match("^%*%*%s+NEXT%s+") ~= nil, "TODO task should switch to NEXT after clock in")

  punch.clock_out_current_task()
end

local function test_clock_in_next_project_switches_to_todo()
  local path = write_temp_org({
    "* NEXT Project B",
    "** TODO Child task",
  })

  setup_orgmode({ path })
  local punch = setup_punch({ path }, "")

  vim.cmd("silent edit " .. vim.fn.fnameescape(path))
  vim.api.nvim_win_set_cursor(0, { 1, 0 })

  local ok = punch.clock_in_current_task()
  assert_true(ok == true, "clock_in_current_task should succeed")
  assert_true(read_line(path, 1):match("^%*%s+TODO%s+") ~= nil, "NEXT project should switch back to TODO on clock in")

  punch.clock_out_current_task()
end

local function test_clock_out_removes_zero_duration_clock()
  local path = write_temp_org({
    "* TODO Quick task",
  })

  setup_orgmode({ path })
  local punch = setup_punch({ path }, "")

  vim.cmd("silent edit " .. vim.fn.fnameescape(path))
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  assert_true(punch.clock_in_current_task() == true, "clock_in_current_task should succeed")
  assert_true(punch.clock_out_current_task() == true, "clock_out_current_task should succeed")

  local lines = read_lines(path)
  for _, line in ipairs(lines) do
    assert_true(not line:match("CLOCK:.*=>%s*0:00%s*$"), "0:00 clock entry should be removed")
  end
end

local function test_clock_out_in_punch_mode_returns_to_default()
  local default_path = write_temp_org({
    "* Tasks",
    "** TODO Organization",
    "   :PROPERTIES:",
    "   :ID: " .. DEFAULT_TASK_ID,
    "   :END:",
  })
  local task_path = write_temp_org({
    "* TODO Focus task",
  })

  setup_orgmode({ task_path, default_path })
  local punch = setup_punch({ task_path, default_path }, DEFAULT_TASK_ID)
  local orgmode = require("orgmode")

  vim.cmd("silent edit " .. vim.fn.fnameescape(task_path))
  assert_true(punch.punch_in() == true, "punch_in should succeed")

  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  assert_true(punch.clock_in_current_task() == true, "clock_in_current_task should succeed")
  assert_true(punch.clock_out_current_task() == true, "clock_out_current_task should succeed in punch mode")

  orgmode.clock:update_clocked_headline()
  assert_true(orgmode.clock.clocked_headline ~= nil, "clock should continue running in punch mode")
  assert_true(orgmode.clock.clocked_headline:get_title() == "Organization", "clock should return to default task")

  punch.punch_out()
end

local function test_norang_refresh_marks_stuck_project()
  local path = write_temp_org({
    "* TODO Dist Systems",
    "** DONE Read paper",
  })

  setup_norang({ path })
  local norang = require("org_norang")
  local result = norang.refresh_file(path)

  assert_true(result.ok == true, "refresh_file should succeed")
  assert_true(read_line(path, 1):match(":PROJECT:STUCK:") ~= nil, "project should receive :PROJECT:STUCK: tags")
end

local function test_norang_cleanup_apply_removes_derived_tags()
  local path = write_temp_org({
    "* TODO Dist Systems :PROJECT:STUCK:ARCHIVE_CANDIDATE:",
  })

  setup_norang({ path })
  vim.cmd("silent edit " .. vim.fn.fnameescape(path))
  local norang = require("org_norang")
  local summary = norang.cleanup_derived_tags({ apply = true })

  assert_true(summary.changed_files >= 1, "cleanup apply should change at least one file")
  local line = vim.fn.getline(1)
  assert_true(line:match("PROJECT") == nil, "cleanup should remove PROJECT tag")
  assert_true(line:match("STUCK") == nil, "cleanup should remove STUCK tag")
  assert_true(line:match("ARCHIVE_CANDIDATE") == nil, "cleanup should remove ARCHIVE_CANDIDATE tag")
end

local function test_capture_clock_handoff_resumes_previous()
  local path = write_temp_org({
    "* TODO Focus task",
  })

  setup_orgmode({ path })
  local orgmode = require("orgmode")
  local capture = require("org_capture_norang")
  capture.setup()

  vim.cmd("silent edit " .. vim.fn.fnameescape(path))
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  orgmode.clock:org_clock_in():wait(2000)

  orgmode.clock:update_clocked_headline()
  assert_true(orgmode.clock.clocked_headline ~= nil, "precondition: clock should be active")
  assert_true(orgmode.clock.clocked_headline:get_title() == "Focus task", "precondition: active clock title mismatch")

  capture.begin_capture_clock_handoff()
  orgmode.clock:update_clocked_headline()
  assert_true(orgmode.clock.clocked_headline == nil, "capture handoff should pause current clock")

  capture.finish_capture_clock_handoff()
  orgmode.clock:update_clocked_headline()
  assert_true(orgmode.clock.clocked_headline ~= nil, "capture handoff should resume previous clock")
  assert_true(orgmode.clock.clocked_headline:get_title() == "Focus task", "resumed clock should return to original task")

  require("org_punch").clock_out_current_task({ ignore_keep_running = true, silent = true })

  local lines = read_lines(path)
  for _, line in ipairs(lines) do
    assert_true(not line:match("=>%s*0:00%s*$"), "capture handoff should not leave 0:00 clock entries")
  end
end

local function test_capture_pre_refile_injects_clock_line()
  local path = write_temp_org({
    "* TODO Captured task",
  })

  setup_orgmode({ path })
  local orgmode = require("orgmode")
  local capture = require("org_capture_norang")
  capture.setup()

  vim.cmd("silent edit " .. vim.fn.fnameescape(path))
  local source_file = orgmode.files:get_current_file()
  local source_headline = source_file:get_headlines()[1]
  assert_true(source_headline ~= nil, "precondition: source headline missing")

  capture.begin_capture_clock_handoff()
  capture._state.capture_started_at = os.time() - 61
  orgmode.capture.on_pre_refile(orgmode.capture, {
    source_file = source_file,
    source_headline = source_headline,
    template = { whole_file = false },
  })

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local has_logbook = false
  local has_clock = false
  for _, line in ipairs(lines) do
    if line:match("^%s*:LOGBOOK:%s*$") then
      has_logbook = true
    end
    if line:match("^%s*CLOCK:%s*%[") and line:match("=>%s*%d+:%d%d%s*$") and not line:match("=>%s*0:00%s*$") then
      has_clock = true
    end
  end
  assert_true(has_logbook, "capture pre-refile should inject LOGBOOK drawer")
  assert_true(has_clock, "capture pre-refile should inject CLOCK line")

  capture.finish_capture_clock_handoff()
end

local CASES = {
  punch_in_requires_id = test_punch_in_requires_id,
  punch_in_clocks_default_task = test_punch_in_clocks_default_task,
  punch_in_preserves_current_buffer = test_punch_in_preserves_current_buffer,
  punch_out_preserves_current_buffer = test_punch_out_preserves_current_buffer,
  clock_in_todo_task_switches_to_next = test_clock_in_todo_task_switches_to_next,
  clock_in_next_project_switches_to_todo = test_clock_in_next_project_switches_to_todo,
  clock_out_removes_zero_duration_clock = test_clock_out_removes_zero_duration_clock,
  clock_out_in_punch_mode_returns_to_default = test_clock_out_in_punch_mode_returns_to_default,
  norang_refresh_marks_stuck_project = test_norang_refresh_marks_stuck_project,
  norang_cleanup_apply_removes_derived_tags = test_norang_cleanup_apply_removes_derived_tags,
  capture_clock_handoff_resumes_previous = test_capture_clock_handoff_resumes_previous,
  capture_pre_refile_injects_clock_line = test_capture_pre_refile_injects_clock_line,
}

function M.run(case_name)
  local case_fn = CASES[case_name]
  assert_true(type(case_fn) == "function", "unknown smoke case: " .. tostring(case_name))

  local ok, err = pcall(case_fn)
  if not ok then
    vim.api.nvim_err_writeln("FAIL " .. case_name .. ": " .. tostring(err))
    vim.cmd("cquit 1")
    return
  end

  vim.api.nvim_out_write("PASS " .. case_name .. "\n")
end

function M.list_cases()
  local names = vim.tbl_keys(CASES)
  table.sort(names)
  return names
end

return M
