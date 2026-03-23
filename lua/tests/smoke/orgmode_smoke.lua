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

local function encode_json(payload)
  local ok_json, encoded = pcall(vim.json.encode, payload)
  if ok_json and type(encoded) == "string" then
    return encoded
  end

  local ok_fn, fallback = pcall(vim.fn.json_encode, payload)
  if ok_fn and type(fallback) == "string" then
    return fallback
  end

  return "{}"
end

local function build_parity_failure_message(assertion)
  local payload = {
    v = 1,
    id = tostring(assertion.id or "NP-UNKNOWN"),
    phase = tostring(assertion.phase or "unknown"),
    case = tostring(assertion.case_name or "unknown"),
    expected = tostring(assertion.expected or "(unspecified)"),
    actual = tostring(assertion.actual or "(nil)"),
  }

  if assertion.context ~= nil then
    payload.context = assertion.context
  end

  return "PARITY_FAIL " .. encode_json(payload)
end

local function assert_parity(condition, assertion)
  if condition then
    return
  end

  error(build_parity_failure_message(assertion), 0)
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

local function read_buffer_lines_for_file(path)
  local ok_org, orgmode = pcall(require, "orgmode")
  if not ok_org or not orgmode.files then
    return read_lines(path)
  end

  local ok_file, file = pcall(function()
    return orgmode.files:get(path):reload_sync()
  end)
  if not ok_file or not file then
    return read_lines(path)
  end

  local bufnr = file:bufnr()
  if bufnr > -1 and vim.api.nvim_buf_is_loaded(bufnr) then
    return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  end

  return read_lines(path)
end

local function read_line(path, line_nr)
  local lines = read_buffer_lines_for_file(path)
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

