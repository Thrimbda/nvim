-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- vim.keymap.set({ "n", "x" }, "<leader>oa", function()
--   require("opencode").ask("@this: ", { submit = true })
-- end, { desc = "Opencode Ask" })
-- vim.keymap.set({ "n", "x" }, "<leader>os", function()
--   require("opencode").select()
-- end, { desc = "Opencode Select" })
vim.keymap.set({ "n", "t" }, "<leader>ot", function()
  require("opencode").toggle()
end, { desc = "Opencode Toggle" })
