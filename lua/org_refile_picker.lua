local Promise = require("orgmode.utils.promise")

local M = {}

local function safe_headlines(file)
  if type(file) ~= "table" or type(file.get_opened_unfinished_headlines) ~= "function" then
    return {}
  end

  local ok, headlines = pcall(file.get_opened_unfinished_headlines, file)
  if not ok or type(headlines) ~= "table" then
    return {}
  end

  return headlines
end

local function headline_title(headline)
  if type(headline) ~= "table" or type(headline.get_title) ~= "function" then
    return nil
  end

  local ok, title = pcall(headline.get_title, headline)
  if not ok or type(title) ~= "string" or vim.trim(title) == "" then
    return nil
  end

  return title
end

function M.build_items(destinations)
  local items = {}
  local paths = vim.tbl_keys(destinations or {})
  table.sort(paths)

  for _, path in ipairs(paths) do
    local file = destinations[path]
    table.insert(items, {
      kind = "file",
      label = path,
      file = file,
    })

    for _, headline in ipairs(safe_headlines(file)) do
      local title = headline_title(headline)
      if title then
        table.insert(items, {
          kind = "headline",
          label = ("%s%s"):format(path, title),
          file = file,
          headline = headline,
        })
      end
    end
  end

  return items
end

local function selected_destination(item)
  if not item then
    return false
  end

  return {
    file = item.file,
    headline = item.headline,
  }
end

function M.select(items)
  return Promise.new(function(resolve, _)
    vim.ui.select(items, {
      prompt = "Refile subtree to:",
      kind = "org_refile_destination",
      format_item = function(item)
        return item.label
      end,
    }, function(item)
      resolve(selected_destination(item))
    end)
  end)
end

function M.setup(capture)
  if type(capture) ~= "table" or type(capture.get_destination) ~= "function" then
    return false
  end

  if capture._org_refile_picker_original_get_destination then
    return true
  end

  capture._org_refile_picker_original_get_destination = capture.get_destination

  capture.get_destination = function(self)
    local original = self._org_refile_picker_original_get_destination
    local ok, destinations = pcall(self._get_autocompletion_files, self)
    if not ok or type(destinations) ~= "table" or type(vim.ui.select) ~= "function" then
      return original(self)
    end

    local items = M.build_items(destinations)
    if #items == 0 then
      return original(self)
    end

    local ok_select, promise = pcall(M.select, items)
    if not ok_select then
      return original(self)
    end

    return promise
  end

  return true
end

return M
