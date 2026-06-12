-- bootstrap lazy.nvim, LazyVim and your plugins
vim.env.LC_TIME = "en_US.UTF-8"
pcall(os.setlocale, "en_US.UTF-8", "time")

-- File read handlers needed during startup must be registered before LazyVim's VeryLazy autocmd loader.
require("config.file_handlers")

require("config.lazy")
