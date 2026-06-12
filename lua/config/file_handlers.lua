local tabiew_parquet_group = vim.api.nvim_create_augroup("cone_open_parquet_with_tabiew", { clear = true })

vim.api.nvim_create_autocmd("BufReadCmd", {
  group = tabiew_parquet_group,
  pattern = { "*.parquet", "*.pqt", "*.parq" },
  desc = "Open Parquet files with Tabiew",
  callback = function(args)
    local bufnr = args.buf
    local path = args.file

    if not path or path == "" then
      path = args.match
    end

    local file = vim.fn.fnamemodify(path, ":p")

    vim.bo[bufnr].bufhidden = "wipe"
    vim.bo[bufnr].swapfile = false

    if vim.fn.executable("tw") == 0 then
      vim.bo[bufnr].buftype = "nofile"
      vim.bo[bufnr].modifiable = true
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
        "Tabiew executable `tw` not found.",
        "",
        "Install it first:",
        "  macOS: brew install tabiew",
        "  Rust:  cargo install --locked tabiew",
      })
      vim.bo[bufnr].modifiable = false
      vim.bo[bufnr].modified = false
      return
    end

    vim.fn.termopen({ "tw", file }, {
      on_exit = function()
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(bufnr) then
            pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
          end
        end)
      end,
    })

    vim.cmd("startinsert")
  end,
})
