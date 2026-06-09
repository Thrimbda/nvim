return {
  {
    "nvim-treesitter/nvim-treesitter",
    commit = "4916d6592ede8c07973490d9322f187e07dfefac",
    build = function()
      local TS = require("nvim-treesitter")
      if not TS.get_installed then
        LazyVim.error("Please restart Neovim and run `:TSUpdate` to use the nvim-treesitter main branch.")
        return
      end

      package.loaded["lazyvim.util.treesitter"] = nil
      LazyVim.treesitter.build(function()
        TS.update(nil, { summary = true })
      end)
      require("config.native_artifacts").sign_nvim_artifacts()
    end,
  },
}
