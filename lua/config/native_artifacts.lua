local M = {}

local function should_sign()
  return vim.fn.has("macunix") == 1 and vim.fn.executable("codesign") == 1
end

function M.sign_patterns(patterns)
  if not should_sign() then
    return
  end

  local files = {}
  for _, pattern in ipairs(patterns) do
    for _, path in ipairs(vim.fn.glob(pattern, true, true)) do
      if vim.fn.filereadable(path) == 1 then
        table.insert(files, path)
      end
    end
  end

  if #files == 0 then
    return
  end

  local cmd = { "codesign", "--force", "--sign", "-" }
  vim.list_extend(cmd, files)
  local output = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify(("native artifact signing failed: %s"):format(output), vim.log.levels.WARN)
  end
end

function M.sign_nvim_artifacts()
  local data = vim.fn.stdpath("data")
  M.sign_patterns({
    data .. "/site/parser/*.so",
    data .. "/lazy/orgmode/parser/org.so",
    data .. "/lazy/blink.cmp/target/release/libblink_cmp_fuzzy.dylib",
  })
end

return M
