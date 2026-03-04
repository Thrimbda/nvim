-- bootstrap lazy.nvim, LazyVim and your plugins
vim.env.LC_TIME = "en_US.UTF-8"
pcall(os.setlocale, "en_US.UTF-8", "time")
require("config.lazy")
