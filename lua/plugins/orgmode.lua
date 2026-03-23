return {
  {
    "nvim-orgmode/orgmode",
    event = "VeryLazy",
    ft = { "org" },
    config = function()
      local org_agenda_files = "~/OneDrive/cone/**/*.org"
      local org_default_notes_file = "~/OneDrive/cone/refile.org"
      local org_diary_file = vim.g.org_diary_file or "~/OneDrive/cone/diary.org"
      local organization_task_id = vim.g.org_organization_task_id
      require("orgmode").setup({
        org_agenda_files = org_agenda_files,
        org_default_notes_file = org_default_notes_file,
        org_startup_indented = true,
        ui = {
          input = {
            use_vim_ui = true,
          },
        },
        org_agenda_use_time_grid = true,
        mappings = {
          global = {
            org_capture = false,
          },
          agenda = {
            org_agenda_clock_in = false,
            org_agenda_clock_out = false,
          },
          org = {
            org_toggle_checkbox = "<C-Space>",
            org_clock_in = false,
            org_clock_out = false,
            org_meta_return = false,
          },
        },
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
        org_todo_keyword_faces = {
          TODO = ":foreground #e86671 :weight bold",
          NEXT = ":foreground #61afef :weight bold",
          WAITING = ":foreground #e5c07b :weight bold",
          HOLD = ":foreground #d19a66 :weight bold",
          DONE = ":foreground #98c379 :weight bold :slant italic",
          CANCELLED = ":foreground #5c6370 :slant italic",
        },
        org_log_into_drawer = "LOGBOOK",
        org_log_done = "note",
        org_capture_templates = {
          t = {
            description = "Todo",
            template = "* TODO %? :REFILE:\n%U\n",
            target = org_default_notes_file,
          },
          r = {
            description = "Respond",
            template = "* NEXT Respond to %^{from} on %^{subject} :REFILE:\nSCHEDULED: %t\n%U\n",
            target = org_default_notes_file,
          },
          n = {
            description = "Note",
            template = "* %? :NOTE:REFILE:\n%U\n",
            target = org_default_notes_file,
          },
          m = {
            description = "Meeting",
            template = "* MEETING with %? :MEETING:REFILE:\n%U\n",
            target = org_default_notes_file,
          },
          p = {
            description = "Phone call",
            template = "* PHONE %? :PHONE:REFILE:\n%U\n",
            target = org_default_notes_file,
          },
          w = {
            description = "Org protocol",
            template = "* TODO Review %a :REFILE:\n%U\n",
            target = org_default_notes_file,
          },
          h = {
            description = "Habit",
            template = "* NEXT %? :REFILE:\nSCHEDULED: %t\n:PROPERTIES:\n:STYLE: habit\n:REPEAT_TO_STATE: NEXT\n:END:\n%U\n",
            target = org_default_notes_file,
          },
          j = {
            description = "Journal",
            template = "* %U %?",
            target = org_diary_file,
            datetree = true,
          },
        },
        org_agenda_custom_commands = {
          b = {
            description = "Block agenda (Legion-style)",
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

      require("org_legion.todo_triggers").setup()

      local agenda_right_group = vim.api.nvim_create_augroup("OrgAgendaRightSide", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = agenda_right_group,
        pattern = "orgagenda",
        callback = function(args)
          vim.keymap.set("n", "I", function()
            require("org_punch").clock_in_current_task()
          end, { buffer = args.buf, desc = "Clock in (Legion NEXT transition)" })
          vim.keymap.set("n", "O", function()
            require("org_punch").clock_out_current_task()
          end, { buffer = args.buf, desc = "Clock out (remove 0:00 entry)" })

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

      local function run_org_action(action)
        local ok, orgmode = pcall(require, "orgmode")
        if not ok or type(orgmode.action) ~= "function" then
          vim.notify("orgmode action is unavailable", vim.log.levels.ERROR)
          return
        end

        local ok_action, result = pcall(orgmode.action, action)
        if not ok_action then
          vim.notify(("orgmode action failed: %s"):format(action), vim.log.levels.ERROR)
          return
        end

        if type(result) == "table" and type(result.wait) == "function" then
          pcall(result.wait, result, 2000)
        end
      end

      local org_meta_return_group = vim.api.nvim_create_augroup("OrgSmartMetaReturn", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = org_meta_return_group,
        pattern = "org",
        callback = function(args)
          vim.keymap.set("n", "<Leader><CR>", function()
            local line = vim.api.nvim_get_current_line()
            if line:match("^%*+%s+") then
              run_org_action("org_mappings.insert_heading_respect_content")
              return
            end
            run_org_action("org_mappings.meta_return")
          end, { buffer = args.buf, desc = "Org Meta Return (respect heading content)" })
        end,
      })

      local punch_cfg = {
        org_agenda_files = org_agenda_files,
        project_todo_keywords = { "TODO", "NEXT", "WAITING", "HOLD" },
      }
      if type(organization_task_id) == "string" and organization_task_id ~= "" then
        punch_cfg.organization_task_id = organization_task_id
      end
      require("org_punch").setup(punch_cfg)

      require("org_legion").setup({
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
      local capture = require("org_capture_legion")
      capture.setup()
      vim.keymap.set("n", "<Leader>opI", punch.punch_in, { desc = "Org Punch In" })
      vim.keymap.set("n", "<Leader>opO", punch.punch_out, { desc = "Org Punch Out" })
      vim.keymap.set("n", "<Leader>opo", punch.clock_out_keep_running, { desc = "Clock out (keep running)" })
      vim.keymap.set("n", "<Leader>oxi", punch.clock_in_current_task, { desc = "Org Clock In (Legion NEXT transition)" })
      vim.keymap.set("n", "<Leader>oxo", punch.clock_out_current_task, { desc = "Org Clock Out (remove 0:00 entry)" })
      vim.keymap.set("n", "<Leader>X", capture.capture_prompt, { desc = "Org Capture (Legion clock handoff)" })

      vim.keymap.set("n", "<F12>", "<Cmd>Org agenda b<CR>", { desc = "Org Block Agenda" })
      vim.keymap.set("n", "<Leader>oab", "<Cmd>Org agenda b<CR>", { desc = "Org Block Agenda" })
      vim.keymap.set("n", "<Leader>oan", "<Cmd>Org agenda n<CR>", { desc = "Org NEXT" })
      vim.keymap.set("n", "<Leader>oat", "<Cmd>Org agenda t<CR>", { desc = "Org Timeline" })
      vim.keymap.set("n", "<Leader>oas", "<Cmd>Org agenda s<CR>", { desc = "Org Stuck Projects" })
      vim.keymap.set("n", "<Leader>oar", "<Cmd>Org agenda r<CR>", { desc = "Org Refile" })
    end,
  },
}
