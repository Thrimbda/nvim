return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.picker = opts.picker or {}
      opts.picker.sources = opts.picker.sources or {}
      opts.picker.sources.explorer = vim.tbl_deep_extend("force", opts.picker.sources.explorer or {}, {
        hidden = true, -- show dotfiles by default
        ignored = true, -- optional: also show gitignored files
        win = {
          input = { wo = { winfixwidth = true } },
          list = { wo = { winfixwidth = true } },
        },
      })
      opts.picker.sources.files = vim.tbl_deep_extend("force", opts.picker.sources.files or {}, {
        hidden = true, -- show dotfiles in <leader>ff
      })
    end,
  },
}
