return {
  {
    "nvim-orgmode/orgmode",
    event = "VeryLazy",
    ft = { "org" },
    config = function()
      -- Setup orgmode
      require("orgmode").setup({
        org_agenda_files = "~/OneDrive/cone/**/*",
        org_default_notes_file = "~/OneDrive/cone/refile.org",
      })
    end,
  },
}
