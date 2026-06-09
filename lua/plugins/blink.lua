return {
  {
    "saghen/blink.cmp",
    build = function()
      require("config.native_artifacts").sign_patterns({
        vim.fn.stdpath("data") .. "/lazy/blink.cmp/target/release/libblink_cmp_fuzzy.dylib",
      })
    end,
    opts = {
      fuzzy = {
        -- Avoid macOS SIGKILL(Code Signature Invalid) from the native matcher.
        implementation = "lua",
      },
    },
  },
}
