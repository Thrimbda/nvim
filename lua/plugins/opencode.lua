return {
  {
    "nickjvandyke/opencode.nvim",
    config = function()
      local opencode_cmd = "opencode --port"
      local terminal_opts = {
        win = {
          position = "right",
          width = 0.4,
          enter = false,
          on_win = function(win)
            require("opencode.terminal").setup(win.win)
          end,
        },
      }

      vim.g.opencode_opts = {
        server = {
          start = function()
            require("snacks.terminal").open(opencode_cmd, terminal_opts)
          end,
          stop = function()
            require("snacks.terminal").get(opencode_cmd, terminal_opts):close()
          end,
          toggle = function()
            require("snacks.terminal").toggle(opencode_cmd, terminal_opts)
          end,
        },
      }
    end,
  },
}