local function setup_legion(paths)
  local legion = require("org_legion")
  local ok, err = legion.setup({
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

  assert_true(ok == true, "org_legion setup failed: " .. tostring(err))
  return legion
end

local function setup_todo_triggers()
  local ok, err = require("org_legion.todo_triggers").setup()
  assert_true(ok == true, "todo trigger setup failed: " .. tostring(err))
end

local function run_org_action(action)
  local orgmode = require("orgmode")
  local ok_action, result = pcall(orgmode.action, action)
  assert_true(ok_action, "orgmode action failed: " .. tostring(action))
  if type(result) == "table" and type(result.wait) == "function" then
    result:wait(2000)
  end
end

local function get_current_headline_state(line_nr)
  local orgmode = require("orgmode")
  local headline = orgmode.files:get_closest_headline()
  local tags = headline:get_own_tags()
  return {
    line = vim.fn.getline(line_nr),
    tags = tags,
  }
end

local function apply_todo_trigger_now()
  local trigger = require("org_legion.todo_triggers")
  local orgmode = require("orgmode")
  trigger._state.listener({ headline = orgmode.files:get_closest_headline() })
end

local function has_tag_in_list(tags, tag)
  for _, item in ipairs(tags or {}) do
    if item == tag then
      return true
    end
  end
  return false
end

local function get_active_clock_title()
  local orgmode = require("orgmode")
  orgmode.clock:update_clocked_headline()
  if not orgmode.clock.clocked_headline then
    return nil
  end
  return orgmode.clock.clocked_headline:get_title()
end

local function has_active_clock_line(path)
  local lines = read_buffer_lines_for_file(path)
  for _, line in ipairs(lines) do
    if line:match("^%s*CLOCK:%s*%[") and not line:match("%]%-%-%[") then
      return true
    end
  end
  return false
end

local function assert_no_zero_duration_clock(path, label)
  local lines = read_buffer_lines_for_file(path)
  for _, line in ipairs(lines) do
    assert_true(not line:match("CLOCK:.*=>%s*0:00%s*$"), label .. " should not leave 0:00 clock entries")
  end
end

local function find_line_number(path, pattern)
  local lines = read_buffer_lines_for_file(path)
  for idx, line in ipairs(lines) do
    if line:match(pattern) then
      return idx
    end
  end
  return nil
end

local function get_subtree_lines(path, heading_line)
  local lines = read_buffer_lines_for_file(path)
  local heading = lines[heading_line] or ""
  local stars = heading:match("^(%*+)")
  if not stars then
    return {}
  end

  local level = #stars
  local last = #lines
  for idx = heading_line + 1, #lines do
    local cand = (lines[idx] or ""):match("^(%*+)")
    if cand and #cand <= level then
      last = idx - 1
      break
    end
  end

  local out = {}
  for idx = heading_line, last do
    table.insert(out, lines[idx])
  end
  return out
end

local function close_all_folds_for_test()
  vim.wo.foldenable = true
  vim.wo.foldlevel = 99
  vim.cmd("normal! zM")
end

local function capture_view_state(line_nr)
  return {
    buf = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p"),
    foldlevel = vim.wo.foldlevel,
    foldenable = vim.wo.foldenable,
    foldmethod = vim.wo.foldmethod,
    foldexpr = vim.wo.foldexpr,
    foldcolumn = vim.wo.foldcolumn,
    foldclosed = vim.fn.foldclosed(line_nr),
  }
end

local function assert_same_view_state(before, after, label)
  assert_true(before.buf == after.buf, label .. " should preserve current buffer")
  assert_true(before.foldlevel == after.foldlevel, label .. " should preserve foldlevel")
  assert_true(before.foldenable == after.foldenable, label .. " should preserve foldenable")
  assert_true(before.foldmethod == after.foldmethod, label .. " should preserve foldmethod")
  assert_true(before.foldexpr == after.foldexpr, label .. " should preserve foldexpr")
  assert_true(before.foldcolumn == after.foldcolumn, label .. " should preserve foldcolumn")
  assert_true(before.foldclosed == after.foldclosed, label .. " should preserve fold closed state")
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

  local lines = read_buffer_lines_for_file(path)
  local has_clock = false
  for _, line in ipairs(lines) do
    if line:match("^%s*CLOCK:%s*%[") then
      has_clock = true
      break
    end
  end
  assert_true(has_clock, "default task should have active CLOCK line after punch_in")
  assert_true(get_active_clock_title() == "Organization", "active clock should point at the default task after punch_in")

  punch.punch_out()
end

local function test_punch_in_prefers_current_buffer_when_id_is_duplicated()
  local other_path = write_temp_org({
    "* Tasks",
    "** Organization",
    "   :PROPERTIES:",
    "   :ID: " .. DEFAULT_TASK_ID,
    "   :END:",
  })
  local current_path = write_temp_org({
    "* Tasks",
    "** Organization",
    "   :PROPERTIES:",
    "   :ID: " .. DEFAULT_TASK_ID,
    "   :END:",
  })

  setup_orgmode({ other_path, current_path })
  local punch = setup_punch({ other_path, current_path }, DEFAULT_TASK_ID)

  vim.cmd("silent edit " .. vim.fn.fnameescape(current_path))

  assert_true(punch.punch_in() == true, "punch_in should succeed when duplicate IDs exist")
  assert_true(get_active_clock_title() == "Organization", "duplicate IDs should still produce an active clock")
  assert_true(has_active_clock_line(current_path), "current buffer should receive the active clock line")
  assert_true(not has_active_clock_line(other_path), "non-current duplicate should not receive the active clock line")

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
  close_all_folds_for_test()
  local before = capture_view_state(1)
  assert_true(punch.punch_in() == true, "punch_in should succeed")
  local after = capture_view_state(1)
  assert_same_view_state(before, after, "punch_in")

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
  close_all_folds_for_test()
  local before = capture_view_state(1)
  assert_true(punch.punch_out() == true, "punch_out should succeed")
  local after = capture_view_state(1)
  assert_same_view_state(before, after, "punch_out")
end

local function test_clock_out_preserves_view_state()
  local path = write_temp_org({
    "* TODO Focus project",
    "** TODO Nested task",
    "*** TODO Deep task",
  })

  setup_orgmode({ path })
  local punch = setup_punch({ path }, "")

  vim.cmd("silent edit " .. vim.fn.fnameescape(path))
  close_all_folds_for_test()
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  assert_true(punch.clock_in_current_task() == true, "clock_in_current_task should succeed")

  close_all_folds_for_test()
  local before = capture_view_state(2)
  assert_true(punch.clock_out_current_task({ ignore_keep_running = true, silent = true }) == true, "clock_out_current_task should succeed")
  local after = capture_view_state(2)

  assert_same_view_state(before, after, "clock_out_current_task")
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
  assert_true(vim.fn.getline(2):match("^%*%*%s+NEXT%s+") ~= nil, "TODO task should switch to NEXT after clock in")

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
  assert_true(vim.fn.getline(1):match("^%*%s+TODO%s+") ~= nil, "NEXT project should switch back to TODO on clock in")

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

  assert_no_zero_duration_clock(path, "clock_out_current_task")
end

local function test_clock_in_switch_removes_previous_zero_duration_clock()
  local path = write_temp_org({
    "* TODO First task",
    "* TODO Second task",
  })

  setup_orgmode({ path })
  local punch = setup_punch({ path }, "")

  vim.cmd("silent edit " .. vim.fn.fnameescape(path))
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  assert_true(punch.clock_in_current_task() == true, "first clock_in_current_task should succeed")

  local second_line = find_line_number(path, "^%* TODO Second task")
  assert_true(second_line ~= nil, "second task line should be found after first clock in")
  vim.api.nvim_win_set_cursor(0, { second_line, 0 })
  assert_true(punch.clock_in_current_task() == true, "second clock_in_current_task should succeed")
  assert_true(get_active_clock_title() == "Second task", "second task should become active clock")
  assert_no_zero_duration_clock(path, "clock_in_current_task switch")

  punch.clock_out_current_task()
end

local function test_punch_in_switch_removes_previous_zero_duration_clock()
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

  vim.cmd("silent edit " .. vim.fn.fnameescape(task_path))
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  assert_true(punch.clock_in_current_task() == true, "precondition clock_in_current_task should succeed")
  assert_true(punch.punch_in() == true, "punch_in should succeed while another task is active")
  assert_true(get_active_clock_title() == "Organization", "punch_in should switch active clock to Organization")
  assert_no_zero_duration_clock(task_path, "punch_in switch")

  punch.punch_out()
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

local function test_clock_out_in_punch_mode_returns_to_parent()
  local case_name = "clock_out_in_punch_mode_returns_to_parent"
  local default_path = write_temp_org({
    "* Tasks",
    "** TODO Organization",
    "   :PROPERTIES:",
    "   :ID: " .. DEFAULT_TASK_ID,
    "   :END:",
  })
  local task_path = write_temp_org({
    "* TODO Parent project",
    "** TODO Child task",
  })

  setup_orgmode({ task_path, default_path })
  local punch = setup_punch({ task_path, default_path }, DEFAULT_TASK_ID)

  vim.cmd("silent edit " .. vim.fn.fnameescape(task_path))
  assert_parity(punch.punch_in() == true, {
    id = "NP-002",
    phase = "punch",
    case_name = case_name,
    expected = "punch_in succeeds",
    actual = "punch_in failed",
  })

  assert_parity(punch.clock_out_current_task({ ignore_keep_running = true, silent = true }) == true, {
    id = "NP-015",
    phase = "clock",
    case_name = case_name,
    expected = "able to clear active default clock before focused clock in",
    actual = "clock_out_current_task(ignore_keep_running=true) failed",
  })

  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  assert_parity(punch.clock_in_current_task() == true, {
    id = "NP-003",
    phase = "clock",
    case_name = case_name,
    expected = "clock_in_current_task succeeds",
    actual = "clock_in_current_task failed",
  })
  assert_parity(get_active_clock_title() == "Child task", {
    id = "NP-015",
    phase = "clock",
    case_name = case_name,
    expected = "active clock title=Child task before clock_out fallback",
    actual = "active clock title=" .. tostring(get_active_clock_title()),
  })

  assert_parity(punch.clock_out_current_task() == true, {
    id = "NP-006A",
    phase = "clock",
    case_name = case_name,
    expected = "clock_out_current_task succeeds in punch mode",
    actual = "clock_out_current_task failed",
  })

  local parent_fallback_title = get_active_clock_title()
  assert_parity(parent_fallback_title == "Parent project", {
    id = "NP-006A",
    phase = "clock",
    case_name = case_name,
    expected = "active clock title=Parent project",
    actual = "active clock title=" .. tostring(parent_fallback_title),
  })

  assert_parity(punch.punch_out() == true, {
    id = "NP-005",
    phase = "teardown",
    case_name = case_name,
    expected = "punch_out succeeds",
    actual = "punch_out failed",
  })

end

local function test_clock_in_preserves_view_state()
  local default_path = write_temp_org({
    "* Tasks",
    "** TODO Organization",
    "   :PROPERTIES:",
    "   :ID: " .. DEFAULT_TASK_ID,
    "   :END:",
  })
  local task_path = write_temp_org({
    "* TODO Focus project",
    "** TODO Nested task",
    "*** TODO Deep task",
  })

  setup_orgmode({ task_path, default_path })
  local punch = setup_punch({ task_path, default_path }, DEFAULT_TASK_ID)

  vim.cmd("silent edit " .. vim.fn.fnameescape(task_path))
  close_all_folds_for_test()
  local before = capture_view_state(2)

  assert_true(punch.punch_in() == true, "punch_in should succeed")

  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  assert_true(punch.clock_in_current_task() == true, "clock_in_current_task should succeed")

  local after = capture_view_state(2)
  assert_same_view_state(before, after, "clock_in_current_task")

  punch.punch_out()
end

local function test_legion_refresh_marks_stuck_project()
  local path = write_temp_org({
    "* TODO Dist Systems",
    "** DONE Read paper",
  })

  setup_legion({ path })
  local legion = require("org_legion")
  local result = legion.refresh_file(path)

  assert_true(result.ok == true, "refresh_file should succeed")
  assert_true(read_line(path, 1):match(":PROJECT:STUCK:") ~= nil, "project should receive :PROJECT:STUCK: tags")
end

local function test_legion_cleanup_apply_removes_derived_tags()
  local path = write_temp_org({
    "* TODO Dist Systems :PROJECT:STUCK:ARCHIVE_CANDIDATE:",
  })

  setup_legion({ path })
  vim.cmd("silent edit " .. vim.fn.fnameescape(path))
  local legion = require("org_legion")
  local summary = legion.cleanup_derived_tags({ apply = true })

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
  local capture = require("org_capture_legion")
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

  local lines = read_buffer_lines_for_file(path)
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
  local capture = require("org_capture_legion")
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

local function test_todo_state_tag_triggers_legion()
  local path = write_temp_org({
    "* TODO Trigger task :WAITING:HOLD:CANCELLED:",
  })

  setup_orgmode({ path })
  setup_todo_triggers()
  vim.cmd("silent edit " .. vim.fn.fnameescape(path))
  vim.api.nvim_win_set_cursor(0, { 1, 0 })

  run_org_action("org_mappings.todo_next_state")
  apply_todo_trigger_now()
  local state = get_current_headline_state(1)
  assert_true(state.line:match("^%*%s+NEXT%s+") ~= nil, "todo should switch to NEXT")
  assert_true(not has_tag_in_list(state.tags, "WAITING"), "NEXT should remove WAITING tag")
  assert_true(not has_tag_in_list(state.tags, "HOLD"), "NEXT should remove HOLD tag")
  assert_true(not has_tag_in_list(state.tags, "CANCELLED"), "NEXT should remove CANCELLED tag")

  run_org_action("org_mappings.todo_next_state")
  apply_todo_trigger_now()
  state = get_current_headline_state(1)
  assert_true(has_tag_in_list(state.tags, "WAITING"), "WAITING should add WAITING tag")
  assert_true(not has_tag_in_list(state.tags, "HOLD"), "WAITING should not force HOLD tag")
  assert_true(not has_tag_in_list(state.tags, "CANCELLED"), "WAITING should clear CANCELLED by flow")

  run_org_action("org_mappings.todo_next_state")
  apply_todo_trigger_now()
  state = get_current_headline_state(1)
  assert_true(has_tag_in_list(state.tags, "WAITING"), "HOLD should keep WAITING tag")
  assert_true(has_tag_in_list(state.tags, "HOLD"), "HOLD should add HOLD tag")

  run_org_action("org_mappings.todo_next_state")
  apply_todo_trigger_now()
  state = get_current_headline_state(1)
  assert_true(not has_tag_in_list(state.tags, "WAITING"), "DONE should remove WAITING tag")
  assert_true(not has_tag_in_list(state.tags, "HOLD"), "DONE should remove HOLD tag")
  assert_true(not has_tag_in_list(state.tags, "CANCELLED"), "DONE should remove CANCELLED tag")

  run_org_action("org_mappings.todo_next_state")
  apply_todo_trigger_now()
  state = get_current_headline_state(1)
  assert_true(has_tag_in_list(state.tags, "CANCELLED"), "CANCELLED should add CANCELLED tag")
  assert_true(not has_tag_in_list(state.tags, "WAITING"), "CANCELLED should remove WAITING tag")
  assert_true(not has_tag_in_list(state.tags, "HOLD"), "CANCELLED should remove HOLD tag")

  require("orgmode").files:get_closest_headline():set_todo("TODO")
  apply_todo_trigger_now()
  state = get_current_headline_state(1)
  assert_true(state.line:match("^%*%s+TODO%s+") ~= nil, "todo should switch back to TODO")
  assert_true(not has_tag_in_list(state.tags, "WAITING"), "TODO should remove WAITING tag")
  assert_true(not has_tag_in_list(state.tags, "HOLD"), "TODO should remove HOLD tag")
  assert_true(not has_tag_in_list(state.tags, "CANCELLED"), "TODO should remove CANCELLED tag")
end

local function test_legion_e2e_integrated_flow()
  local case_name = "legion_e2e_integrated_flow"
  local default_path = write_temp_org({
    "* Tasks",
    "** TODO Organization",
    "   :PROPERTIES:",
    "   :ID: " .. DEFAULT_TASK_ID,
    "   :END:",
  })
  local workflow_path = write_temp_org({
    "* TODO Parent project",
    "** TODO Focus task",
    "* TODO Solo focus",
    "* TODO Capture candidate",
    "* TODO Trigger task :WAITING:HOLD:CANCELLED:",
    "* TODO Dist Systems",
    "** DONE Read paper",
    "* TODO Cleanup target :PROJECT:STUCK:ARCHIVE_CANDIDATE:USER_TAG:",
  })

  setup_orgmode({ workflow_path, default_path })
  local punch = setup_punch({ workflow_path, default_path }, DEFAULT_TASK_ID)
  local legion = setup_legion({ workflow_path })
  setup_todo_triggers()

  local orgmode = require("orgmode")
  local capture = require("org_capture_legion")
  capture.setup()

  vim.cmd("silent edit " .. vim.fn.fnameescape(workflow_path))

  assert_parity(punch.punch_in() == true, {
    id = "NP-002",
    phase = "punch",
    case_name = case_name,
    expected = "punch_in succeeds",
    actual = "punch_in failed",
  })
  assert_parity(punch.state.keep_clock_running == true, {
    id = "NP-002",
    phase = "punch",
    case_name = case_name,
    expected = "keep_clock_running=true",
    actual = "keep_clock_running=" .. tostring(punch.state.keep_clock_running),
  })
  assert_parity(get_active_clock_title() == "Organization", {
    id = "NP-002",
    phase = "punch",
    case_name = case_name,
    expected = "active clock title=Organization",
    actual = "active clock title=" .. tostring(get_active_clock_title()),
  })

  assert_parity(punch.clock_out_current_task({ ignore_keep_running = true, silent = true }) == true, {
    id = "NP-015",
    phase = "clock",
    case_name = case_name,
    expected = "able to clear active default clock before focused clock in",
    actual = "clock_out_current_task(ignore_keep_running=true) failed",
  })

  local focus_line = find_line_number(workflow_path, "^%*%*%s+TODO%s+Focus task")
  assert_parity(type(focus_line) == "number", {
    id = "NP-003",
    phase = "setup",
    case_name = case_name,
    expected = "Focus task headline exists",
    actual = "Focus task headline missing",
  })
  vim.api.nvim_win_set_cursor(0, { focus_line, 0 })
  assert_parity(punch.clock_in_current_task() == true, {
    id = "NP-003",
    phase = "clock",
    case_name = case_name,
    expected = "clock_in_current_task succeeds on Focus task",
    actual = "clock_in_current_task failed on Focus task",
  })
  assert_parity(vim.fn.getline(focus_line):match("^%*%*%s+NEXT%s+Focus task") ~= nil, {
    id = "NP-003",
    phase = "clock",
    case_name = case_name,
    expected = "Focus task TODO switches to NEXT",
    actual = "line=" .. vim.fn.getline(focus_line),
  })
  assert_parity(get_active_clock_title() == "Focus task", {
    id = "NP-015",
    phase = "clock",
    case_name = case_name,
    expected = "active clock title=Focus task",
    actual = "active clock title=" .. tostring(get_active_clock_title()),
  })

  assert_parity(punch.clock_out_current_task() == true, {
    id = "NP-006A",
    phase = "clock",
    case_name = case_name,
    expected = "clock_out_current_task succeeds with TODO parent",
    actual = "clock_out_current_task failed",
  })
  local integrated_parent_fallback_title = get_active_clock_title()
  assert_parity(integrated_parent_fallback_title == "Parent project", {
    id = "NP-006A",
    phase = "clock",
    case_name = case_name,
    expected = "active clock title=Parent project",
    actual = "active clock title=" .. tostring(integrated_parent_fallback_title),
  })

  assert_parity(punch.clock_out_current_task({ ignore_keep_running = true, silent = true }) == true, {
    id = "NP-015",
    phase = "clock",
    case_name = case_name,
    expected = "able to clear parent clock before default-fallback branch",
    actual = "clock_out_current_task(ignore_keep_running=true) failed",
  })

  local solo_line = find_line_number(workflow_path, "^%*%s+TODO%s+Solo focus")
  assert_parity(type(solo_line) == "number", {
    id = "NP-006B",
    phase = "setup",
    case_name = case_name,
    expected = "Solo focus headline exists",
    actual = "Solo focus headline missing",
  })
  vim.api.nvim_win_set_cursor(0, { solo_line, 0 })
  assert_parity(punch.clock_in_current_task() == true, {
    id = "NP-003",
    phase = "clock",
    case_name = case_name,
    expected = "clock_in_current_task succeeds on Solo focus",
    actual = "clock_in_current_task failed on Solo focus",
  })
  assert_parity(vim.fn.getline(solo_line):match("^%*%s+NEXT%s+Solo focus") ~= nil, {
    id = "NP-003",
    phase = "clock",
    case_name = case_name,
    expected = "Solo focus TODO switches to NEXT",
    actual = "line=" .. vim.fn.getline(solo_line),
  })
  assert_parity(punch.clock_out_current_task() == true, {
    id = "NP-006B",
    phase = "clock",
    case_name = case_name,
    expected = "clock_out_current_task succeeds with no TODO parent",
    actual = "clock_out_current_task failed",
  })
  assert_parity(get_active_clock_title() == "Organization", {
    id = "NP-006B",
    phase = "clock",
    case_name = case_name,
    expected = "active clock title=Organization",
    actual = "active clock title=" .. tostring(get_active_clock_title()),
  })

  local capture_line = find_line_number(workflow_path, "^%*%s+TODO%s+Capture candidate")
  assert_parity(type(capture_line) == "number", {
    id = "NP-008",
    phase = "setup",
    case_name = case_name,
    expected = "Capture candidate headline exists",
    actual = "Capture candidate headline missing",
  })
  vim.api.nvim_win_set_cursor(0, { capture_line, 0 })
  assert_parity(punch.clock_out_current_task({ ignore_keep_running = true, silent = true }) == true, {
    id = "NP-015",
    phase = "capture",
    case_name = case_name,
    expected = "able to clear active clock before capture handoff",
    actual = "clock_out_current_task(ignore_keep_running=true) failed",
  })
  orgmode.clock:org_clock_in():wait(2000)
  assert_parity(get_active_clock_title() == "Capture candidate", {
    id = "NP-015",
    phase = "capture",
    case_name = case_name,
    expected = "active clock title=Capture candidate before handoff",
    actual = "active clock title=" .. tostring(get_active_clock_title()),
  })

  local source_file = orgmode.files:get_current_file()
  local source_headline = source_file:get_closest_headline({ capture_line, 0 })
  assert_parity(source_headline ~= nil, {
    id = "NP-008",
    phase = "setup",
    case_name = case_name,
    expected = "source headline resolves for capture",
    actual = "source headline=nil",
  })
  local source_line = source_headline:get_range().start_line
  assert_parity(type(source_line) == "number", {
    id = "NP-008",
    phase = "setup",
    case_name = case_name,
    expected = "source headline has valid start line",
    actual = "source line=" .. tostring(source_line),
  })

  capture.begin_capture_clock_handoff()
  assert_parity(get_active_clock_title() == nil, {
    id = "NP-007",
    phase = "capture",
    case_name = case_name,
    expected = "active clock pauses during capture",
    actual = "active clock title=" .. tostring(get_active_clock_title()),
  })

  capture._state.capture_started_at = os.time() - 61
  orgmode.capture.on_pre_refile(orgmode.capture, {
    source_file = source_file,
    source_headline = source_headline,
    template = { whole_file = false },
  })

  local capture_lines = get_subtree_lines(workflow_path, source_line)
  local has_logbook = false
  local has_non_zero_clock = false
  for _, line in ipairs(capture_lines) do
    if line:match("^%s*:LOGBOOK:%s*$") then
      has_logbook = true
    end
    if line:match("^%s*CLOCK:%s*%[") and line:match("=>%s*%d+:%d%d%s*$") and not line:match("=>%s*0:00%s*$") then
      has_non_zero_clock = true
    end
  end
  assert_parity(has_logbook, {
    id = "NP-008",
    phase = "capture",
    case_name = case_name,
    expected = "capture pre-refile injects LOGBOOK",
    actual = "LOGBOOK not found",
  })
  assert_parity(has_non_zero_clock, {
    id = "NP-008",
    phase = "capture",
    case_name = case_name,
    expected = "capture pre-refile injects non-zero CLOCK",
    actual = "non-zero CLOCK not found",
  })

  capture.finish_capture_clock_handoff()
  assert_parity(get_active_clock_title() == "Capture candidate", {
    id = "NP-007",
    phase = "capture",
    case_name = case_name,
    expected = "previous clock resumes after capture",
    actual = "active clock title=" .. tostring(get_active_clock_title()),
  })

  local trigger_line = find_line_number(workflow_path, "^%*%s+TODO%s+Trigger task")
  assert_parity(type(trigger_line) == "number", {
    id = "NP-009",
    phase = "setup",
    case_name = case_name,
    expected = "Trigger task headline exists",
    actual = "Trigger task headline missing",
  })
  vim.api.nvim_win_set_cursor(0, { trigger_line, 0 })

  local trigger_headline = orgmode.files:get_closest_headline()
  trigger_headline:set_todo("WAITING")
  apply_todo_trigger_now()
  local state = get_current_headline_state(trigger_line)
  assert_parity(has_tag_in_list(state.tags, "WAITING"), {
    id = "NP-009",
    phase = "tags",
    case_name = case_name,
    expected = "WAITING state adds WAITING tag",
    actual = "tags=" .. table.concat(state.tags or {}, ","),
  })

  trigger_headline = orgmode.files:get_closest_headline()
  trigger_headline:set_todo("HOLD")
  apply_todo_trigger_now()
  state = get_current_headline_state(trigger_line)
  assert_parity(has_tag_in_list(state.tags, "WAITING") and has_tag_in_list(state.tags, "HOLD"), {
    id = "NP-009",
    phase = "tags",
    case_name = case_name,
    expected = "HOLD adds WAITING and HOLD tags",
    actual = "tags=" .. table.concat(state.tags or {}, ","),
  })

  trigger_headline = orgmode.files:get_closest_headline()
  trigger_headline:set_todo("CANCELLED")
  apply_todo_trigger_now()
  state = get_current_headline_state(trigger_line)
  assert_parity(has_tag_in_list(state.tags, "CANCELLED") and not has_tag_in_list(state.tags, "WAITING") and not has_tag_in_list(state.tags, "HOLD"), {
    id = "NP-009",
    phase = "tags",
    case_name = case_name,
    expected = "CANCELLED keeps only CANCELLED from trigger set",
    actual = "tags=" .. table.concat(state.tags or {}, ","),
  })

  trigger_headline = orgmode.files:get_closest_headline()
  trigger_headline:set_todo("NEXT")
  apply_todo_trigger_now()
  state = get_current_headline_state(trigger_line)
  assert_parity(not has_tag_in_list(state.tags, "WAITING") and not has_tag_in_list(state.tags, "HOLD") and not has_tag_in_list(state.tags, "CANCELLED"), {
    id = "NP-010",
    phase = "tags",
    case_name = case_name,
    expected = "NEXT clears WAITING/HOLD/CANCELLED",
    actual = "tags=" .. table.concat(state.tags or {}, ","),
  })

  trigger_headline = orgmode.files:get_closest_headline()
  trigger_headline:set_todo("DONE")
  apply_todo_trigger_now()
  state = get_current_headline_state(trigger_line)
  assert_parity(not has_tag_in_list(state.tags, "WAITING") and not has_tag_in_list(state.tags, "HOLD") and not has_tag_in_list(state.tags, "CANCELLED"), {
    id = "NP-010",
    phase = "tags",
    case_name = case_name,
    expected = "DONE clears WAITING/HOLD/CANCELLED",
    actual = "tags=" .. table.concat(state.tags or {}, ","),
  })

  trigger_headline = orgmode.files:get_closest_headline()
  trigger_headline:set_todo("TODO")
  apply_todo_trigger_now()
  state = get_current_headline_state(trigger_line)
  assert_parity(not has_tag_in_list(state.tags, "WAITING") and not has_tag_in_list(state.tags, "HOLD") and not has_tag_in_list(state.tags, "CANCELLED"), {
    id = "NP-010",
    phase = "tags",
    case_name = case_name,
    expected = "TODO clears WAITING/HOLD/CANCELLED",
    actual = "tags=" .. table.concat(state.tags or {}, ","),
  })

  local refresh_result = legion.refresh_file(workflow_path)
  assert_parity(refresh_result.ok == true, {
    id = "NP-011",
    phase = "refresh",
    case_name = case_name,
    expected = "legion refresh_file succeeds",
    actual = "refresh ok=" .. tostring(refresh_result.ok),
  })
  local dist_line = find_line_number(workflow_path, "^%*%s+TODO%s+Dist Systems")
  assert_parity(type(dist_line) == "number", {
    id = "NP-011",
    phase = "refresh",
    case_name = case_name,
    expected = "Dist Systems headline exists",
    actual = "Dist Systems headline missing",
  })
  assert_parity((read_line(workflow_path, dist_line) or ""):match(":PROJECT:STUCK:") ~= nil, {
    id = "NP-011",
    phase = "refresh",
    case_name = case_name,
    expected = "Dist Systems marked with PROJECT:STUCK",
    actual = "line=" .. tostring(read_line(workflow_path, dist_line)),
  })

  local cleanup_result = legion.cleanup_derived_tags({ apply = true })
  assert_parity(cleanup_result.changed_files >= 1, {
    id = "NP-012",
    phase = "cleanup",
    case_name = case_name,
    expected = "cleanup apply changes at least one file",
    actual = "changed_files=" .. tostring(cleanup_result.changed_files),
  })
  local cleanup_line_nr = find_line_number(workflow_path, "^%*%s+TODO%s+Cleanup target")
  local cleanup_line = cleanup_line_nr and read_line(workflow_path, cleanup_line_nr) or ""
  assert_parity(cleanup_line:match("PROJECT") == nil and cleanup_line:match("STUCK") == nil and cleanup_line:match("ARCHIVE_CANDIDATE") == nil, {
    id = "NP-012",
    phase = "cleanup",
    case_name = case_name,
    expected = "cleanup removes PROJECT/STUCK/ARCHIVE_CANDIDATE",
    actual = "line=" .. cleanup_line,
  })
  assert_parity(cleanup_line:match("USER_TAG") ~= nil, {
    id = "NP-012",
    phase = "cleanup",
    case_name = case_name,
    expected = "cleanup preserves user tags",
    actual = "line=" .. cleanup_line,
  })

  assert_parity(punch.punch_out() == true, {
    id = "NP-015",
    phase = "teardown",
    case_name = case_name,
    expected = "punch_out succeeds",
    actual = "punch_out failed",
  })
  assert_parity(get_active_clock_title() == nil, {
    id = "NP-015",
    phase = "teardown",
    case_name = case_name,
    expected = "no active clock after punch_out",
    actual = "active clock title=" .. tostring(get_active_clock_title()),
  })
end

local CASES = {
  punch_in_requires_id = test_punch_in_requires_id,
  punch_in_clocks_default_task = test_punch_in_clocks_default_task,
  punch_in_prefers_current_buffer_when_id_is_duplicated = test_punch_in_prefers_current_buffer_when_id_is_duplicated,
  punch_in_preserves_current_buffer = test_punch_in_preserves_current_buffer,
  punch_out_preserves_current_buffer = test_punch_out_preserves_current_buffer,
  clock_out_preserves_view_state = test_clock_out_preserves_view_state,
  clock_in_todo_task_switches_to_next = test_clock_in_todo_task_switches_to_next,
  clock_in_next_project_switches_to_todo = test_clock_in_next_project_switches_to_todo,
  clock_in_switch_removes_previous_zero_duration_clock = test_clock_in_switch_removes_previous_zero_duration_clock,
  clock_in_preserves_view_state = test_clock_in_preserves_view_state,
  clock_out_removes_zero_duration_clock = test_clock_out_removes_zero_duration_clock,
  punch_in_switch_removes_previous_zero_duration_clock = test_punch_in_switch_removes_previous_zero_duration_clock,
  clock_out_in_punch_mode_returns_to_parent = test_clock_out_in_punch_mode_returns_to_parent,
  clock_out_in_punch_mode_returns_to_default = test_clock_out_in_punch_mode_returns_to_default,
  legion_refresh_marks_stuck_project = test_legion_refresh_marks_stuck_project,
  legion_cleanup_apply_removes_derived_tags = test_legion_cleanup_apply_removes_derived_tags,
  capture_clock_handoff_resumes_previous = test_capture_clock_handoff_resumes_previous,
  capture_pre_refile_injects_clock_line = test_capture_pre_refile_injects_clock_line,
  todo_state_tag_triggers_legion = test_todo_state_tag_triggers_legion,
  legion_e2e_integrated_flow = test_legion_e2e_integrated_flow,
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
