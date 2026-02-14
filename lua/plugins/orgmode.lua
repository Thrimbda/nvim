return {
  {
    "nvim-orgmode/orgmode",
    event = "VeryLazy",
    ft = { "org" },
    config = function()
      local org_agenda_files = "~/OneDrive/cone/**/*.org"
      local org_default_notes_file = "~/OneDrive/cone/refile.org"
      local organization_task_id = vim.g.org_organization_task_id or ""
      require("orgmode").setup({
        org_agenda_files = org_agenda_files,
        org_default_notes_file = org_default_notes_file,
        org_startup_indented = true,
        org_agenda_use_time_grid = true,
        org_agenda_time_grid = {
          type = { "daily" },
          times = { 800, 1000, 1200, 1400, 1600, 1800, 2000 },
          time_separator = "┄┄┄┄┄",
          time_label = "┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄",
        },
        org_agenda_current_time_string = "<- now -----------------------------------------------",
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
              {
                type = "tags_todo",
                match = "PROJECT+STUCK",
                org_agenda_overriding_header = "Stuck Projects",
              },
              {
                type = "tags_todo",
                match = "PROJECT-STUCK",
                org_agenda_overriding_header = "Projects",
              },
              {
                type = "tags_todo",
                match = '+TODO="TODO"-PROJECT-REFILE',
                org_agenda_overriding_header = "Standalone Tasks",
              },
              {
                type = "tags",
                match = "ARCHIVE_CANDIDATE",
                org_agenda_overriding_header = "Archive Candidates",
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
          t = {
            description = "Timeline (day)",
            types = {
              {
                type = "agenda",
                org_agenda_overriding_header = "Timeline",
                org_agenda_span = "day",
              },
            },
          },
          s = {
            description = "Stuck projects",
            types = {
              {
                type = "tags_todo",
                match = "PROJECT+STUCK",
                org_agenda_overriding_header = "Stuck Projects",
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

      local agenda_right_group = vim.api.nvim_create_augroup("OrgAgendaRightSide", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = agenda_right_group,
        pattern = "orgagenda",
        callback = function()
          local agenda_win = vim.api.nvim_get_current_win()
          vim.schedule(function()
            if not vim.api.nvim_win_is_valid(agenda_win) then
              return
            end
            local buf = vim.api.nvim_win_get_buf(agenda_win)
            if vim.api.nvim_get_option_value("filetype", { buf = buf }) ~= "orgagenda" then
              return
            end
            local current_win = vim.api.nvim_get_current_win()
            vim.api.nvim_set_current_win(agenda_win)
            pcall(vim.cmd, "wincmd L")
            if vim.api.nvim_win_is_valid(current_win) then
              vim.api.nvim_set_current_win(current_win)
            end
          end)
        end,
      })

      require("org_punch").setup({
        org_agenda_files = org_agenda_files,
        organization_task_id = organization_task_id,
        project_todo_keywords = { "TODO", "NEXT", "WAITING", "HOLD" },
      })

      require("org_norang").setup({
        org_agenda_files = org_agenda_files,
        refresh = {
          mode = "approx",
          on_buf_write = true,
          debounce_ms = 120,
          writeback = "memory_only",
          refresh_unloaded_files = true,
        },
        derived_tags = {
          project = "PROJECT",
          stuck = "STUCK",
          archive_candidate = "ARCHIVE_CANDIDATE",
        },
        todo = {
          active = { "TODO", "NEXT", "WAITING", "HOLD" },
          done = { "DONE", "CANCELLED" },
          next = "NEXT",
        },
        archive = {
          stale_days = 30,
          recent_month_window = 2,
        },
      })

      local punch = require("org_punch")
      vim.keymap.set("n", "<Leader>opI", punch.punch_in, { desc = "Org Punch In" })
      vim.keymap.set("n", "<Leader>opO", punch.punch_out, { desc = "Org Punch Out" })
      vim.keymap.set("n", "<Leader>opo", punch.clock_out_keep_running, { desc = "Clock out (keep running)" })

      vim.keymap.set("n", "<F12>", "<Cmd>Org agenda b<CR>", { desc = "Org Block Agenda" })
      vim.keymap.set("n", "<Leader>oab", "<Cmd>Org agenda b<CR>", { desc = "Org Block Agenda" })
      vim.keymap.set("n", "<Leader>oan", "<Cmd>Org agenda n<CR>", { desc = "Org NEXT" })
      vim.keymap.set("n", "<Leader>oat", "<Cmd>Org agenda t<CR>", { desc = "Org Timeline" })
      vim.keymap.set("n", "<Leader>oas", "<Cmd>Org agenda s<CR>", { desc = "Org Stuck Projects" })
      vim.keymap.set("n", "<Leader>oar", "<Cmd>Org agenda r<CR>", { desc = "Org Refile" })
    end,
  },
}
