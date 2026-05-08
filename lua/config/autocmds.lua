-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local prose_wrap_group = vim.api.nvim_create_augroup("cone_prose_soft_wrap", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = prose_wrap_group,
  pattern = { "org", "markdown" },
  callback = function(args)
    local filetype = vim.api.nvim_get_option_value("filetype", { buf = args.buf })
    local label = filetype == "markdown" and "Markdown" or "Org"

    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
    vim.opt_local.showbreak = "-> "
    vim.opt_local.textwidth = 0
    vim.opt_local.colorcolumn = "88"
    vim.opt_local.formatoptions:remove({ "t", "a" })

    vim.keymap.set("n", "<leader>oz", "<Cmd>ZenMode<CR>", {
      buffer = args.buf,
      desc = ("%s Zen (88 cols)"):format(label),
      silent = true,
    })
  end,
})
