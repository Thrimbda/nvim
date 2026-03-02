-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Register WhichKey groups
require("which-key").add({
  { "<leader>t", group = "Terminal" },
  { "<leader>a", group = "AI" },
})

-- Opencode keymaps
vim.keymap.set({ "n", "x" }, "<leader>aa", function()
  require("opencode").ask("@this: ", { submit = true })
end, { desc = "Opencode Ask" })

vim.keymap.set({ "n", "x" }, "<leader>as", function()
  require("opencode").select()
end, { desc = "Opencode Select" })

vim.keymap.set({ "n", "t" }, "<leader>at", function()
  require("opencode").toggle()
end, { desc = "Opencode Toggle" })

-- Terminal Switching Logic
local function toggle_terminal(pos)
  local snacks = require("snacks")
  local term = snacks.terminal.get(nil, { create = false })
  local width = (pos == "right") and 0.4 or nil
  local height = (pos == "bottom") and 0.4 or nil

  if term then
    if term:valid() and term.opts.position == pos then
      term:hide()
      return
    end

    term.opts.position = pos
    term.opts.width = width
    term.opts.height = height
    term:show()
    return
  end

  snacks.terminal.toggle(nil, {
    win = {
      position = pos,
      width = width,
      height = height,
    },
  })
end

vim.keymap.set("n", "<leader>tj", function()
  toggle_terminal("bottom")
end, { desc = "Terminal (Bottom)" })

vim.keymap.set("n", "<leader>tl", function()
  toggle_terminal("right")
end, { desc = "Terminal (Right)" })

-- Other Snacks shortcuts
vim.keymap.set("n", "<leader>p", function()
  require("snacks").picker.keymaps()
end, { desc = "Snacks Keymaps" })

vim.keymap.set("n", "<leader>gg", function()
  require("snacks").lazygit()
end, { desc = "Snacks LazyGit" })
