return {
  {
    "nvim-orgmode/orgmode",
    event = "VeryLazy",
    ft = { "org" },
    config = function()
      local org_agenda_files = "~/OneDrive/cone/**/*"
      local org_default_notes_file = "~/OneDrive/cone/refile.org"
      local organization_task_id = vim.g.org_organization_task_id or ""

      require("orgmode").setup({
        org_agenda_files = org_agenda_files,
        org_default_notes_file = org_default_notes_file,
        org_todo_keywords = {
          "TODO(t)",
          "NEXT(n)",
          "WAITING(w)",
          "HOLD(h)",
          "|",
          "DONE(d)",
          "CANCELLED(c)",
        },
        org_log_into_drawer = "LOGBOOK",
        org_log_done = "note",
        org_agenda_custom_commands = {
          b = {
            description = "Block agenda (Norang-style)",
            types = {
              {
                type = "tags_todo",
                match = "REFILE",
                org_agenda_overriding_header = "Refile",
                org_agenda_todo_ignore_scheduled = "all",
                org_agenda_todo_ignore_deadlines = "all",
              },
              {
                type = "agenda",
                org_agenda_overriding_header = "Today",
                org_agenda_span = "day",
              },
              {
                type = "tags_todo",
                match = '+TODO="NEXT"',
                org_agenda_overriding_header = "Next actions",
                org_agenda_sorting_strategy = { "priority-down", "todo-state-up" },
              },
              {
                type = "tags_todo",
                match = '+TODO="WAITING"',
                org_agenda_overriding_header = "Waiting",
              },
              {
                type = "tags_todo",
                match = '+TODO="HOLD"',
                org_agenda_overriding_header = "Hold",
              },
            },
          },
          n = {
            description = "NEXT list",
            types = {
              {
                type = "tags_todo",
                match = '+TODO="NEXT"',
                org_agenda_overriding_header = "Next actions",
              },
            },
          },
          r = {
            description = "REFILE inbox",
            types = {
              {
                type = "tags_todo",
                match = "REFILE",
                org_agenda_overriding_header = "Refile",
              },
            },
          },
        },
      })

      require("org_punch").setup({
        org_agenda_files = org_agenda_files,
        organization_task_id = organization_task_id,
        project_todo_keywords = { "TODO", "NEXT", "WAITING", "HOLD" },
      })

      local punch = require("org_punch")
      vim.keymap.set("n", "<F9>i", punch.punch_in, { desc = "Org Punch In" })
      vim.keymap.set("n", "<F9>o", punch.punch_out, { desc = "Org Punch Out" })
      vim.keymap.set("n", "<F9>O", punch.clock_out_keep_running, { desc = "Clock out (keep running)" })

      vim.keymap.set("n", "<F12>", "<Cmd>Org agenda b<CR>", { desc = "Org Block Agenda" })
      vim.keymap.set("n", "<Leader>oab", "<Cmd>Org agenda b<CR>", { desc = "Org Block Agenda" })
      vim.keymap.set("n", "<Leader>oan", "<Cmd>Org agenda n<CR>", { desc = "Org NEXT" })
      vim.keymap.set("n", "<Leader>oar", "<Cmd>Org agenda r<CR>", { desc = "Org Refile" })
    end,
  },
}
