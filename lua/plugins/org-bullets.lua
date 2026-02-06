return {
  {
    "nvim-orgmode/org-bullets.nvim",
    ft = { "org" },
    dependencies = { "nvim-orgmode/orgmode" },
    config = function()
      require("org-bullets").setup()
    end,
  },
}
