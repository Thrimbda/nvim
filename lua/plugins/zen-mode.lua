return {
  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    opts = {
      window = {
        width = 88,
        options = {
          number = false,
          relativenumber = false,
          signcolumn = "no",
          foldcolumn = "0",
          colorcolumn = "",
        },
      },
      plugins = {
        options = {
          enabled = true,
          ruler = false,
          showcmd = false,
        },
      },
    },
  },
}
