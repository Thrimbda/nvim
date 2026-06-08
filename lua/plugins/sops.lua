return {
  {
    "Thrimbda/sops.nvim",
    -- BufReadCmd handlers must exist before opening the first encrypted file.
    lazy = false,
    main = "nvim_sops",
    opts = {},
  },
}
