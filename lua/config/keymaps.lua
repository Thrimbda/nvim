-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Opencode keymaps
-- vim.keymap.set({ "n", "x" }, "<leader>oa", function()
--   require("opencode").ask("@this: ", { submit = true })
-- end, { desc = "Opencode Ask" })
-- vim.keymap.set({ "n", "x" }, "<leader>os", function()
--   require("opencode").select()
-- end, { desc = "Opencode Select" })
vim.keymap.set({ "n", "t" }, "<leader>ot", function()
  require("opencode").toggle()
end, { desc = "Opencode Toggle" })

vim.keymap.set("n", "<leader>p", function()
  require("snacks").picker.keymaps()
end, { desc = "Snacks Keymaps" })

-- Snacks terminal toggles
vim.keymap.set("n", "<leader>tj", function()
  require("snacks").terminal.toggle(nil, { win = { position = "bottom" } })
end, { desc = "Snacks Terminal (Bottom)" })

vim.keymap.set("n", "<leader>tl", function()
  require("snacks").terminal.toggle(nil, { win = { position = "right" } })
end, { desc = "Snacks Terminal (Right)" })

-- Snacks LazyGit
vim.keymap.set("n", "<leader>gg", function()
  require("snacks").lazygit()
end, { desc = "Snacks LazyGit" })
