local virtual_tags = require("org_legion.virtual_tags")

local M = {}

function M.is_agenda_file(cfg, path_or_bufnr)
  return virtual_tags.is_agenda_file(cfg, path_or_bufnr)
end

function M.refresh_file(cfg, path_or_bufnr)
  return virtual_tags.refresh_file(cfg, path_or_bufnr)
end

function M.refresh_all(cfg)
  return virtual_tags.refresh_all(cfg)
end

return M
