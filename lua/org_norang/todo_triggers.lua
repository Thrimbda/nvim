local M = {}
local org_utils = require("orgmode.utils")

M._state = {
  installed = false,
  listener = nil,
}

local function apply_tag_delta(headline, tags_to_add, tags_to_remove)
  local own_tags = headline:get_own_tags()
  local keep = {}
  for _, tag in ipairs(own_tags or {}) do
    keep[tag] = true
  end

  for _, tag in ipairs(tags_to_remove or {}) do
    keep[tag] = nil
  end
  for _, tag in ipairs(tags_to_add or {}) do
    keep[tag] = true
  end

  local next_tags = {}
  for _, tag in ipairs(own_tags or {}) do
    if keep[tag] then
      table.insert(next_tags, tag)
      keep[tag] = nil
    end
  end
  for _, tag in ipairs(tags_to_add or {}) do
    if keep[tag] then
      table.insert(next_tags, tag)
      keep[tag] = nil
    end
  end

  local bufnr = headline.file:get_valid_bufnr()
  local row = headline:node():start()
  local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
  local base = line:gsub("%s+:[%w_@#%%:]+:%s*$", "")
  local tags = org_utils.tags_to_string(next_tags)
  local next_line = tags == "" and base or (base .. " " .. tags)
  vim.api.nvim_buf_set_lines(bufnr, row, row + 1, false, { next_line })
  headline:refresh()
end

local function apply_norang_trigger(headline, todo)
  if todo == "WAITING" then
    apply_tag_delta(headline, { "WAITING" }, nil)
    return
  end

  if todo == "HOLD" then
    apply_tag_delta(headline, { "WAITING", "HOLD" }, nil)
    return
  end

  if todo == "CANCELLED" then
    apply_tag_delta(headline, { "CANCELLED" }, { "WAITING", "HOLD" })
    return
  end

  if todo == "TODO" or todo == "NEXT" or todo == "DONE" then
    apply_tag_delta(headline, nil, { "WAITING", "HOLD", "CANCELLED" })
  end
end

function M.setup()
  if M._state.installed then
    return true
  end

  local ok_event_manager, event_manager = pcall(require, "orgmode.events")
  local ok_events, events = pcall(require, "orgmode.events.types")
  if not ok_event_manager or not ok_events then
    return false, "orgmode events unavailable"
  end

  M._state.listener = function(event)
    local headline = event and event.headline
    if not headline then
      return
    end

    local todo = headline:get_todo()
    if type(todo) ~= "string" or todo == "" then
      return
    end

    apply_norang_trigger(headline, todo:upper())
    headline:align_tags()
  end

  event_manager.listen(events.TodoChanged, M._state.listener)
  M._state.installed = true
  return true
end

return M
